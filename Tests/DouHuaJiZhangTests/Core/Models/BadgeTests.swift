import XCTest
@testable import DouHuaJiZhang

final class BadgeTests: XCTestCase {
    
    func testBadgeType_allCases() {
        XCTAssertEqual(BadgeType.allCases.count, 13)
    }
    
    func testBadgeType_displayNames() {
        XCTAssertEqual(BadgeType.firstTransaction.displayName, "初次记账")
        XCTAssertEqual(BadgeType.streak7Days.displayName, "连续7天")
        XCTAssertEqual(BadgeType.streak30Days.displayName, "连续30天")
        XCTAssertEqual(BadgeType.firstSavings.displayName, "开始攒钱")
        XCTAssertEqual(BadgeType.savingsGoalMet.displayName, "攒钱达标")
        XCTAssertEqual(BadgeType.firstFamilyLedger.displayName, "家庭记账")
        XCTAssertEqual(BadgeType.budgetMaster.displayName, "预算大师")
        XCTAssertEqual(BadgeType.healthRecorder.displayName, "健康记录者")
    }
    
    func testBadgeType_descriptions() {
        for badgeType in BadgeType.allCases {
            XCTAssertFalse(badgeType.description.isEmpty, "BadgeType \(badgeType.rawValue) should have description")
        }
    }
    
    func testBadgeType_iconNames() {
        for badgeType in BadgeType.allCases {
            XCTAssertFalse(badgeType.iconName.isEmpty, "BadgeType \(badgeType.rawValue) should have icon")
        }
    }
    
    func testBadge_unlocked() {
        let badge = Badge(
            type: .firstTransaction,
            name: "初次记账",
            isUnlocked: true,
            unlockedAt: Date()
        )
        
        XCTAssertTrue(badge.isUnlocked)
        XCTAssertNotNil(badge.unlockedAt)
    }
    
    func testBadge_locked() {
        let badge = Badge(
            type: .streak30Days,
            name: "连续30天",
            isUnlocked: false
        )
        
        XCTAssertFalse(badge.isUnlocked)
        XCTAssertNil(badge.unlockedAt)
    }
    
    func testBadge_codable() throws {
        let badge = Badge(
            type: .firstTransaction,
            name: "初次记账",
            isUnlocked: true,
            unlockedAt: Date(timeIntervalSince1970: 1000)
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(badge)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Badge.self, from: data)
        
        XCTAssertEqual(badge.type, decoded.type)
        XCTAssertEqual(badge.isUnlocked, decoded.isUnlocked)
    }
}
