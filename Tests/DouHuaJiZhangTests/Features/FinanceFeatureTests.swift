import ComposableArchitecture
import XCTest
@testable import DouHuaJiZhang

@MainActor
final class FinanceFeatureTests: XCTestCase {
    
    let userId = UUID()
    
    // MARK: - Load Data
    
    func testOnAppear_loadsMarketAndInvestments() async {
        let quote = MarketQuote(
            id: "600519", name: "贵州茅台", price: 1800,
            change: 50, changePercent: 0.028, category: .aStock, updatedAt: Date()
        )
        let investment = Investment(
            userId: userId, name: "沪深300", type: .fund,
            amount: 10000, currentValue: 12000
        )
        
        let store = TestStore(initialState: FinanceFeature.State()) {
            FinanceFeature()
        } withDependencies: {
            $0.apiClient.fetchMarketQuotes = { _ in [quote] }
            $0.apiClient.fetchInvestments = { [investment] }
        }
        
        await store.send(.onAppear)
        
        await store.receive(\.loadMarketQuotes) {
            $0.isLoading = true
        }
        await store.receive(\.loadInvestments)
        
        // Order of responses is non-deterministic for parallel effects
        await store.skipReceivedActions()
    }
    
    // MARK: - Market Quotes
    
    func testQuotesLoaded() async {
        let quotes = [
            MarketQuote(id: "600519", name: "茅台", price: 1800, change: 50, changePercent: 0.028, category: .aStock, updatedAt: Date()),
            MarketQuote(id: "AAPL", name: "苹果", price: 170, change: -5, changePercent: -0.029, category: .usStock, updatedAt: Date()),
        ]
        
        let store = TestStore(initialState: FinanceFeature.State()) {
            FinanceFeature()
        }
        
        await store.send(.quotesLoaded(quotes)) {
            $0.marketQuotes = quotes
            $0.isLoading = false
        }
    }
    
    func testSelectMarketCategory() async {
        let store = TestStore(initialState: FinanceFeature.State()) {
            FinanceFeature()
        } withDependencies: {
            $0.apiClient.fetchMarketQuotes = { _ in [] }
        }
        
        await store.send(.selectMarketCategory(.aStock)) {
            $0.selectedMarketCategory = .aStock
        }
        
        await store.receive(\.loadMarketQuotes) {
            $0.isLoading = true
        }
        await store.receive(\.quotesLoaded) {
            $0.marketQuotes = []
            $0.isLoading = false
        }
    }
    
    // MARK: - Investments
    
    func testInvestmentsLoaded_computesTotals() async {
        let inv1 = Investment(userId: userId, name: "A", type: .stock, amount: 10000, currentValue: 12000)
        let inv2 = Investment(userId: userId, name: "B", type: .fund, amount: 20000, currentValue: 18000)
        
        let store = TestStore(initialState: FinanceFeature.State()) {
            FinanceFeature()
        }
        
        await store.send(.investmentsLoaded([inv1, inv2])) {
            $0.investments = [inv1, inv2]
            $0.totalInvestment = 30000 // 10000 + 20000
            $0.totalProfit = 0 // 2000 + (-2000) = 0
        }
    }
    
    func testDeleteInvestment() async {
        let inv1 = Investment(userId: userId, name: "A", type: .stock, amount: 10000, currentValue: 12000)
        let inv2 = Investment(userId: userId, name: "B", type: .fund, amount: 20000, currentValue: 25000)
        
        let store = TestStore(
            initialState: {
                var state = FinanceFeature.State()
                state.investments = [inv1, inv2]
                state.totalInvestment = 30000
                state.totalProfit = 7000
                return state
            }()
        ) {
            FinanceFeature()
        } withDependencies: {
            $0.apiClient.deleteInvestment = { _ in }
        }
        
        await store.send(.deleteInvestment(inv1.id))
        
        await store.receive(\.investmentDeleted) {
            $0.investments = [inv2]
            $0.totalInvestment = 20000
            $0.totalProfit = 5000
        }
    }
    
    // MARK: - Navigation
    
    func testToggleInvestmentList() async {
        let store = TestStore(initialState: FinanceFeature.State()) {
            FinanceFeature()
        }
        
        await store.send(.toggleInvestmentList) {
            $0.showInvestmentList = true
        }
        
        await store.send(.toggleInvestmentList) {
            $0.showInvestmentList = false
        }
    }
    
    func testShowAddInvestment() async {
        let store = TestStore(initialState: FinanceFeature.State()) {
            FinanceFeature()
        }
        
        await store.send(.showAddInvestment) {
            $0.addInvestment = FinanceFeature.AddInvestmentState()
        }
    }
    
    func testShowInvestmentDetail() async {
        let inv = Investment(userId: userId, name: "Test", type: .stock, amount: 10000, currentValue: 12000)
        
        let store = TestStore(initialState: FinanceFeature.State()) {
            FinanceFeature()
        }
        
        await store.send(.showInvestmentDetail(inv)) {
            $0.investmentDetail = FinanceFeature.InvestmentDetailState(investment: inv)
        }
    }
    
    // MARK: - Error
    
    func testLoadFailed() async {
        let store = TestStore(initialState: FinanceFeature.State()) {
            FinanceFeature()
        }
        
        await store.send(.loadFailed("网络超时")) {
            $0.isLoading = false
            $0.errorMessage = "网络超时"
        }
    }
}
