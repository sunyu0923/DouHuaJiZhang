import Foundation

/// 账单/交易模型
struct Transaction: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let ledgerId: UUID
    let creatorId: UUID
    var amount: Decimal
    var type: TransactionType
    var category: TransactionCategory
    var note: String
    var attachments: [URL]
    var date: Date
    let createdAt: Date
    var updatedAt: Date
    
    /// 幂等操作ID
    let operationId: UUID
    
    init(
        id: UUID = UUID(),
        ledgerId: UUID,
        creatorId: UUID,
        amount: Decimal,
        type: TransactionType,
        category: TransactionCategory,
        note: String = "",
        attachments: [URL] = [],
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        operationId: UUID = UUID()
    ) {
        self.id = id
        self.ledgerId = ledgerId
        self.creatorId = creatorId
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.attachments = attachments
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.operationId = operationId
    }
}
