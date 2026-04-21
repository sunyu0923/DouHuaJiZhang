import Foundation

/// 同步操作类型
enum SyncOperationType: String, Codable, Equatable, Sendable {
    case create = "create"
    case update = "update"
    case delete = "delete"
}

/// 协同同步操作
struct SyncOperation: Identifiable, Codable, Equatable, Sendable {
    var id: UUID { operationId }
    
    let operationId: UUID
    let ledgerId: UUID
    let userId: UUID
    let type: SyncOperationType
    let payload: Data       // JSON encoded payload
    let vectorClock: VectorClock
    let timestamp: Date
    
    init(
        operationId: UUID = UUID(),
        ledgerId: UUID,
        userId: UUID,
        type: SyncOperationType,
        payload: Data,
        vectorClock: VectorClock,
        timestamp: Date = Date()
    ) {
        self.operationId = operationId
        self.ledgerId = ledgerId
        self.userId = userId
        self.type = type
        self.payload = payload
        self.vectorClock = vectorClock
        self.timestamp = timestamp
    }
}
