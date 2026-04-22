import ComposableArchitecture
import XCTest
@testable import DouHuaJiZhang

@MainActor
final class TransactionFeatureTests: XCTestCase {
    
    let ledgerId = UUID()
    
    // MARK: - State computed properties
    
    func testAmount_fromDisplay() {
        var state = TransactionFeature.State(ledgerId: ledgerId)
        state.calculatorDisplay = "123.45"
        
        XCTAssertEqual(state.amount, Decimal(string: "123.45"))
    }
    
    func testCanSubmit_noCategory() {
        var state = TransactionFeature.State(ledgerId: ledgerId)
        state.calculatorDisplay = "100"
        state.selectedCategory = nil
        
        XCTAssertFalse(state.canSubmit)
    }
    
    func testCanSubmit_zeroAmount() {
        var state = TransactionFeature.State(ledgerId: ledgerId)
        state.calculatorDisplay = "0"
        state.selectedCategory = .dining
        
        XCTAssertFalse(state.canSubmit)
    }
    
    func testCanSubmit_valid() {
        var state = TransactionFeature.State(ledgerId: ledgerId)
        state.calculatorDisplay = "100"
        state.selectedCategory = .dining
        
        XCTAssertTrue(state.canSubmit)
    }
    
    func testCurrentCategories_expense() {
        var state = TransactionFeature.State(ledgerId: ledgerId)
        state.transactionType = .expense
        
        XCTAssertEqual(state.currentCategories.count, 30)
    }
    
    func testCurrentCategories_income() {
        var state = TransactionFeature.State(ledgerId: ledgerId)
        state.transactionType = .income
        
        XCTAssertEqual(state.currentCategories.count, 9)
    }
    
    // MARK: - Transaction Type / Category
    
    func testSetTransactionType_clearsCategory() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.transactionType = .expense
                state.selectedCategory = .dining
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.setTransactionType(.income)) {
            $0.transactionType = .income
            $0.selectedCategory = nil
        }
    }
    
    func testSelectCategory() async {
        let store = TestStore(
            initialState: TransactionFeature.State(ledgerId: ledgerId)
        ) {
            TransactionFeature()
        }
        
        await store.send(.selectCategory(.shopping)) {
            $0.selectedCategory = .shopping
            $0.douhuaQuote = TransactionCategory.shopping.douhuaQuote
        }
    }
    
    // MARK: - Calculator: Digit Input
    
    func testCalculator_digitInput_replacesZero() async {
        let store = TestStore(
            initialState: TransactionFeature.State(ledgerId: ledgerId)
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.five)) {
            $0.calculatorDisplay = "5"
        }
    }
    
    func testCalculator_digitInput_appends() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "12"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.three)) {
            $0.calculatorDisplay = "123"
        }
    }
    
    func testCalculator_dot_addsDecimalPoint() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "5"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.dot)) {
            $0.calculatorDisplay = "5."
        }
    }
    
    func testCalculator_dot_ignoreDuplicate() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "5.2"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        // Second dot should be ignored
        await store.send(.calculatorInput(.dot))
    }
    
    func testCalculator_decimalLimit_twoPlaces() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "5.12"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        // Third decimal digit should be ignored
        await store.send(.calculatorInput(.three))
    }
    
    // MARK: - Calculator: Clear / Backspace
    
    func testCalculator_clear() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "123"
                state.calculatorExpression = "500+"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.clear)) {
            $0.calculatorDisplay = "0"
            $0.calculatorExpression = ""
        }
    }
    
    func testCalculator_backspace() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "123"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.backspace)) {
            $0.calculatorDisplay = "12"
        }
    }
    
    func testCalculator_backspace_singleDigit() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "5"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.backspace)) {
            $0.calculatorDisplay = "0"
        }
    }
    
    // MARK: - Calculator: Operators
    
    func testCalculator_operator_plus() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "100"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.plus)) {
            $0.calculatorExpression = "100+"
            $0.calculatorDisplay = "0"
        }
    }
    
    func testCalculator_equals_addition() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorExpression = "100+"
                state.calculatorDisplay = "50"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.equals)) {
            $0.calculatorDisplay = "150"
            $0.calculatorExpression = ""
        }
    }
    
    func testCalculator_equals_subtraction() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorExpression = "200-"
                state.calculatorDisplay = "50"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.equals)) {
            $0.calculatorDisplay = "150"
            $0.calculatorExpression = ""
        }
    }
    
    func testCalculator_equals_multiplication() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorExpression = "25×"
                state.calculatorDisplay = "4"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.equals)) {
            $0.calculatorDisplay = "100"
            $0.calculatorExpression = ""
        }
    }
    
    func testCalculator_equals_division() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorExpression = "100÷"
                state.calculatorDisplay = "4"
                return state
            }()
        ) {
            TransactionFeature()
        }
        
        await store.send(.calculatorInput(.equals)) {
            $0.calculatorDisplay = "25"
            $0.calculatorExpression = ""
        }
    }
    
    // MARK: - Submit
    
    func testSubmit_success() async {
        let savedTx = Transaction(
            ledgerId: ledgerId,
            creatorId: UUID(),
            amount: 100,
            type: .expense,
            category: .dining
        )
        
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "100"
                state.selectedCategory = .dining
                return state
            }()
        ) {
            TransactionFeature()
        } withDependencies: {
            $0.apiClient.createTransaction = { _, _ in savedTx }
        }
        
        await store.send(.submit) {
            $0.isLoading = true
        }
        
        await store.receive(\.submitResponse.success) {
            $0.isLoading = false
            // douhuaQuote changes
        }
        
        await store.receive(\.transactionSaved)
    }
    
    func testSubmit_failure() async {
        let store = TestStore(
            initialState: {
                var state = TransactionFeature.State(ledgerId: self.ledgerId)
                state.calculatorDisplay = "100"
                state.selectedCategory = .dining
                return state
            }()
        ) {
            TransactionFeature()
        } withDependencies: {
            $0.apiClient.createTransaction = { _, _ in throw APIError.serverError(500) }
        }
        
        await store.send(.submit) {
            $0.isLoading = true
        }
        
        await store.receive(\.submitResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = "服务器错误(500)"
        }
    }
    
    // MARK: - Date
    
    func testSetDate() async {
        let newDate = Date(timeIntervalSince1970: 1000)
        
        let store = TestStore(
            initialState: TransactionFeature.State(ledgerId: ledgerId)
        ) {
            TransactionFeature()
        }
        
        await store.send(.setDate(newDate)) {
            $0.selectedDate = newDate
        }
    }
}
