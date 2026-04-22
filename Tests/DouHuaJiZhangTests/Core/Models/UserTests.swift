import XCTest
@testable import DouHuaJiZhang

final class UserTests: XCTestCase {
    
    func testUserInit_defaultValues() {
        let user = User(phone: "13800138000", nickname: "豆花")
        
        XCTAssertFalse(user.id.uuidString.isEmpty)
        XCTAssertEqual(user.phone, "13800138000")
        XCTAssertEqual(user.nickname, "豆花")
        XCTAssertNil(user.avatarURL)
    }
    
    func testUserInit_customValues() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 0)
        let url = URL(string: "https://example.com/avatar.png")!
        
        let user = User(
            id: id,
            phone: "13900139000",
            nickname: "测试用户",
            avatarURL: url,
            createdAt: date
        )
        
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.phone, "13900139000")
        XCTAssertEqual(user.nickname, "测试用户")
        XCTAssertEqual(user.avatarURL, url)
        XCTAssertEqual(user.createdAt, date)
    }
    
    func testUserEquality() {
        let id = UUID()
        let user1 = User(id: id, phone: "13800138000", nickname: "豆花")
        let user2 = User(id: id, phone: "13800138000", nickname: "豆花")
        
        XCTAssertEqual(user1, user2)
    }
    
    func testUserInequality() {
        let user1 = User(phone: "13800138000", nickname: "豆花")
        let user2 = User(phone: "13900139000", nickname: "花生")
        
        XCTAssertNotEqual(user1, user2)
    }
    
    func testUserCodable() throws {
        let id = UUID()
        let user = User(
            id: id,
            phone: "13800138000",
            nickname: "豆花",
            createdAt: Date(timeIntervalSince1970: 1000)
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(user)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(User.self, from: data)
        
        XCTAssertEqual(user, decoded)
    }
    
    func testUserMutation() {
        var user = User(phone: "13800138000", nickname: "豆花")
        
        user.phone = "13900139000"
        user.nickname = "修改后的昵称"
        
        XCTAssertEqual(user.phone, "13900139000")
        XCTAssertEqual(user.nickname, "修改后的昵称")
    }
}
