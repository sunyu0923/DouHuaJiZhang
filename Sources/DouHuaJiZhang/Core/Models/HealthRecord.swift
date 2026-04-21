import Foundation

/// 拉屎记录模型
struct PoopRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    var date: Date
    var time: Date
    var note: String    // 最多20字，如"正常/便秘"
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date = Date(),
        time: Date = Date(),
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.time = time
        self.note = note
        self.createdAt = createdAt
    }
}

/// 月经记录模型
struct MenstrualRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    var startDate: Date
    var endDate: Date?
    var cycleLength: Int?     // 周期天数（自动计算）
    var note: String
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        startDate: Date,
        endDate: Date? = nil,
        cycleLength: Int? = nil,
        note: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.startDate = startDate
        self.endDate = endDate
        self.cycleLength = cycleLength
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// 月经持续天数
    var durationDays: Int? {
        guard let endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day.map { $0 + 1 }
    }
}

/// 月经预测数据
struct MenstrualPrediction: Codable, Equatable, Sendable {
    let nextPeriodDate: Date
    let ovulationDate: Date
    let averageCycleLength: Int
    let averageDuration: Int
}
