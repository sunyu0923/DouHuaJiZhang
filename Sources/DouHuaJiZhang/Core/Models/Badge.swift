import Foundation

/// 勋章类型
enum BadgeType: String, Codable, Equatable, Sendable, CaseIterable {
    // 连续记账勋章
    case streak7 = "streak_7"
    case streak15 = "streak_15"
    case streak30 = "streak_30"
    case streak90 = "streak_90"
    
    // 攒钱达标勋章
    case savingsMonthly = "savings_monthly"
    case savingsQuarterly = "savings_quarterly"
    case savingsYearly = "savings_yearly"
    
    // 邀请好友勋章
    case invite1 = "invite_1"
    case invite3 = "invite_3"
    case invite5 = "invite_5"
    
    // 记账笔数勋章
    case transactions100 = "transactions_100"
    case transactions500 = "transactions_500"
    case transactions1000 = "transactions_1000"
    
    var displayName: String {
        switch self {
        case .streak7: return "初出茅庐"
        case .streak15: return "坚持不懈"
        case .streak30: return "月度之星"
        case .streak90: return "记账达人"
        case .savingsMonthly: return "月度攒手"
        case .savingsQuarterly: return "季度理财师"
        case .savingsYearly: return "年度储蓄王"
        case .invite1: return "交友达人"
        case .invite3: return "社交能手"
        case .invite5: return "人气之星"
        case .transactions100: return "百笔记账"
        case .transactions500: return "五百强"
        case .transactions1000: return "千笔大师"
        }
    }
    
    var description: String {
        switch self {
        case .streak7: return "连续记账7天"
        case .streak15: return "连续记账15天"
        case .streak30: return "连续记账30天"
        case .streak90: return "连续记账90天"
        case .savingsMonthly: return "月度攒钱目标达标"
        case .savingsQuarterly: return "连续3个月攒钱达标"
        case .savingsYearly: return "年度攒钱目标达标"
        case .invite1: return "邀请1位好友"
        case .invite3: return "邀请3位好友"
        case .invite5: return "邀请5位好友"
        case .transactions100: return "累计记账100笔"
        case .transactions500: return "累计记账500笔"
        case .transactions1000: return "累计记账1000笔"
        }
    }
    
    var iconName: String {
        switch self {
        case .streak7, .streak15, .streak30, .streak90:
            return "flame.fill"
        case .savingsMonthly, .savingsQuarterly, .savingsYearly:
            return "banknote.fill"
        case .invite1, .invite3, .invite5:
            return "person.2.fill"
        case .transactions100, .transactions500, .transactions1000:
            return "pencil.circle.fill"
        }
    }
}

/// 勋章模型
struct Badge: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let type: BadgeType
    var name: String
    var isUnlocked: Bool
    var unlockedAt: Date?
    
    init(
        id: UUID = UUID(),
        type: BadgeType,
        name: String? = nil,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name ?? type.displayName
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
}
