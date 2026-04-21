import ComposableArchitecture
import Foundation

/// 记账（交易）Feature — 计算器输入 + 分类选择
@Reducer
struct TransactionFeature {
    
    @ObservableState
    struct State: Equatable {
        let ledgerId: UUID
        var transactionType: TransactionType = .expense
        var selectedCategory: TransactionCategory?
        var calculatorDisplay: String = "0"
        var calculatorExpression: String = ""
        var note: String = ""
        var selectedDate: Date = Date()
        var isLoading: Bool = false
        var errorMessage: String?
        var douhuaQuote: String = DouhuaQuoteManager.randomQuote(for: .recording)
        
        var amount: Decimal? {
            Decimal(string: calculatorDisplay)
        }
        
        var canSubmit: Bool {
            selectedCategory != nil && (amount ?? 0) > 0 && !isLoading
        }
        
        var currentCategories: [TransactionCategory] {
            transactionType == .expense ? TransactionCategory.expenseCategories : TransactionCategory.incomeCategories
        }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case setTransactionType(TransactionType)
        case selectCategory(TransactionCategory)
        case calculatorInput(CalculatorKey)
        case setDate(Date)
        case submit
        case submitResponse(Result<Transaction, APIError>)
        case transactionSaved
        case dismiss
    }
    
    /// 计算器按键
    enum CalculatorKey: String, Equatable, Sendable {
        case zero = "0"
        case one = "1"
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"
        case six = "6"
        case seven = "7"
        case eight = "8"
        case nine = "9"
        case dot = "."
        case plus = "+"
        case minus = "-"
        case multiply = "×"
        case divide = "÷"
        case equals = "="
        case clear = "C"
        case backspace = "⌫"
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .setTransactionType(let type):
                state.transactionType = type
                state.selectedCategory = nil
                return .none
                
            case .selectCategory(let category):
                state.selectedCategory = category
                state.douhuaQuote = category.douhuaQuote
                return .none
                
            case .calculatorInput(let key):
                handleCalculatorInput(&state, key: key)
                return .none
                
            case .setDate(let date):
                state.selectedDate = date
                return .none
                
            case .submit:
                guard state.canSubmit,
                      let category = state.selectedCategory,
                      let amount = state.amount else { return .none }
                
                state.isLoading = true
                let request = CreateTransactionRequest(
                    operationId: UUID(),
                    amount: amount,
                    type: state.transactionType,
                    category: category,
                    note: state.note,
                    date: state.selectedDate
                )
                let ledgerId = state.ledgerId
                
                return .run { send in
                    do {
                        let transaction = try await apiClient.createTransaction(ledgerId, request)
                        await send(.submitResponse(.success(transaction)))
                    } catch let error as APIError {
                        await send(.submitResponse(.failure(error)))
                    } catch {
                        await send(.submitResponse(.failure(.networkError(error.localizedDescription))))
                    }
                }
                
            case .submitResponse(.success):
                state.isLoading = false
                state.douhuaQuote = DouhuaQuoteManager.randomQuote(for: .recordSuccess)
                return .send(.transactionSaved)
                
            case .submitResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .transactionSaved:
                return .none
                
            case .dismiss:
                return .none
            }
        }
    }
    
    // MARK: - Calculator Logic
    
    private func handleCalculatorInput(_ state: inout State, key: CalculatorKey) {
        switch key {
        case .clear:
            state.calculatorDisplay = "0"
            state.calculatorExpression = ""
            
        case .backspace:
            if state.calculatorDisplay.count > 1 {
                state.calculatorDisplay.removeLast()
            } else {
                state.calculatorDisplay = "0"
            }
            
        case .equals:
            if let result = evaluateExpression(state.calculatorExpression + state.calculatorDisplay) {
                state.calculatorDisplay = formatResult(result)
                state.calculatorExpression = ""
            }
            
        case .plus, .minus, .multiply, .divide:
            state.calculatorExpression += state.calculatorDisplay + key.rawValue
            state.calculatorDisplay = "0"
            
        case .dot:
            if !state.calculatorDisplay.contains(".") {
                state.calculatorDisplay += "."
            }
            
        default: // digits
            if state.calculatorDisplay == "0" {
                state.calculatorDisplay = key.rawValue
            } else {
                // 限制小数位数为2位
                if let dotIndex = state.calculatorDisplay.firstIndex(of: ".") {
                    let decimals = state.calculatorDisplay[state.calculatorDisplay.index(after: dotIndex)...]
                    if decimals.count >= 2 { return }
                }
                state.calculatorDisplay += key.rawValue
            }
        }
    }
    
    private func evaluateExpression(_ expression: String) -> Decimal? {
        // 简单表达式求值：支持 +−×÷
        let expr = expression
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
        
        // 过滤不安全的表达式 (防止 NSExpression crash)
        let validChars = CharacterSet(charactersIn: "0123456789.+-*/() ")
        guard expr.unicodeScalars.allSatisfy({ validChars.contains($0) }),
              !expr.isEmpty,
              !"+-*/".contains(expr.last!) else {
            return nil
        }
        
        // 防除零
        if expr.contains("/0") { return nil }
        
        guard let nsExpression = try? NSExpression(format: expr) else { return nil }
        if let result = nsExpression.expressionValue(with: nil, context: nil) as? NSNumber {
            return result.decimalValue
        }
        return nil
    }
    
    private func formatResult(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }
}
