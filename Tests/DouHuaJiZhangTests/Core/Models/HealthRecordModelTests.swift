import XCTest
@testable import DouHuaJiZhang

final class HealthRecordModelTests: XCTestCase {
    
    let userId = UUID()
    
    // MARK: - PoopRecord Tests
    
    func testPoopRecord_init() {
        let record = PoopRecord(userId: userId, note: "正常")
        
        XCTAssertEqual(record.userId, userId)
        XCTAssertEqual(record.note, "正常")
    }
    
    func testPoopRecord_defaultNote() {
        let record = PoopRecord(userId: userId)
        
        XCTAssertEqual(record.note, "")
    }
    
    func testPoopRecord_codable() throws {
        let record = PoopRecord(
            userId: userId,
            date: Date(timeIntervalSince1970: 1000),
            note: "测试"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PoopRecord.self, from: data)
        
        XCTAssertEqual(record.userId, decoded.userId)
        XCTAssertEqual(record.note, decoded.note)
    }
    
    // MARK: - MenstrualRecord Tests
    
    func testMenstrualRecord_durationDays() {
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let end = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 6))!
        
        let record = MenstrualRecord(
            userId: userId,
            startDate: start,
            endDate: end
        )
        
        XCTAssertEqual(record.durationDays, 5)
    }
    
    func testMenstrualRecord_durationDays_nilEndDate() {
        let record = MenstrualRecord(
            userId: userId,
            startDate: Date(),
            endDate: nil
        )
        
        XCTAssertNil(record.durationDays)
    }
    
    func testMenstrualRecord_cycleLength_default() {
        let record = MenstrualRecord(
            userId: userId,
            startDate: Date()
        )
        
        XCTAssertEqual(record.cycleLength, 28)
    }
    
    func testMenstrualRecord_customCycleLength() {
        let record = MenstrualRecord(
            userId: userId,
            startDate: Date(),
            cycleLength: 30
        )
        
        XCTAssertEqual(record.cycleLength, 30)
    }
    
    func testMenstrualRecord_codable() throws {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 500000)
        
        let record = MenstrualRecord(
            userId: userId,
            startDate: start,
            endDate: end,
            cycleLength: 28
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(MenstrualRecord.self, from: data)
        
        XCTAssertEqual(record.userId, decoded.userId)
        XCTAssertEqual(record.cycleLength, decoded.cycleLength)
    }
    
    // MARK: - MenstrualPrediction Tests
    
    func testMenstrualPrediction_init() {
        let nextStart = Date()
        let nextEnd = Calendar.current.date(byAdding: .day, value: 5, to: nextStart)!
        
        let prediction = MenstrualPrediction(
            nextStartDate: nextStart,
            nextEndDate: nextEnd,
            averageCycleLength: 28,
            averageDuration: 5
        )
        
        XCTAssertEqual(prediction.averageCycleLength, 28)
        XCTAssertEqual(prediction.averageDuration, 5)
    }
}
