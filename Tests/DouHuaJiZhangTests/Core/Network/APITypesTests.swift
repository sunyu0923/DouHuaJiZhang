import XCTest
@testable import DouHuaJiZhang

/// API 层 DTOs 和辅助类型的单元测试
final class APITypesTests: XCTestCase {
    
    // MARK: - APIError
    
    func testAPIError_localizedDescription() {
        XCTAssertEqual(APIError.unauthorized.errorDescription, "登录已过期，请重新登录")
        XCTAssertEqual(APIError.forbidden.errorDescription, "没有访问权限")
        XCTAssertEqual(APIError.notFound.errorDescription, "资源不存在")
        XCTAssertEqual(APIError.conflict.errorDescription, "数据冲突，请刷新后重试")
        XCTAssertEqual(APIError.validationError("手机号格式错误").errorDescription, "手机号格式错误")
        XCTAssertEqual(APIError.serverError(500).errorDescription, "服务器错误(500)")
        XCTAssertEqual(APIError.networkError("超时").errorDescription, "网络错误: 超时")
        XCTAssertEqual(APIError.decodingError("JSON").errorDescription, "数据解析错误: JSON")
        XCTAssertEqual(APIError.unknown("未知").errorDescription, "未知")
    }
    
    func testAPIError_equatable() {
        XCTAssertEqual(APIError.unauthorized, APIError.unauthorized)
        XCTAssertNotEqual(APIError.unauthorized, APIError.forbidden)
        XCTAssertEqual(APIError.serverError(500), APIError.serverError(500))
        XCTAssertNotEqual(APIError.serverError(500), APIError.serverError(502))
    }
    
    // MARK: - PaginatedResponse
    
    func testPaginatedResponse_hasNextPage_true() {
        let response = PaginatedResponse<Transaction>(
            items: [],
            total: 50,
            page: 1,
            pageSize: 20
        )
        
        XCTAssertTrue(response.hasNextPage) // 1 * 20 = 20 < 50
    }
    
    func testPaginatedResponse_hasNextPage_false() {
        let response = PaginatedResponse<Transaction>(
            items: [],
            total: 50,
            page: 3,
            pageSize: 20
        )
        
        XCTAssertFalse(response.hasNextPage) // 3 * 20 = 60 >= 50
    }
    
    func testPaginatedResponse_hasNextPage_exact() {
        let response = PaginatedResponse<Transaction>(
            items: [],
            total: 40,
            page: 2,
            pageSize: 20
        )
        
        XCTAssertFalse(response.hasNextPage) // 2 * 20 = 40 == 40
    }
    
    // MARK: - CalendarDayData
    
    func testCalendarDayData_id() {
        let data = CalendarDayData(date: "2026-04-21", expense: 100, income: 200)
        
        XCTAssertEqual(data.id, "2026-04-21")
    }
    
    // MARK: - DailyAmount
    
    func testDailyAmount_id() {
        let daily = DailyAmount(date: "2026-04-21", expense: 50, income: 100)
        
        XCTAssertEqual(daily.id, "2026-04-21")
    }
    
    // MARK: - CategoryAmount
    
    func testCategoryAmount_id() {
        let ca = CategoryAmount(category: .dining, amount: 500, percentage: 0.25)
        
        XCTAssertEqual(ca.id, "dining")
    }
    
    // MARK: - StatisticsData
    
    func testStatisticsData_codable() throws {
        let stats = StatisticsData(
            totalExpense: 5000,
            totalIncome: 12000,
            balance: 7000,
            categoryBreakdown: [
                CategoryAmount(category: .dining, amount: 2000, percentage: 0.4)
            ],
            dailyTrend: [
                DailyAmount(date: "2026-04-21", expense: 100, income: 500)
            ]
        )
        
        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(StatisticsData.self, from: data)
        
        XCTAssertEqual(stats, decoded)
    }
}
