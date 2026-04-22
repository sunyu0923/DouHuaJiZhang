import XCTest
@testable import DouHuaJiZhang

final class SyncOperationModelTests: XCTestCase {
    
    func testSyncOperationType_allCases() {
        XCTAssertEqual(SyncOperationType.allCases.count, 3)
    }
    
    func testSyncOperationType_rawValues() {
        XCTAssertEqual(SyncOperationType.create.rawValue, "create")
        XCTAssertEqual(SyncOperationType.update.rawValue, "update")
        XCTAssertEqual(SyncOperationType.delete.rawValue, "delete")
    }
    
    func testSyncOperation_computedId() {
        let operationId = "op-12345"
        let op = SyncOperation(
            operationId: operationId,
            ledgerId: UUID(),
            userId: UUID(),
            type: .create,
            payload: Data("{}".utf8),
            vectorClock: VectorClock(),
            timestamp: Date()
        )
        
        XCTAssertEqual(op.id, operationId)
    }
    
    func testSyncOperation_codable() throws {
        let op = SyncOperation(
            operationId: "test-op-1",
            ledgerId: UUID(),
            userId: UUID(),
            type: .update,
            payload: Data("{\"amount\": 100}".utf8),
            vectorClock: VectorClock(clocks: ["A": 1]),
            timestamp: Date(timeIntervalSince1970: 1000)
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(op)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SyncOperation.self, from: data)
        
        XCTAssertEqual(op.operationId, decoded.operationId)
        XCTAssertEqual(op.type, decoded.type)
    }
}
