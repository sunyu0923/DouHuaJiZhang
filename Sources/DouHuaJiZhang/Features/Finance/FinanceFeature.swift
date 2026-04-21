import ComposableArchitecture
import Foundation

/// 理财管理 Feature — 行情 + 投资管理
@Reducer
struct FinanceFeature {
    
    @ObservableState
    struct State: Equatable {
        var selectedMarketCategory: MarketCategory? = nil  // nil = 全部
        var marketQuotes: [MarketQuote] = []
        var investments: [Investment] = []
        var totalInvestment: Decimal = 0
        var totalProfit: Decimal = 0
        var isLoading: Bool = false
        var errorMessage: String?
        var showInvestmentList: Bool = false
        var douhuaQuote: String = DouhuaQuoteManager.randomQuote(for: .financeMarket)
        
        @Presents var addInvestment: AddInvestmentState?
        @Presents var investmentDetail: InvestmentDetailState?
    }
    
    struct AddInvestmentState: Equatable, Identifiable {
        let id = UUID()
        var name: String = ""
        var type: InvestmentType = .stock
        var amount: String = ""
        var symbol: String = ""
    }
    
    struct InvestmentDetailState: Equatable, Identifiable {
        var id: UUID { investment.id }
        var investment: Investment
    }
    
    enum Action {
        case onAppear
        case loadMarketQuotes
        case quotesLoaded([MarketQuote])
        case loadInvestments
        case investmentsLoaded([Investment])
        case loadFailed(String)
        case selectMarketCategory(MarketCategory?)
        case toggleInvestmentList
        case showAddInvestment
        case showInvestmentDetail(Investment)
        case deleteInvestment(UUID)
        case investmentDeleted(UUID)
        case addInvestment(PresentationAction<AddInvestmentAction>)
        case investmentDetail(PresentationAction<InvestmentDetailAction>)
    }
    
    enum AddInvestmentAction { case dismiss }
    enum InvestmentDetailAction { case dismiss }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(.send(.loadMarketQuotes), .send(.loadInvestments))
                
            case .loadMarketQuotes:
                state.isLoading = true
                let category = state.selectedMarketCategory
                return .run { send in
                    do {
                        let quotes = try await apiClient.fetchMarketQuotes(category)
                        await send(.quotesLoaded(quotes))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case .quotesLoaded(let quotes):
                state.marketQuotes = quotes
                state.isLoading = false
                return .none
                
            case .loadInvestments:
                return .run { send in
                    do {
                        let investments = try await apiClient.fetchInvestments()
                        await send(.investmentsLoaded(investments))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }
                
            case .investmentsLoaded(let investments):
                state.investments = investments
                state.totalInvestment = investments.reduce(0) { $0 + $1.amount }
                state.totalProfit = investments.reduce(0) { $0 + $1.profit }
                return .none
                
            case .loadFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            case .selectMarketCategory(let category):
                state.selectedMarketCategory = category
                return .send(.loadMarketQuotes)
                
            case .toggleInvestmentList:
                state.showInvestmentList.toggle()
                return .none
                
            case .showAddInvestment:
                state.addInvestment = AddInvestmentState()
                return .none
                
            case .showInvestmentDetail(let investment):
                state.investmentDetail = InvestmentDetailState(investment: investment)
                return .none
                
            case .deleteInvestment(let id):
                return .run { send in
                    try await apiClient.deleteInvestment(id)
                    await send(.investmentDeleted(id))
                }
                
            case .investmentDeleted(let id):
                state.investments.removeAll { $0.id == id }
                state.totalInvestment = state.investments.reduce(0) { $0 + $1.amount }
                state.totalProfit = state.investments.reduce(0) { $0 + $1.profit }
                return .none
                
            case .addInvestment, .investmentDetail:
                return .none
            }
        }
    }
}
