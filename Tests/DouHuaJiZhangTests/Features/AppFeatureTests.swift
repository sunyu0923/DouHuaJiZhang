import ComposableArchitecture
import XCTest
@testable import DouHuaJiZhang

@MainActor
final class AppFeatureTests: XCTestCase {
    
    // MARK: - Tab Selection
    
    func testSelectTab() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        
        await store.send(.selectTab(.savings)) {
            $0.selectedTab = .savings
        }
        
        await store.send(.selectTab(.finance)) {
            $0.selectedTab = .finance
        }
        
        await store.send(.selectTab(.health)) {
            $0.selectedTab = .health
        }
        
        await store.send(.selectTab(.ledger)) {
            $0.selectedTab = .ledger
        }
    }
    
    // MARK: - Tab enum
    
    func testTab_allCases() {
        XCTAssertEqual(AppFeature.Tab.allCases.count, 4)
    }
    
    func testTab_titles() {
        XCTAssertEqual(AppFeature.Tab.ledger.title, "账本")
        XCTAssertEqual(AppFeature.Tab.savings.title, "攒钱")
        XCTAssertEqual(AppFeature.Tab.finance.title, "理财")
        XCTAssertEqual(AppFeature.Tab.health.title, "健康")
    }
    
    func testTab_iconNames() {
        XCTAssertEqual(AppFeature.Tab.ledger.iconName, "book.fill")
        XCTAssertEqual(AppFeature.Tab.savings.iconName, "banknote.fill")
        XCTAssertEqual(AppFeature.Tab.finance.iconName, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(AppFeature.Tab.health.iconName, "heart.fill")
    }
    
    // MARK: - Auth Status
    
    func testCheckAuthStatus_notAuthenticated() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.keychainClient.getToken = { nil }
        }
        
        await store.send(.checkAuthStatus)
        
        await store.receive(\.authStatusChecked) {
            $0.isAuthenticated = false
            $0.currentUser = nil
            $0.auth = AuthFeature.State()
        }
    }
    
    func testCheckAuthStatus_authenticated() async {
        let user = User(phone: "13800138000", nickname: "豆花")
        
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.keychainClient.getToken = { "valid-token" }
            $0.apiClient.fetchProfile = { user }
        }
        
        await store.send(.checkAuthStatus)
        
        await store.receive(\.authStatusChecked) {
            $0.isAuthenticated = true
            $0.currentUser = user
        }
    }
    
    // MARK: - Login Success (from auth child)
    
    func testAuthLoginSuccess_dismissesAuth() async {
        let user = User(phone: "13800138000", nickname: "豆花")
        
        let store = TestStore(
            initialState: {
                var state = AppFeature.State()
                state.auth = AuthFeature.State()
                return state
            }()
        ) {
            AppFeature()
        }
        
        await store.send(.auth(.presented(.loginSuccess(user)))) {
            $0.isAuthenticated = true
            $0.currentUser = user
            $0.auth = nil
        }
    }
    
    // MARK: - Settings
    
    func testShowSettings() async {
        let user = User(phone: "13800138000", nickname: "豆花")
        
        let store = TestStore(
            initialState: {
                var state = AppFeature.State()
                state.currentUser = user
                return state
            }()
        ) {
            AppFeature()
        }
        
        await store.send(.showSettings) {
            $0.settings = SettingsFeature.State(user: user)
        }
    }
    
    // MARK: - Logout
    
    func testLogout() async {
        let store = TestStore(
            initialState: {
                var state = AppFeature.State()
                state.isAuthenticated = true
                state.currentUser = User(phone: "13800138000", nickname: "豆花")
                return state
            }()
        ) {
            AppFeature()
        } withDependencies: {
            $0.apiClient.logout = { }
            $0.keychainClient.deleteAll = { }
        }
        
        await store.send(.logout)
        
        await store.receive(\.logoutCompleted) {
            $0.isAuthenticated = false
            $0.currentUser = nil
            $0.auth = AuthFeature.State()
        }
    }
    
    func testSettingsLogout_triggersAppLogout() async {
        let store = TestStore(
            initialState: {
                var state = AppFeature.State()
                state.isAuthenticated = true
                state.settings = SettingsFeature.State()
                return state
            }()
        ) {
            AppFeature()
        } withDependencies: {
            $0.apiClient.logout = { }
            $0.keychainClient.deleteAll = { }
        }
        
        await store.send(.settings(.presented(.logout)))
        
        await store.receive(\.logout)
        
        await store.receive(\.logoutCompleted) {
            $0.isAuthenticated = false
            $0.currentUser = nil
            $0.auth = AuthFeature.State()
        }
    }
    
    // MARK: - Initial State
    
    func testInitialState() {
        let state = AppFeature.State()
        
        XCTAssertEqual(state.selectedTab, .ledger)
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertNil(state.currentUser)
        XCTAssertNil(state.auth)
        XCTAssertNil(state.settings)
    }
}
