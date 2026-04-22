import ComposableArchitecture
import XCTest
@testable import DouHuaJiZhang

@MainActor
final class SavingsFeatureTests: XCTestCase {
    
    let userId = UUID()
    
    // MARK: - Goal Input
    
    func testSetMonthlyGoal() async {
        let store = TestStore(initialState: SavingsFeature.State()) {
            SavingsFeature()
        }
        
        await store.send(.setMonthlyGoal("5000")) {
            $0.monthlyGoalInput = "5000"
        }
    }
    
    func testSetYearlyGoal() async {
        let store = TestStore(initialState: SavingsFeature.State()) {
            SavingsFeature()
        }
        
        await store.send(.setYearlyGoal("60000")) {
            $0.yearlyGoalInput = "60000"
        }
    }
    
    // MARK: - Load Plans
    
    func testLoadPlans_withCurrentMonthPlan() async {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let plan = SavingsPlan(
            userId: userId,
            monthlyGoal: 5000,
            yearlyGoal: 60000,
            month: currentMonth,
            year: 2026
        )
        let progress = SavingsProgress(
            planId: plan.id,
            month: currentMonth,
            year: 2026,
            targetAmount: 5000,
            totalIncome: 15000,
            totalExpense: 8000
        )
        
        let store = TestStore(initialState: SavingsFeature.State()) {
            SavingsFeature()
        } withDependencies: {
            $0.apiClient.fetchSavingsPlans = { _ in [plan] }
            $0.apiClient.fetchSavingsProgress = { _ in progress }
        }
        
        await store.send(.loadPlans) {
            $0.isLoading = true
        }
        
        await store.receive(\.plansLoaded) {
            $0.plans = [plan]
            $0.isLoading = false
            $0.currentPlan = plan
            $0.monthlyGoalInput = "\(plan.monthlyGoal)"
            $0.yearlyGoalInput = "\(plan.yearlyGoal)"
        }
        
        await store.receive(\.progressLoaded) {
            $0.progress = progress
            // douhuaQuote updated based on progress
        }
    }
    
    func testLoadPlans_empty() async {
        let store = TestStore(initialState: SavingsFeature.State()) {
            SavingsFeature()
        } withDependencies: {
            $0.apiClient.fetchSavingsPlans = { _ in [] }
        }
        
        await store.send(.loadPlans) {
            $0.isLoading = true
        }
        
        await store.receive(\.plansLoaded) {
            $0.plans = []
            $0.isLoading = false
        }
    }
    
    func testLoadPlans_failure() async {
        let store = TestStore(initialState: SavingsFeature.State()) {
            SavingsFeature()
        } withDependencies: {
            $0.apiClient.fetchSavingsPlans = { _ in throw APIError.networkError("超时") }
        }
        
        await store.send(.loadPlans) {
            $0.isLoading = true
        }
        
        await store.receive(\.loadFailed) {
            $0.isLoading = false
            $0.errorMessage = "网络错误: 超时"
        }
    }
    
    // MARK: - Save Goal
    
    func testSaveGoal_validInput() async {
        let savedPlan = SavingsPlan(
            userId: userId,
            monthlyGoal: 5000,
            yearlyGoal: 60000,
            month: Calendar.current.component(.month, from: Date()),
            year: 2026
        )
        
        let store = TestStore(
            initialState: {
                var state = SavingsFeature.State()
                state.monthlyGoalInput = "5000"
                state.yearlyGoalInput = "60000"
                return state
            }()
        ) {
            SavingsFeature()
        } withDependencies: {
            $0.apiClient.createSavingsPlan = { _ in savedPlan }
        }
        
        await store.send(.saveGoal)
        
        await store.receive(\.goalSaved) {
            $0.plans = [savedPlan]
            $0.currentPlan = savedPlan
        }
    }
    
    func testSaveGoal_invalidInput() async {
        let store = TestStore(
            initialState: {
                var state = SavingsFeature.State()
                state.monthlyGoalInput = "abc"
                state.yearlyGoalInput = "60000"
                return state
            }()
        ) {
            SavingsFeature()
        }
        
        // Should not fire any effects for invalid input
        await store.send(.saveGoal)
    }
    
    func testSaveGoal_zeroAmount() async {
        let store = TestStore(
            initialState: {
                var state = SavingsFeature.State()
                state.monthlyGoalInput = "0"
                state.yearlyGoalInput = "60000"
                return state
            }()
        ) {
            SavingsFeature()
        }
        
        // 0 should be rejected by guard (monthly > 0)
        await store.send(.saveGoal)
    }
    
    // MARK: - Update Goal
    
    func testUpdateGoal_canModify() async {
        let plan = SavingsPlan(
            userId: userId,
            monthlyGoal: 5000,
            yearlyGoal: 60000,
            month: 4,
            year: 2026,
            modifiedCount: 0
        )
        let updatedPlan = SavingsPlan(
            id: plan.id,
            userId: userId,
            monthlyGoal: 8000,
            yearlyGoal: 96000,
            month: 4,
            year: 2026,
            modifiedCount: 1
        )
        
        let store = TestStore(
            initialState: {
                var state = SavingsFeature.State()
                state.plans = [plan]
                state.currentPlan = plan
                return state
            }()
        ) {
            SavingsFeature()
        } withDependencies: {
            $0.apiClient.updateSavingsPlan = { _ in updatedPlan }
        }
        
        await store.send(.updateGoal(plan))
        
        await store.receive(\.goalUpdated) {
            $0.plans = [updatedPlan]
            $0.currentPlan = updatedPlan
        }
    }
    
    func testUpdateGoal_cannotModify() async {
        let plan = SavingsPlan(
            userId: userId,
            monthlyGoal: 5000,
            yearlyGoal: 60000,
            month: 4,
            year: 2026,
            modifiedCount: 1 // already modified once
        )
        
        let store = TestStore(initialState: SavingsFeature.State()) {
            SavingsFeature()
        }
        
        // Should not fire effects since canModify = false
        await store.send(.updateGoal(plan))
    }
}
