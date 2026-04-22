import XCTest
@testable import DouHuaJiZhang

final class InvestmentModelTests: XCTestCase {
    
    let userId = UUID()
    
    func testInvestmentType_allCases() {
        XCTAssertEqual(InvestmentType.allCases.count, 8)
    }
    
    func testInvestmentType_displayNames() {
        XCTAssertEqual(InvestmentType.stock.displayName, "股票")
        XCTAssertEqual(InvestmentType.fund.displayName, "基金")
        XCTAssertEqual(InvestmentType.fixedDeposit.displayName, "定期存款")
        XCTAssertEqual(InvestmentType.gold.displayName, "黄金")
        XCTAssertEqual(InvestmentType.forex.displayName, "外汇")
        XCTAssertEqual(InvestmentType.bond.displayName, "债券")
        XCTAssertEqual(InvestmentType.crypto.displayName, "加密货币")
        XCTAssertEqual(InvestmentType.other.displayName, "其他")
    }
    
    func testInvestment_profit_positive() {
        let inv = Investment(
            userId: userId,
            name: "腾讯控股",
            type: .stock,
            amount: 10000,
            currentValue: 12000
        )
        
        XCTAssertEqual(inv.profit, 2000)
    }
    
    func testInvestment_profit_negative() {
        let inv = Investment(
            userId: userId,
            name: "比特币",
            type: .crypto,
            amount: 50000,
            currentValue: 35000
        )
        
        XCTAssertEqual(inv.profit, -15000)
    }
    
    func testInvestment_profit_zero() {
        let inv = Investment(
            userId: userId,
            name: "余额宝",
            type: .fund,
            amount: 10000,
            currentValue: 10000
        )
        
        XCTAssertEqual(inv.profit, 0)
    }
    
    func testInvestment_profitRate() {
        let inv = Investment(
            userId: userId,
            name: "沪深300",
            type: .fund,
            amount: 10000,
            currentValue: 12000
        )
        
        XCTAssertEqual(inv.profitRate, 0.2, accuracy: 0.001) // 2000/10000 = 0.2
    }
    
    func testInvestment_profitRate_zeroAmount() {
        let inv = Investment(
            userId: userId,
            name: "测试",
            type: .other,
            amount: 0,
            currentValue: 100
        )
        
        XCTAssertEqual(inv.profitRate, 0)
    }
    
    func testInvestment_profitRate_negative() {
        let inv = Investment(
            userId: userId,
            name: "A股",
            type: .stock,
            amount: 10000,
            currentValue: 8000
        )
        
        XCTAssertEqual(inv.profitRate, -0.2, accuracy: 0.001) // -2000/10000
    }
    
    // MARK: - MarketQuote Tests
    
    func testMarketQuote_isUp() {
        let quote = MarketQuote(
            id: "600519",
            name: "贵州茅台",
            price: 1800,
            change: 50,
            changePercent: 0.028,
            category: .aStock,
            updatedAt: Date()
        )
        
        XCTAssertTrue(quote.isUp)
        XCTAssertFalse(quote.isDown)
    }
    
    func testMarketQuote_isDown() {
        let quote = MarketQuote(
            id: "AAPL",
            name: "苹果",
            price: 170,
            change: -5,
            changePercent: -0.029,
            category: .usStock,
            updatedAt: Date()
        )
        
        XCTAssertTrue(quote.isDown)
        XCTAssertFalse(quote.isUp)
    }
    
    func testMarketCategory_displayNames() {
        XCTAssertEqual(MarketCategory.aStock.displayName, "A股")
        XCTAssertEqual(MarketCategory.usStock.displayName, "美股")
        XCTAssertEqual(MarketCategory.goldSilver.displayName, "金银")
        XCTAssertEqual(MarketCategory.fund.displayName, "基金")
        XCTAssertEqual(MarketCategory.forex.displayName, "外汇")
    }
    
    func testMarketCategory_allCases() {
        XCTAssertEqual(MarketCategory.allCases.count, 5)
    }
}
