import ComposableArchitecture
import Foundation

/// 认证 Feature — 登录/注册状态机
@Reducer
struct AuthFeature {
    
    enum AuthMode: Equatable, Sendable {
        case welcome
        case login
        case register
    }
    
    enum LoginMethod: Equatable, Sendable {
        case password
        case verificationCode
    }
    
    @ObservableState
    struct State: Equatable {
        var mode: AuthMode = .welcome
        var loginMethod: LoginMethod = .password
        
        // Login fields
        var phone: String = ""
        var password: String = ""
        var verificationCode: String = ""
        var isPasswordVisible: Bool = false
        
        // Register fields
        var registerPhone: String = ""
        var registerPassword: String = ""
        var registerConfirmPassword: String = ""
        var registerVerificationCode: String = ""
        var isRegisterPasswordVisible: Bool = false
        var hasAgreedToTerms: Bool = false
        
        // State
        var isLoading: Bool = false
        var errorMessage: String?
        var failedAttempts: Int = 0
        var isLocked: Bool = false
        var codeSentCountdown: Int = 0
        
        var canLogin: Bool {
            !phone.isEmpty && !isLoading && !isLocked &&
            (loginMethod == .password ? !password.isEmpty : !verificationCode.isEmpty)
        }
        
        var canRegister: Bool {
            !registerPhone.isEmpty && !registerPassword.isEmpty &&
            !registerConfirmPassword.isEmpty && !registerVerificationCode.isEmpty &&
            hasAgreedToTerms && !isLoading &&
            registerPassword == registerConfirmPassword
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case setMode(AuthMode)
        case setLoginMethod(LoginMethod)
        case togglePasswordVisibility
        case toggleRegisterPasswordVisibility
        case login
        case register
        case loginWithWechat
        case sendVerificationCode(String)
        case codeSentCountdownTick
        case loginResponse(Result<AuthResponse, APIError>)
        case registerResponse(Result<AuthResponse, APIError>)
        case loginSuccess(User)
        case unlockAccount
        case dismissError
    }
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.keychainClient) var keychainClient
    @Dependency(\.continuousClock) var clock
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .setMode(let mode):
                state.mode = mode
                state.errorMessage = nil
                return .none
                
            case .setLoginMethod(let method):
                state.loginMethod = method
                return .none
                
            case .togglePasswordVisibility:
                state.isPasswordVisible.toggle()
                return .none
                
            case .toggleRegisterPasswordVisibility:
                state.isRegisterPasswordVisible.toggle()
                return .none
                
            case .login:
                guard state.canLogin else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let request = LoginRequest(
                    phone: state.phone,
                    password: state.loginMethod == .password ? state.password : nil,
                    verificationCode: state.loginMethod == .verificationCode ? state.verificationCode : nil
                )
                return .run { send in
                    do {
                        let response = try await apiClient.login(request)
                        await send(.loginResponse(.success(response)))
                    } catch let error as APIError {
                        await send(.loginResponse(.failure(error)))
                    } catch {
                        await send(.loginResponse(.failure(.networkError(error.localizedDescription))))
                    }
                }
                
            case .register:
                guard state.canRegister else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                let request = RegisterRequest(
                    phone: state.registerPhone,
                    password: state.registerPassword,
                    verificationCode: state.registerVerificationCode
                )
                return .run { send in
                    do {
                        let response = try await apiClient.register(request)
                        await send(.registerResponse(.success(response)))
                    } catch let error as APIError {
                        await send(.registerResponse(.failure(error)))
                    } catch {
                        await send(.registerResponse(.failure(.networkError(error.localizedDescription))))
                    }
                }
                
            case .loginWithWechat:
                state.isLoading = true
                // WeChat SDK integration would go here
                // For now, this is a placeholder
                state.isLoading = false
                return .none
                
            case .sendVerificationCode(let phone):
                guard !phone.isEmpty, state.codeSentCountdown == 0 else { return .none }
                state.codeSentCountdown = 60
                return .run { send in
                    try? await apiClient.sendVerificationCode(phone)
                    for _ in 0..<60 {
                        try await clock.sleep(for: .seconds(1))
                        await send(.codeSentCountdownTick)
                    }
                }
                
            case .codeSentCountdownTick:
                if state.codeSentCountdown > 0 {
                    state.codeSentCountdown -= 1
                }
                return .none
                
            case .loginResponse(.success(let response)):
                state.isLoading = false
                state.failedAttempts = 0
                return .run { send in
                    try await keychainClient.saveToken(response.token)
                    try await keychainClient.saveRefreshToken(response.refreshToken)
                    try await keychainClient.saveUserId(response.user.id.uuidString)
                    await send(.loginSuccess(response.user))
                }
                
            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.failedAttempts += 1
                if state.failedAttempts >= 3 {
                    state.isLocked = true
                    state.errorMessage = "登录失败次数过多，请10分钟后再试"
                    return .run { [clock] send in
                        try await clock.sleep(for: .seconds(600))
                        await send(.unlockAccount)
                    }
                } else {
                    state.errorMessage = error.localizedDescription
                }
                return .none
                
            case .registerResponse(.success(let response)):
                state.isLoading = false
                return .run { send in
                    try await keychainClient.saveToken(response.token)
                    try await keychainClient.saveRefreshToken(response.refreshToken)
                    try await keychainClient.saveUserId(response.user.id.uuidString)
                    await send(.loginSuccess(response.user))
                }
                
            case .registerResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .loginSuccess:
                // Handled by parent (AppFeature)
                return .none
                
            case .unlockAccount:
                state.isLocked = false
                state.failedAttempts = 0
                state.errorMessage = nil
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}
