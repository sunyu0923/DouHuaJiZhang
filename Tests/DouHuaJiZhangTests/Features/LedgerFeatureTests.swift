import ComposableArchitecture
import XCTest
@testable import DouHuaJiZhang

@MainActor
final class LedgerFeatureTests: XCTestCase {
    
    let testLedger = Ledger(id: UUID(), name: "测试账本")
    
    // MARK: - Month Navigation
    
    func testPreviousMonth_normalMonth() async {
        let store = TestStore(
            initialState: {
                var state = LedgerFeature.State()
                state.currentMonth = 6
                state.currentYear = 2026
                return state
            }()
        ) {
            LedgerFeature()
        } withDependencies: {
            $0.apiClient.fetchLedgers = { [] }
        }
        
        await store.send(.previousMonth) {
            $0.currentMonth = 5
        }
        
        // loadData is triggered — handle cascading effects
        await store.receive(\.loadData) {
            $0.isLoading = true
        }
        await store.skipReceivedActions()
    }
    
    func testPreviousMonth_january() async {
        let store = TestStore(
            initialState: {
                var state = LedgerFeature.State()
                state.currentMonth = 1
                state.currentYear = 2026
                return state
            }()
        ) {
            LedgerFeature()
        } withDependencies: {
            $0.apiClient.fetchLedgers = { [] }
        }
        
        await store.send(.previousMonth) {
            $0.currentMonth = 12
            $0.currentYear = 2025
        }
        
        await store.receive(\.loadData) {
            $0.isLoading = true
        }
        await store.skipReceivedActions()
    }
    
    func testNextMonth_normalMonth() async {
        let store = TestStore(
            initialState: {
                var state = LedgerFeature.State()
                state.currentMonth = 6
                state.currentYear = 2026
                return state
            }()
        ) {
            LedgerFeature()
        } withDependencies: {
            $0.apiClient.fetchLedgers = { [] }
        }
        
        await store.send(.nextMonth) {
            $0.currentMonth = 7
        }
        
        await store.receive(\.loadData) {
            $0.isLoading = true
        }
        await store.skipReceivedActions()
    }
    
    func testNextMonth_december() async {
        let store = TestStore(
            initialState: {
                var state = LedgerFeature.State()
                state.currentMonth = 12
                state.currentYear = 2026
                return state
            }()
        ) {
            LedgerFeature()
        } withDependencies: {
            $0.apiClient.fetchLedgers = { [] }
        }
        
        await store.send(.nextMonth) {
            $0.currentMonth = 1
            $0.currentYear = 2027
        }
        
        await store.receive(\.loadData) {
            $0.isLoading = true
        }
        await store.skipReceivedActions()
    }
    
    // MARK: - Load Data
    
    func testLoadData_setsCurrentLedger() async {
        let ledger1 = Ledger(name: "账本1")
        let ledger2 = Ledger(name: "账本2")
        
        let store = TestStore(initialState: LedgerFeature.State()) {
            LedgerFeature()
        } withDependencies: {
            $0.apiClient.fetchLedgers = { [ledger1, ledger2] }
            $0.apiClient.fetchCalendar = { _, _, _ in [] }
            $0.apiClient.fetchStatistics = { _, _, _ in
                StatisticsData(totalExpense: 0, totalIncome: 0, balance: 0, categoryBreakdown: [], dailyTrend: [])
            }
            $0.apiClient.fetchTransactions = { _, _, _ in
                PaginatedResponse(items: [], total: 0, page: 1, pageSize: 20)
            }
        }
        
        await store.send(.loadData) {
            $0.isLoading = true
        }
        
        await store.receive(\.ledgersLoaded) {
            $0.ledgers = [ledger1, ledger2]
            $0.currentLedger = ledger1
            $0.isLoading = false
        }
        
        // Receive parallel data loading results
        await store.skipReceivedActions()
    }
    
    func testLoadData_failure() async {
        let store = TestStore(initialState: LedgerFeature.State()) {
            LedgerFeature()
        } withDependencies: {
            $0.apiClient.fetchLedgers = { throw APIError.networkError("网络不可用") }
        }
        
        await store.send(.loadData) {
            $0.isLoading = true
        }
        
        await store.receive(\.loadFailed) {
            $0.isLoading = false
            $0.errorMessage = "网络错误: 网络不可用"
        }
    }
    
    // MARK: - Navigation
    
    func testShowAddTransaction() async {
        let ledger = Ledger(name: "测试")
        
        let store = TestStore(
            initialState: {
                var state = LedgerFeature.State()
                state.currentLedger = ledger
                return state
            }()
        ) {
            LedgerFeature()
        }
        
        await store.send(.showAddTransaction) {
            $0.addTransaction = TransactionFeature.State(ledgerId: ledger.id)
        }
    }
    
    func testShowLedgerSwitch() async {
        let ledger1 = Ledger(name: "账本1")
        let ledger2 = Ledger(name: "账本2")
        
        let store = TestStore(
            initialState: {
                var state = LedgerFeature.State()
                state.ledgers = [ledger1, ledger2]
                return state
            }()
        ) {
            LedgerFeature()
        }
        
        await store.send(.showLedgerSwitch) {
            $0.ledgerSwitch = LedgerFeature.LedgerSwitchState(ledgers: [ledger1, ledger2])
        }
    }
    
    // MARK: - Transactions
    
    func testTransactionsLoaded_firstPage() async {
        let tx = Transaction(
            ledgerId: UUID(),
            creatorId: UUID(),
            amount: 50,
            type: .expense,
            category: .dining
        )
        
        let store = TestStore(
            initialState: {
                var state = LedgerFeature.State()
                state.currentPage = 1
                return state
            }()
        ) {
            LedgerFeature()
        }
        
        let response = PaginatedResponse(items: [tx], total: 1, page: 1, pageSize: 20)
        
        await store.send(.transactionsLoaded(response)) {
            $0.transactions = [tx]
            $0.hasMorePages = false
            $0.isLoading = false
        }
    }
    
    // MARK: - Ledger CRUD
    
    func testSwitchLedger() async {
        let ledger1 = Ledger(name: "账本1")
        let ledger2 = Ledger(name: "账本2")
        
        let store = TestStore(
            initialState: {
                var state = LedgerFeature.State()
                state.currentLedger = ledger1
                state.ledgerSwitch = LedgerFeature.LedgerSwitchState(ledgers: [ledger1, ledger2])
                return state
            }()
        ) {
            LedgerFeature()
        } withDependencies: {
            $0.apiClient.fetchLedgers = { [ledger1, ledger2] }
        }
        
        await store.send(.switchLedger(ledger2)) {
            $0.currentLedger = ledger2
            $0.ledgerSwitch = nil
        }
        
        await store.receive(\.loadData) {
            $0.isLoading = true
        }
        await store.skipReceivedActions()
    }
    
    // MARK: - Balance computed property
    
    func testBalance() {
        var state = LedgerFeature.State()
        state.totalIncome = 15000
        state.totalExpense = 8000
        
        XCTAssertEqual(state.balance, 7000)
    }
    
    func testStatisticsLoaded() async {
        let stats = StatisticsData(
            totalExpense: 5000,
            totalIncome: 12000,
            balance: 7000,
            categoryBreakdown: [],
            dailyTrend: []
        )
        
        let store = TestStore(initialState: LedgerFeature.State()) {
            LedgerFeature()
        }
        
        await store.send(.statisticsLoaded(stats)) {
            $0.statistics = stats
            $0.totalExpense = 5000
            $0.totalIncome = 12000
        }
    }
}
