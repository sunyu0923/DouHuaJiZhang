import Foundation

/// 攒钱计划模型
struct SavingsPlan: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    var monthlyGoal: Decimal
    var yearlyGoal: Decimal
    var month: Int       // 1-12
    var year: Int         // e.g. 2026
    var modifiedCount: Int  // 当月修改次数，每月最多1次
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        monthlyGoal: Decimal,
        yearlyGoal: Decimal,
        month: Int,
        year: Int,
        modifiedCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.monthlyGoal = monthlyGoal
        self.yearlyGoal = yearlyGoal
        self.month = month
        self.year = year
        self.modifiedCount = modifiedCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// 是否可以修改目标（每月最多1次）
    var canModify: Bool {
        modifiedCount < 1
    }
}

/// 攒钱进度
struct SavingsProgress: Codable, Equatable, Sendable {
    let planId: UUID
    let month: Int
    let year: Int
    let targetAmount: Decimal
    let totalIncome: Decimal
    let totalExpense: Decimal
    
    /// 实际攒钱金额 = 收入 - 支出
    var actualSaved: Decimal {
        totalIncome - totalExpense
    }
    
    /// 差额（正 = 超攒，负 = 欠攒）
    var difference: Decimal {
        actualSaved - targetAmount
    }
    
    /// 进度百分比 (0.0 - 1.0+)
    var progressRatio: Double {
        guard targetAmount > 0 else { return 0 }
        return NSDecimalNumber(decimal: actualSaved / targetAmount).doubleValue
    }
    
    /// 达标状态
    var status: SavingsStatus {
        if actualSaved >= targetAmount {
            return .exceeded
        } else if actualSaved > 0 {
            return .inProgress
        } else {
            return .notStarted
        }
    }
}

enum SavingsStatus: String, Codable, Equatable, Sendable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case exceeded = "exceeded"
    
    var displayName: String {
        switch self {
        case .notStarted: return "未开始"
        case .inProgress: return "进行中"
        case .exceeded: return "已超攒"
        }
    }
}
