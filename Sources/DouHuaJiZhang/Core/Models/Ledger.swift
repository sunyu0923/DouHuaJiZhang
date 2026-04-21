import Foundation

/// 账本类型
enum LedgerType: String, Codable, Equatable, Sendable, CaseIterable {
    case personal = "personal"
    case family = "family"
    
    var displayName: String {
        switch self {
        case .personal: return "个人账本"
        case .family: return "家庭账本"
        }
    }
}

/// 账本成员角色
enum MemberRole: String, Codable, Equatable, Sendable {
    case owner = "owner"
    case admin = "admin"
    case member = "member"
}

/// 账本成员
struct LedgerMember: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    var nickname: String
    var avatarURL: URL?
    var role: MemberRole
    let joinedAt: Date
}

/// 向量时钟 — 用于协同同步冲突解决
struct VectorClock: Codable, Equatable, Sendable {
    var clocks: [String: Int]
    
    init(clocks: [String: Int] = [:]) {
        self.clocks = clocks
    }
    
    mutating func increment(for nodeId: String) {
        clocks[nodeId, default: 0] += 1
    }
    
    func merged(with other: VectorClock) -> VectorClock {
        var result = clocks
        for (key, value) in other.clocks {
            result[key] = max(result[key, default: 0], value)
        }
        return VectorClock(clocks: result)
    }
    
    /// 判断 self 是否在 other 之前发生
    func happenedBefore(_ other: VectorClock) -> Bool {
        var atLeastOneLess = false
        for (key, value) in clocks {
            let otherValue = other.clocks[key, default: 0]
            if value > otherValue { return false }
            if value < otherValue { atLeastOneLess = true }
        }
        for (key, value) in other.clocks where clocks[key] == nil {
            if value > 0 { atLeastOneLess = true }
        }
        return atLeastOneLess
    }
}

/// 账本模型
struct Ledger: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var type: LedgerType
    var currency: String  // ISO 4217
    var members: [LedgerMember]
    var vectorClock: VectorClock
    var coverImageURL: URL?
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        type: LedgerType = .personal,
        currency: String = "CNY",
        members: [LedgerMember] = [],
        vectorClock: VectorClock = VectorClock(),
        coverImageURL: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.currency = currency
        self.members = members
        self.vectorClock = vectorClock
        self.coverImageURL = coverImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
