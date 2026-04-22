import XCTest
@testable import DouHuaJiZhang

final class SavingsPlanTests: XCTestCase {
    
    let userId = UUID()
    
    func testSavingsPlan_init() {
        let plan = SavingsPlan(
            userId: userId,
            monthlyGoal: 5000,
            yearlyGoal: 60000,
            month: 4,
            year: 2026
        )
        
        XCTAssertEqual(plan.monthlyGoal, 5000)
        XCTAssertEqual(plan.yearlyGoal, 60000)
        XCTAssertEqual(plan.month, 4)
        XCTAssertEqual(plan.year, 2026)
        XCTAssertEqual(plan.modifiedCount, 0)
    }
    
    func testSavingsPlan_canModify() {
        var plan = SavingsPlan(
            userId: userId,
            monthlyGoal: 5000,
            yearlyGoal: 60000,
            month: 4,
            year: 2026,
            modifiedCount: 0
        )
        
        XCTAssertTrue(plan.canModify)
        
        plan.modifiedCount = 1
        XCTAssertFalse(plan.canModify)
    }
    
    // MARK: - SavingsProgress Tests
    
    func testSavingsProgress_actualSaved() {
        let progress = SavingsProgress(
            planId: UUID(),
            month: 4,
            year: 2026,
            targetAmount: 5000,
            totalIncome: 15000,
            totalExpense: 8000
        )
        
        XCTAssertEqual(progress.actualSaved, 7000) // 15000 - 8000
    }
    
    func testSavingsProgress_difference_positive() {
        let progress = SavingsProgress(
            planId: UUID(),
            month: 4,
            year: 2026,
            targetAmount: 5000,
            totalIncome: 15000,
            totalExpense: 8000
        )
        
        XCTAssertEqual(progress.difference, 2000) // 7000 - 5000
    }
    
    func testSavingsProgress_difference_negative() {
        let progress = SavingsProgress(
            planId: UUID(),
            month: 4,
            year: 2026,
            targetAmount: 10000,
            totalIncome: 15000,
            totalExpense: 12000
        )
        
        XCTAssertEqual(progress.difference, -7000) // 3000 - 10000
    }
    
    func testSavingsProgress_ratio() {
        let progress = SavingsProgress(
            planId: UUID(),
            month: 4,
            year: 2026,
            targetAmount: 5000,
            totalIncome: 15000,
            totalExpense: 10000
        )
        
        XCTAssertEqual(progress.progressRatio, 1.0, accuracy: 0.01) // 5000/5000 = 1.0
    }
    
    func testSavingsProgress_ratio_zeroTarget() {
        let progress = SavingsProgress(
            planId: UUID(),
            month: 4,
            year: 2026,
            targetAmount: 0,
            totalIncome: 15000,
            totalExpense: 10000
        )
        
        XCTAssertEqual(progress.progressRatio, 0)
    }
    
    func testSavingsProgress_status_exceeded() {
        let progress = SavingsProgress(
            planId: UUID(),
            month: 4,
            year: 2026,
            targetAmount: 5000,
            totalIncome: 15000,
            totalExpense: 8000
        )
        
        XCTAssertEqual(progress.status, .exceeded) // actualSaved 7000 >= 5000
    }
    
    func testSavingsProgress_status_inProgress() {
        let progress = SavingsProgress(
            planId: UUID(),
            month: 4,
            year: 2026,
            targetAmount: 10000,
            totalIncome: 15000,
            totalExpense: 12000
        )
        
        XCTAssertEqual(progress.status, .inProgress) // actualSaved 3000 > 0 but < 10000
    }
    
    func testSavingsProgress_status_notStarted() {
        let progress = SavingsProgress(
            planId: UUID(),
            month: 4,
            year: 2026,
            targetAmount: 5000,
            totalIncome: 10000,
            totalExpense: 10000
        )
        
        XCTAssertEqual(progress.status, .notStarted) // actualSaved = 0
    }
    
    func testSavingsStatus_displayNames() {
        XCTAssertEqual(SavingsStatus.notStarted.displayName, "未开始")
        XCTAssertEqual(SavingsStatus.inProgress.displayName, "进行中")
        XCTAssertEqual(SavingsStatus.exceeded.displayName, "已超攒")
    }
}
