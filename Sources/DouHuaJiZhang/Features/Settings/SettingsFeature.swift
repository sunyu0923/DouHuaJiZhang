import ComposableArchitecture
import Foundation

/// 个人设置 Feature
@Reducer
struct SettingsFeature {
    
    @ObservableState
    struct State: Equatable {
        var user: User?
        
        // 记账数据
        var consecutiveDays: Int = 0
        var totalDays: Int = 0
        var totalTransactions: Int = 0
        var totalBalance: Decimal = 0
        
        // 设置
        var isReminderEnabled: Bool = true
        var reminderTime: Date = {
            var components = DateComponents()
            components.hour = 20
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }()
        var isAmountHidden: Bool = false
        var isAppLockEnabled: Bool = false
        
        var isLoading: Bool = false
        
        // Navigation
        @Presents var badges: BadgesState?
    }
    
    struct BadgesState: Equatable, Identifiable {
        let id = UUID()
        var badges: [Badge] = []
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case loadProfile
        case profileLoaded(User)
        case updateAvatar
        case showBadges
        case badges(PresentationAction<BadgesAction>)
        case badgesLoaded([Badge])
        case inviteFriend
        case clearCache
        case cacheCleared
        case logout
        case dismiss
    }
    
    enum BadgesAction { case dismiss }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                return .send(.loadProfile)
                
            case .loadProfile:
                state.isLoading = true
                return .run { send in
                    let user = try await apiClient.fetchProfile()
                    await send(.profileLoaded(user))
                }
                
            case .profileLoaded(let user):
                state.user = user
                state.isLoading = false
                return .none
                
            case .updateAvatar:
                // TODO: Photo picker integration
                return .none
                
            case .showBadges:
                state.badges = BadgesState()
                return .run { send in
                    let badges = try await apiClient.fetchBadges()
                    await send(.badgesLoaded(badges))
                }
                
            case .badgesLoaded(let badges):
                state.badges?.badges = badges
                return .none
                
            case .badges:
                return .none
                
            case .inviteFriend:
                // TODO: Share sheet
                return .none
                
            case .clearCache:
                // TODO: Clear cache
                return .send(.cacheCleared)
                
            case .cacheCleared:
                return .none
                
            case .logout:
                // Handled by parent (AppFeature)
                return .none
                
            case .dismiss:
                return .none
            }
        }
        .ifLet(\.$badges, action: \.badges) {
            EmptyReducer()
        }
    }
}
