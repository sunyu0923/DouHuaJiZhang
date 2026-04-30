import ComposableArchitecture
import XCTest
@testable import DouHuaJiZhang

@MainActor
final class AuthFeatureTests: XCTestCase {
    
    // MARK: - Mode / Navigation
    
    func testSetMode_login() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        }
        
        await store.send(.setMode(.login)) {
            $0.mode = .login
        }
    }
    
    func testSetMode_register() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        }
        
        await store.send(.setMode(.register)) {
            $0.mode = .register
        }
    }
    
    func testSetLoginMethod() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        }
        
        await store.send(.setLoginMethod(.verificationCode)) {
            $0.loginMethod = .verificationCode
        }
    }
    
    func testTogglePasswordVisibility() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        }
        
        await store.send(.togglePasswordVisibility) {
            $0.isPasswordVisible = true
        }
        
        await store.send(.togglePasswordVisibility) {
            $0.isPasswordVisible = false
        }
    }
    
    // MARK: - canLogin computed property
    
    func testCanLogin_emptyFields() {
        let state = AuthFeature.State()
        XCTAssertFalse(state.canLogin)
    }
    
    func testCanLogin_passwordMode() {
        var state = AuthFeature.State()
        state.phone = "13800138000"
        state.password = "password123"
        state.loginMethod = .password
        
        XCTAssertTrue(state.canLogin)
    }
    
    func testCanLogin_verificationCodeMode() {
        var state = AuthFeature.State()
        state.phone = "13800138000"
        state.verificationCode = "123456"
        state.loginMethod = .verificationCode
        
        XCTAssertTrue(state.canLogin)
    }
    
    func testCanLogin_locked() {
        var state = AuthFeature.State()
        state.phone = "13800138000"
        state.password = "password123"
        state.isLocked = true
        
        XCTAssertFalse(state.canLogin)
    }
    
    // MARK: - canRegister computed property
    
    func testCanRegister_allFieldsFilled() {
        var state = AuthFeature.State()
        state.registerPhone = "13800138000"
        state.registerPassword = "password123"
        state.registerConfirmPassword = "password123"
        state.registerVerificationCode = "123456"
        state.hasAgreedToTerms = true
        
        XCTAssertTrue(state.canRegister)
    }
    
    func testCanRegister_passwordMismatch() {
        var state = AuthFeature.State()
        state.registerPhone = "13800138000"
        state.registerPassword = "password123"
        state.registerConfirmPassword = "different"
        state.registerVerificationCode = "123456"
        state.hasAgreedToTerms = true
        
        XCTAssertFalse(state.canRegister)
    }
    
    func testCanRegister_termsNotAgreed() {
        var state = AuthFeature.State()
        state.registerPhone = "13800138000"
        state.registerPassword = "password123"
        state.registerConfirmPassword = "password123"
        state.registerVerificationCode = "123456"
        state.hasAgreedToTerms = false
        
        XCTAssertFalse(state.canRegister)
    }
    
    // MARK: - Login Flow
    
    func testLogin_success() async {
        let testUser = User(phone: "13800138000", nickname: "豆花")
        let testResponse = AuthResponse(token: "access-token", refreshToken: "refresh-token", user: testUser)
        
        let store = TestStore(
            initialState: {
                var state = AuthFeature.State()
                state.phone = "13800138000"
                state.password = "password123"
                return state
            }()
        ) {
            AuthFeature()
        } withDependencies: {
            $0.apiClient.login = { _ in testResponse }
            $0.keychainClient.saveToken = { _ in }
            $0.keychainClient.saveRefreshToken = { _ in }
            $0.keychainClient.saveUserId = { _ in }
        }
        
        await store.send(.login) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        
        await store.receive(\.loginResponse.success) {
            $0.isLoading = false
            $0.failedAttempts = 0
        }
        
        await store.receive(\.loginSuccess)
    }
    
    func testLogin_failure_incrementsAttempts() async {
        let store = TestStore(
            initialState: {
                var state = AuthFeature.State()
                state.phone = "13800138000"
                state.password = "wrong"
                return state
            }()
        ) {
            AuthFeature()
        } withDependencies: {
            $0.apiClient.login = { _ in throw APIError.unauthorized }
        }
        
        await store.send(.login) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        
        await store.receive(\.loginResponse.failure) {
            $0.isLoading = false
            $0.failedAttempts = 1
            $0.errorMessage = APIError.unauthorized.localizedDescription
        }
    }

    func testLogin_testCredentialsDoNotBypassAPI() async {
        let store = TestStore(
            initialState: {
                var state = AuthFeature.State()
                state.phone = "15524809230"
                state.password = "1234"
                return state
            }()
        ) {
            AuthFeature()
        } withDependencies: {
            $0.apiClient.login = { request in
                XCTAssertEqual(request.phone, "15524809230")
                XCTAssertEqual(request.password, "1234")
                throw APIError.unauthorized
            }
        }

        await store.send(.login) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.loginResponse.failure) {
            $0.isLoading = false
            $0.failedAttempts = 1
            $0.errorMessage = APIError.unauthorized.localizedDescription
        }
    }
    
    func testLogin_threeFailures_locksAccount() async {
        let clock = TestClock()
        
        let store = TestStore(
            initialState: {
                var state = AuthFeature.State()
                state.phone = "13800138000"
                state.password = "wrong"
                state.failedAttempts = 2 // already failed twice
                return state
            }()
        ) {
            AuthFeature()
        } withDependencies: {
            $0.apiClient.login = { _ in throw APIError.unauthorized }
            $0.continuousClock = clock
        }
        
        await store.send(.login) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        
        await store.receive(\.loginResponse.failure) {
            $0.isLoading = false
            $0.failedAttempts = 3
            $0.isLocked = true
            $0.errorMessage = "登录失败次数过多，请10分钟后再试"
        }
        
        // Advance clock 10 minutes to trigger unlock
        await clock.advance(by: .seconds(600))
        
        await store.receive(\.unlockAccount) {
            $0.isLocked = false
            $0.failedAttempts = 0
            $0.errorMessage = nil
        }
    }
    
    // MARK: - Register Flow
    
    func testRegister_success() async {
        let testUser = User(phone: "13900139000", nickname: "新用户")
        let testResponse = AuthResponse(token: "new-token", refreshToken: "new-refresh", user: testUser)
        
        let store = TestStore(
            initialState: {
                var state = AuthFeature.State()
                state.registerPhone = "13900139000"
                state.registerPassword = "password123"
                state.registerConfirmPassword = "password123"
                state.registerVerificationCode = "123456"
                state.hasAgreedToTerms = true
                return state
            }()
        ) {
            AuthFeature()
        } withDependencies: {
            $0.apiClient.register = { _ in testResponse }
            $0.keychainClient.saveToken = { _ in }
            $0.keychainClient.saveRefreshToken = { _ in }
            $0.keychainClient.saveUserId = { _ in }
        }
        
        await store.send(.register) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        
        await store.receive(\.registerResponse.success) {
            $0.isLoading = false
        }
        
        await store.receive(\.loginSuccess)
    }
    
    func testRegister_failure() async {
        let store = TestStore(
            initialState: {
                var state = AuthFeature.State()
                state.registerPhone = "13900139000"
                state.registerPassword = "password123"
                state.registerConfirmPassword = "password123"
                state.registerVerificationCode = "123456"
                state.hasAgreedToTerms = true
                return state
            }()
        ) {
            AuthFeature()
        } withDependencies: {
            $0.apiClient.register = { _ in throw APIError.conflict }
        }
        
        await store.send(.register) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        
        await store.receive(\.registerResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = APIError.conflict.localizedDescription
        }
    }
    
    // MARK: - OTP Countdown
    
    func testSendVerificationCode_startsCountdown() async {
        let clock = TestClock()
        
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.apiClient.sendVerificationCode = { _ in }
            $0.continuousClock = clock
        }
        
        await store.send(.sendVerificationCode("13800138000")) {
            $0.codeSentCountdown = 60
        }
        
        await clock.advance(by: .seconds(1))
        await store.receive(\.codeSentCountdownTick) {
            $0.codeSentCountdown = 59
        }
        
        await clock.advance(by: .seconds(1))
        await store.receive(\.codeSentCountdownTick) {
            $0.codeSentCountdown = 58
        }
        
        // Skip remaining ticks
        await store.skipReceivedActions()
        await clock.advance(by: .seconds(58))
    }
    
    // MARK: - Error Dismissal
    
    func testDismissError() async {
        let store = TestStore(
            initialState: {
                var state = AuthFeature.State()
                state.errorMessage = "测试错误"
                return state
            }()
        ) {
            AuthFeature()
        }
        
        await store.send(.dismissError) {
            $0.errorMessage = nil
        }
    }
    
    func testSetMode_clearsError() async {
        let store = TestStore(
            initialState: {
                var state = AuthFeature.State()
                state.errorMessage = "旧错误"
                return state
            }()
        ) {
            AuthFeature()
        }
        
        await store.send(.setMode(.login)) {
            $0.mode = .login
            $0.errorMessage = nil
        }
    }
}
