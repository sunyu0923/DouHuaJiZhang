import XCTest
@testable import DouHuaJiZhang

final class TransactionCategoryTests: XCTestCase {
    
    func testExpenseCategories_count() {
        XCTAssertEqual(TransactionCategory.expenseCategories.count, 30)
    }
    
    func testIncomeCategories_count() {
        XCTAssertEqual(TransactionCategory.incomeCategories.count, 9)
    }
    
    func testAllCases_totalCount() {
        XCTAssertEqual(TransactionCategory.allCases.count, 39)
    }
    
    func testExpenseCategory_transactionType() {
        for category in TransactionCategory.expenseCategories {
            XCTAssertEqual(category.transactionType, .expense, "Category \(category.rawValue) should be expense")
        }
    }
    
    func testIncomeCategory_transactionType() {
        for category in TransactionCategory.incomeCategories {
            XCTAssertEqual(category.transactionType, .income, "Category \(category.rawValue) should be income")
        }
    }
    
    func testAllCategories_haveDisplayName() {
        for category in TransactionCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "Category \(category.rawValue) should have a display name")
        }
    }
    
    func testAllCategories_haveIconName() {
        for category in TransactionCategory.allCases {
            XCTAssertFalse(category.iconName.isEmpty, "Category \(category.rawValue) should have an icon")
        }
    }
    
    func testAllCategories_haveDouhuaQuote() {
        for category in TransactionCategory.allCases {
            XCTAssertFalse(category.douhuaQuote.isEmpty, "Category \(category.rawValue) needs a quote")
        }
    }
    
    func testSpecificExpenseCategories() {
        XCTAssertEqual(TransactionCategory.dining.displayName, "餐饮")
        XCTAssertEqual(TransactionCategory.shopping.displayName, "购物")
        XCTAssertEqual(TransactionCategory.transport.displayName, "交通")
        XCTAssertEqual(TransactionCategory.pets.displayName, "宠物")
    }
    
    func testSpecificIncomeCategories() {
        XCTAssertEqual(TransactionCategory.salary.displayName, "工资")
        XCTAssertEqual(TransactionCategory.bonus.displayName, "奖金")
        XCTAssertEqual(TransactionCategory.redPacket.displayName, "红包")
    }
    
    func testCategory_codable() throws {
        let category = TransactionCategory.dining
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(TransactionCategory.self, from: data)
        
        XCTAssertEqual(category, decoded)
    }
    
    func testCategory_rawValues() {
        XCTAssertEqual(TransactionCategory.dining.rawValue, "dining")
        XCTAssertEqual(TransactionCategory.otherExpense.rawValue, "other_expense")
        XCTAssertEqual(TransactionCategory.salary.rawValue, "salary")
        XCTAssertEqual(TransactionCategory.otherIncome.rawValue, "other_income")
    }
}
