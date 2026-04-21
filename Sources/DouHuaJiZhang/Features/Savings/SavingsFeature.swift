import ComposableArchitecture
import Foundation

/// 攒钱计划 Feature
@Reducer
struct SavingsFeature {
    
    @ObservableState
    struct State: Equatable {
        var plans: [SavingsPlan] = []
        var currentPlan: SavingsPlan?
        var progress: SavingsProgress?
        var monthlyGoalInput: String = ""
        var yearlyGoalInput: String = ""
        var currentYear: Int = Calendar.current.component(.year, from: Date())
        var isLoading: Bool = false
        var errorMessage: String?
        var douhuaQuote: String = DouhuaQuoteManager.randomQuote(for: .savingsSetup)
    }
    
    enum Action {
        case onAppear
        case loadPlans
        case plansLoaded([SavingsPlan])
        case progressLoaded(SavingsProgress)
        case loadFailed(String)
        case setMonthlyGoal(String)
        case setYearlyGoal(String)
        case saveGoal
        case goalSaved(SavingsPlan)
        case updateGoal(SavingsPlan)
        case goalUpdated(SavingsPlan)
        case selectMonth(Int, Int)
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadPlans)
                
            case .loadPlans:
                state.isLoading = true
                let year = state.currentYear
                return .run { send in
                    do {
                        let plans = try await apiClient.fetchSavingsPlans(year)
                        await send(.plansLoaded(plans))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case .plansLoaded(let plans):
                state.plans = plans
                state.isLoading = false
                let currentMonth = Calendar.current.component(.month, from: Date())
                state.currentPlan = plans.first { $0.month == currentMonth }
                if let plan = state.currentPlan {
                    state.monthlyGoalInput = "\(plan.monthlyGoal)"
                    state.yearlyGoalInput = "\(plan.yearlyGoal)"
                    return .run { send in
                        let progress = try await apiClient.fetchSavingsProgress(plan.id)
                        await send(.progressLoaded(progress))
                    }
                }
                return .none
                
            case .progressLoaded(let progress):
                state.progress = progress
                // Update douhua quote based on progress
                if progress.status == .exceeded {
                    state.douhuaQuote = DouhuaQuoteManager.randomQuote(for: .savingsExceeded)
                } else if progress.progressRatio > 0.8 {
                    state.douhuaQuote = DouhuaQuoteManager.randomQuote(for: .savingsWarning)
                } else {
                    state.douhuaQuote = DouhuaQuoteManager.randomQuote(for: .savingsProgress)
                }
                return .none
                
            case .loadFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case .setMonthlyGoal(let value):
                state.monthlyGoalInput = value
                return .none
                
            case .setYearlyGoal(let value):
                state.yearlyGoalInput = value
                return .none
                
            case .saveGoal:
                guard let monthly = Decimal(string: state.monthlyGoalInput),
                      let yearly = Decimal(string: state.yearlyGoalInput),
                      monthly > 0 else { return .none }
                let currentMonth = Calendar.current.component(.month, from: Date())
                let plan = SavingsPlan(
                    userId: UUID(), // Will be set by server
                    monthlyGoal: monthly,
                    yearlyGoal: yearly,
                    month: currentMonth,
                    year: state.currentYear
                )
                return .run { send in
                    let saved = try await apiClient.createSavingsPlan(plan)
                    await send(.goalSaved(saved))
                }
                
            case .goalSaved(let plan):
                state.plans.append(plan)
                state.currentPlan = plan
                state.douhuaQuote = DouhuaQuoteManager.randomQuote(for: .savingsSetup)
                return .none
                
            case .updateGoal(let plan):
                guard plan.canModify else { return .none }
                return .run { send in
                    let updated = try await apiClient.updateSavingsPlan(plan)
                    await send(.goalUpdated(updated))
                }
                
            case .goalUpdated(let plan):
                if let index = state.plans.firstIndex(where: { $0.id == plan.id }) {
                    state.plans[index] = plan
                }
                state.currentPlan = plan
                return .none
                
            case .selectMonth:
                return .none
            }
        }
    }
}
