import ComposableArchitecture
import Foundation

/// App 根 Reducer — 管理 Tab 路由和认证状态
@Reducer
struct AppFeature {
    
    /// 底部菜单栏 Tab
    enum Tab: String, Equatable, Sendable, CaseIterable {
        case ledger = "ledger"          // 账本首页
        case savings = "savings"        // 攒钱计划
        case finance = "finance"        // 理财管理
        case health = "health"          // 豆花健康记
        
        var title: String {
            switch self {
            case .ledger: return "账本"
            case .savings: return "攒钱"
            case .finance: return "理财"
            case .health: return "健康"
            }
        }
        
        var iconName: String {
            switch self {
            case .ledger: return "book.fill"
            case .savings: return "banknote.fill"
            case .finance: return "chart.line.uptrend.xyaxis"
            case .health: return "heart.fill"
            }
        }
    }
    
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .ledger
        var isAuthenticated: Bool = false
        var currentUser: User?
        
        // Child feature states
        var ledger = LedgerFeature.State()
        var savings = SavingsFeature.State()
        var finance = FinanceFeature.State()
        var health = HealthRecordFeature.State()
        
        // Presented destinations
        @Presents var auth: AuthFeature.State?
        @Presents var settings: SettingsFeature.State?
    }
    
    enum Action {
        case onAppear
        case selectTab(Tab)
        case checkAuthStatus
        case authStatusChecked(Bool, User?)
        case showSettings
        case logout
        case logoutCompleted
        
        // Child feature actions
        case ledger(LedgerFeature.Action)
        case savings(SavingsFeature.Action)
        case finance(FinanceFeature.Action)
        case health(HealthRecordFeature.Action)
        
        // Presented destination actions
        case auth(PresentationAction<AuthFeature.Action>)
        case settings(PresentationAction<SettingsFeature.Action>)
    }
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.keychainClient) var keychainClient
    
    var body: some ReducerOf<Self> {
        Scope(state: \.ledger, action: \.ledger) {
            LedgerFeature()
        }
        Scope(state: \.savings, action: \.savings) {
            SavingsFeature()
        }
        Scope(state: \.finance, action: \.finance) {
            FinanceFeature()
        }
        Scope(state: \.health, action: \.health) {
            HealthRecordFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.checkAuthStatus)
                
            case .selectTab(let tab):
                state.selectedTab = tab
                return .none
                
            case .checkAuthStatus:
                return .run { send in
                    do {
                        if let _ = try await keychainClient.getToken() {
                            let user = try await apiClient.fetchProfile()
                            await send(.authStatusChecked(true, user))
                        } else {
                            await send(.authStatusChecked(false, nil))
                        }
                    } catch {
                        await send(.authStatusChecked(false, nil))
                    }
                }
                
            case .authStatusChecked(let isAuth, let user):
                state.isAuthenticated = isAuth
                state.currentUser = user
                if !isAuth {
                    state.auth = AuthFeature.State()
                }
                return .none
                
            case .showSettings:
                state.settings = SettingsFeature.State(user: state.currentUser)
                return .none
                
            case .logout:
                return .run { send in
                    try? await apiClient.logout()
                    try? await keychainClient.deleteAll()
                    await send(.logoutCompleted)
                }
                
            case .logoutCompleted:
                state.isAuthenticated = false
                state.currentUser = nil
                state.auth = AuthFeature.State()
                return .none
                
            case .auth(.presented(.loginSuccess(let user))):
                state.isAuthenticated = true
                state.currentUser = user
                state.auth = nil
                return .none
                
            case .auth:
                return .none
                
            case .settings(.presented(.logout)):
                return .send(.logout)
                
            case .settings:
                return .none
                
            case .ledger, .savings, .finance, .health:
                return .none
            }
        }
        .ifLet(\.$auth, action: \.auth) {
            AuthFeature()
        }
        .ifLet(\.$settings, action: \.settings) {
            SettingsFeature()
        }
    }
}
