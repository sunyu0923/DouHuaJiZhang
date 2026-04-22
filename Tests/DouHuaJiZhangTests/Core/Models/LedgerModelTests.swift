import XCTest
@testable import DouHuaJiZhang

final class LedgerModelTests: XCTestCase {
    
    // MARK: - LedgerType Tests
    
    func testLedgerType_displayNames() {
        XCTAssertEqual(LedgerType.personal.displayName, "个人账本")
        XCTAssertEqual(LedgerType.family.displayName, "家庭账本")
    }
    
    func testLedgerType_allCases() {
        XCTAssertEqual(LedgerType.allCases.count, 2)
    }
    
    // MARK: - MemberRole Tests
    
    func testMemberRole_rawValues() {
        XCTAssertEqual(MemberRole.owner.rawValue, "owner")
        XCTAssertEqual(MemberRole.admin.rawValue, "admin")
        XCTAssertEqual(MemberRole.member.rawValue, "member")
    }
    
    // MARK: - VectorClock Tests
    
    func testVectorClock_init() {
        let vc = VectorClock()
        XCTAssertTrue(vc.clocks.isEmpty)
    }
    
    func testVectorClock_increment() {
        var vc = VectorClock()
        vc.increment(for: "node1")
        
        XCTAssertEqual(vc.clocks["node1"], 1)
        
        vc.increment(for: "node1")
        XCTAssertEqual(vc.clocks["node1"], 2)
        
        vc.increment(for: "node2")
        XCTAssertEqual(vc.clocks["node2"], 1)
    }
    
    func testVectorClock_merge() {
        let vc1 = VectorClock(clocks: ["A": 3, "B": 1])
        let vc2 = VectorClock(clocks: ["A": 2, "B": 5, "C": 1])
        
        let merged = vc1.merged(with: vc2)
        
        XCTAssertEqual(merged.clocks["A"], 3) // max(3, 2)
        XCTAssertEqual(merged.clocks["B"], 5) // max(1, 5)
        XCTAssertEqual(merged.clocks["C"], 1) // max(0, 1)
    }
    
    func testVectorClock_happenedBefore() {
        let vc1 = VectorClock(clocks: ["A": 1, "B": 2])
        let vc2 = VectorClock(clocks: ["A": 2, "B": 3])
        
        XCTAssertTrue(vc1.happenedBefore(vc2))
        XCTAssertFalse(vc2.happenedBefore(vc1))
    }
    
    func testVectorClock_concurrent() {
        let vc1 = VectorClock(clocks: ["A": 3, "B": 1])
        let vc2 = VectorClock(clocks: ["A": 1, "B": 3])
        
        // 并发：双方都不在对方之前
        XCTAssertFalse(vc1.happenedBefore(vc2))
        XCTAssertFalse(vc2.happenedBefore(vc1))
    }
    
    func testVectorClock_equal() {
        let vc1 = VectorClock(clocks: ["A": 1, "B": 2])
        let vc2 = VectorClock(clocks: ["A": 1, "B": 2])
        
        XCTAssertFalse(vc1.happenedBefore(vc2))
        XCTAssertFalse(vc2.happenedBefore(vc1))
        XCTAssertEqual(vc1, vc2)
    }
    
    func testVectorClock_happenedBefore_newNode() {
        let vc1 = VectorClock(clocks: ["A": 1])
        let vc2 = VectorClock(clocks: ["A": 1, "B": 1])
        
        XCTAssertTrue(vc1.happenedBefore(vc2))
    }
    
    func testVectorClock_codable() throws {
        let vc = VectorClock(clocks: ["A": 3, "B": 5])
        
        let data = try JSONEncoder().encode(vc)
        let decoded = try JSONDecoder().decode(VectorClock.self, from: data)
        
        XCTAssertEqual(vc, decoded)
    }
    
    // MARK: - Ledger Tests
    
    func testLedger_init_defaults() {
        let ledger = Ledger(name: "我的账本")
        
        XCTAssertEqual(ledger.name, "我的账本")
        XCTAssertEqual(ledger.type, .personal)
        XCTAssertEqual(ledger.currency, "CNY")
        XCTAssertTrue(ledger.members.isEmpty)
        XCTAssertTrue(ledger.vectorClock.clocks.isEmpty)
    }
    
    func testLedger_familyType() {
        let ledger = Ledger(name: "家庭账本", type: .family)
        
        XCTAssertEqual(ledger.type, .family)
    }
    
    func testLedger_identifiable() {
        let id = UUID()
        let ledger = Ledger(id: id, name: "测试")
        
        XCTAssertEqual(ledger.id, id)
    }
    
    // MARK: - LedgerMember Tests
    
    func testLedgerMember_roles() {
        let member = LedgerMember(
            id: UUID(),
            userId: UUID(),
            nickname: "成员",
            role: .member,
            joinedAt: Date()
        )
        
        XCTAssertEqual(member.role, .member)
    }
}
