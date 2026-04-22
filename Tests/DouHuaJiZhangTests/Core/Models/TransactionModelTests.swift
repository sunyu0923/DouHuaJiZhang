import XCTest
@testable import DouHuaJiZhang

final class TransactionModelTests: XCTestCase {
    
    let ledgerId = UUID()
    let creatorId = UUID()
    
    func testTransactionInit_defaultValues() {
        let tx = Transaction(
            ledgerId: ledgerId,
            creatorId: creatorId,
            amount: 100.50,
            type: .expense,
            category: .dining
        )
        
        XCTAssertEqual(tx.amount, 100.50)
        XCTAssertEqual(tx.type, .expense)
        XCTAssertEqual(tx.category, .dining)
        XCTAssertEqual(tx.note, "")
        XCTAssertTrue(tx.attachments.isEmpty)
    }
    
    func testTransactionInit_fullValues() {
        let id = UUID()
        let opId = UUID()
        let date = Date(timeIntervalSince1970: 0)
        
        let tx = Transaction(
            id: id,
            ledgerId: ledgerId,
            creatorId: creatorId,
            amount: 2500,
            type: .income,
            category: .salary,
            note: "四月工资",
            date: date,
            operationId: opId
        )
        
        XCTAssertEqual(tx.id, id)
        XCTAssertEqual(tx.operationId, opId)
        XCTAssertEqual(tx.amount, 2500)
        XCTAssertEqual(tx.type, .income)
        XCTAssertEqual(tx.category, .salary)
        XCTAssertEqual(tx.note, "四月工资")
    }
    
    func testTransaction_identifiable() {
        let id = UUID()
        let tx = Transaction(id: id, ledgerId: ledgerId, creatorId: creatorId, amount: 50, type: .expense, category: .dining)
        
        XCTAssertEqual(tx.id, id)
    }
    
    func testTransaction_codable() throws {
        let tx = Transaction(
            ledgerId: ledgerId,
            creatorId: creatorId,
            amount: 99.99,
            type: .expense,
            category: .shopping,
            note: "买衣服",
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 1000)
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(tx)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Transaction.self, from: data)
        
        XCTAssertEqual(tx.amount, decoded.amount)
        XCTAssertEqual(tx.type, decoded.type)
        XCTAssertEqual(tx.category, decoded.category)
        XCTAssertEqual(tx.note, decoded.note)
    }
    
    func testTransactionAmount_decimalPrecision() {
        // 确保使用 Decimal 而不是 Float/Double
        let tx = Transaction(
            ledgerId: ledgerId,
            creatorId: creatorId,
            amount: Decimal(string: "0.1")! + Decimal(string: "0.2")!,
            type: .expense,
            category: .dining
        )
        
        // Decimal 不会有浮点精度问题
        XCTAssertEqual(tx.amount, Decimal(string: "0.3"))
    }
    
    func testTransactionType_allCases() {
        XCTAssertEqual(TransactionType.allCases.count, 2)
        XCTAssertEqual(TransactionType.expense.displayName, "支出")
        XCTAssertEqual(TransactionType.income.displayName, "收入")
    }
}
