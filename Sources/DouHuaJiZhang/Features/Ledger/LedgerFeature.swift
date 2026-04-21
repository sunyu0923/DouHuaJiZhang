import ComposableArchitecture
import SwiftUI
import Charts

/// 账本 Feature — 账本管理 + 首页展示
@Reducer
struct LedgerFeature {
    
    @ObservableState
    struct State: Equatable {
        var ledgers: [Ledger] = []
        var currentLedger: Ledger?
        var currentMonth: Int = Calendar.current.component(.month, from: Date())
        var currentYear: Int = Calendar.current.component(.year, from: Date())
        
        // 收支概览
        var totalExpense: Decimal = 0
        var totalIncome: Decimal = 0
        var balance: Decimal { totalIncome - totalExpense }
        
        // 日历数据
        var calendarData: [CalendarDayData] = []
        
        // 统计数据
        var statistics: StatisticsData?
        
        // 交易列表
        var transactions: [Transaction] = []
        var currentPage: Int = 1
        var hasMorePages: Bool = true
        
        var isLoading: Bool = false
        var errorMessage: String?
        
        // Navigation
        @Presents var addTransaction: TransactionFeature.State?
        @Presents var ledgerSwitch: LedgerSwitchState?
        @Presents var transactionDetail: TransactionDetailState?
    }
    
    struct LedgerSwitchState: Equatable, Identifiable {
        var id: UUID { UUID() }
        var ledgers: [Ledger] = []
        var newLedgerName: String = ""
        var newLedgerType: LedgerType = .personal
    }
    
    struct TransactionDetailState: Equatable, Identifiable {
        var id: UUID { transaction.id }
        var transaction: Transaction
        var isEditing: Bool = false
    }
    
    enum Action {
        case onAppear
        case loadData
        case ledgersLoaded([Ledger])
        case calendarLoaded([CalendarDayData])
        case statisticsLoaded(StatisticsData)
        case transactionsLoaded(PaginatedResponse<Transaction>)
        case loadFailed(String)
        
        case previousMonth
        case nextMonth
        case selectDate(String)
        
        // Navigation
        case showAddTransaction
        case showLedgerSwitch
        case showTransactionDetail(Transaction)
        case addTransaction(PresentationAction<TransactionFeature.Action>)
        case ledgerSwitch(PresentationAction<LedgerSwitchAction>)
        case transactionDetail(PresentationAction<TransactionDetailAction>)
        
        case switchLedger(Ledger)
        case createLedger(String, LedgerType)
        case ledgerCreated(Ledger)
        
        case deleteTransaction(UUID)
        case transactionDeleted(UUID)
    }
    
    enum LedgerSwitchAction {
        case dismiss
    }
    
    enum TransactionDetailAction {
        case dismiss
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadData)
                
            case .loadData:
                state.isLoading = true
                let month = state.currentMonth
                let year = state.currentYear
                return .run { send in
                    do {
                        let ledgers = try await apiClient.fetchLedgers()
                        await send(.ledgersLoaded(ledgers))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case .ledgersLoaded(let ledgers):
                state.ledgers = ledgers
                if state.currentLedger == nil {
                    state.currentLedger = ledgers.first
                }
                state.isLoading = false
                guard let ledger = state.currentLedger else { return .none }
                let month = state.currentMonth
                let year = state.currentYear
                let ledgerId = ledger.id
                return .merge(
                    .run { send in
                        let calendar = try await apiClient.fetchCalendar(ledgerId, month, year)
                        await send(.calendarLoaded(calendar))
                    },
                    .run { send in
                        let stats = try await apiClient.fetchStatistics(ledgerId, month, year)
                        await send(.statisticsLoaded(stats))
                    },
                    .run { send in
                        let txns = try await apiClient.fetchTransactions(ledgerId, 1, 20)
                        await send(.transactionsLoaded(txns))
                    }
                )
                
            case .calendarLoaded(let data):
                state.calendarData = data
                return .none
                
            case .statisticsLoaded(let data):
                state.statistics = data
                state.totalExpense = data.totalExpense
                state.totalIncome = data.totalIncome
                return .none
                
            case .transactionsLoaded(let response):
                if state.currentPage == 1 {
                    state.transactions = response.items
                } else {
                    state.transactions.append(contentsOf: response.items)
                }
                state.hasMorePages = response.hasNextPage
                state.isLoading = false
                return .none
                
            case .loadFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case .previousMonth:
                if state.currentMonth == 1 {
                    state.currentMonth = 12
                    state.currentYear -= 1
                } else {
                    state.currentMonth -= 1
                }
                return .send(.loadData)
                
            case .nextMonth:
                if state.currentMonth == 12 {
                    state.currentMonth = 1
                    state.currentYear += 1
                } else {
                    state.currentMonth += 1
                }
                return .send(.loadData)
                
            case .selectDate:
                return .none
                
            case .showAddTransaction:
                guard let ledger = state.currentLedger else { return .none }
                state.addTransaction = TransactionFeature.State(ledgerId: ledger.id)
                return .none
                
            case .showLedgerSwitch:
                state.ledgerSwitch = LedgerSwitchState(ledgers: state.ledgers)
                return .none
                
            case .showTransactionDetail(let transaction):
                state.transactionDetail = TransactionDetailState(transaction: transaction)
                return .none
                
            case .addTransaction(.presented(.transactionSaved)):
                state.addTransaction = nil
                return .send(.loadData)
                
            case .addTransaction:
                return .none
                
            case .ledgerSwitch:
                return .none
                
            case .transactionDetail:
                return .none
                
            case .switchLedger(let ledger):
                state.currentLedger = ledger
                state.ledgerSwitch = nil
                return .send(.loadData)
                
            case .createLedger(let name, let type):
                let request = CreateLedgerRequest(name: name, type: type, currency: "CNY")
                return .run { send in
                    let ledger = try await apiClient.createLedger(request)
                    await send(.ledgerCreated(ledger))
                }
                
            case .ledgerCreated(let ledger):
                state.ledgers.append(ledger)
                state.currentLedger = ledger
                state.ledgerSwitch = nil
                return .send(.loadData)
                
            case .deleteTransaction(let id):
                return .run { send in
                    try await apiClient.deleteTransaction(id)
                    await send(.transactionDeleted(id))
                }
                
            case .transactionDeleted(let id):
                state.transactions.removeAll { $0.id == id }
                return .send(.loadData)
            }
        }
        .ifLet(\.$addTransaction, action: \.addTransaction) {
            TransactionFeature()
        }
    }
}
