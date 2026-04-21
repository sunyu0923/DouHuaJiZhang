import Foundation

/// 投资产品类型
enum InvestmentType: String, Codable, Equatable, Sendable, CaseIterable {
    case stock = "stock"                   // 股票
    case fund = "fund"                     // 基金
    case fixedDeposit = "fixed_deposit"    // 定期存款
    case gold = "gold"                     // 黄金
    case forex = "forex"                   // 外汇
    case bond = "bond"                     // 债券
    case crypto = "crypto"                 // 加密货币
    case other = "other"                   // 其他
    
    var displayName: String {
        switch self {
        case .stock: return "股票"
        case .fund: return "基金"
        case .fixedDeposit: return "定期存款"
        case .gold: return "黄金"
        case .forex: return "外汇"
        case .bond: return "债券"
        case .crypto: return "加密货币"
        case .other: return "其他"
        }
    }
}

/// 投资产品模型
struct Investment: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    var name: String
    var type: InvestmentType
    var amount: Decimal           // 持仓金额/存款金额
    var currentValue: Decimal     // 当前价值
    var maturityDate: Date?       // 到期日期（定期存款专属）
    var interestRate: Decimal?    // 利率（定期存款专属）
    var symbol: String?           // 股票/基金代码
    var quantity: Decimal?        // 持仓数量
    var buyPrice: Decimal?        // 买入价格
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        type: InvestmentType,
        amount: Decimal,
        currentValue: Decimal,
        maturityDate: Date? = nil,
        interestRate: Decimal? = nil,
        symbol: String? = nil,
        quantity: Decimal? = nil,
        buyPrice: Decimal? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = type
        self.amount = amount
        self.currentValue = currentValue
        self.maturityDate = maturityDate
        self.interestRate = interestRate
        self.symbol = symbol
        self.quantity = quantity
        self.buyPrice = buyPrice
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// 收益
    var profit: Decimal {
        currentValue - amount
    }
    
    /// 收益率
    var profitRate: Double {
        guard amount > 0 else { return 0 }
        return NSDecimalNumber(decimal: profit / amount).doubleValue
    }
}

/// 行情数据
struct MarketQuote: Identifiable, Codable, Equatable, Sendable {
    let id: String              // 品类代码
    var name: String
    var price: Decimal
    var change: Decimal         // 涨跌金额
    var changePercent: Double   // 涨跌幅度 e.g. 0.05 = 5%
    var category: MarketCategory
    var updatedAt: Date
    
    var isUp: Bool { change > 0 }
    var isDown: Bool { change < 0 }
}

/// 行情分类
enum MarketCategory: String, Codable, Equatable, Sendable, CaseIterable {
    case aStock = "a_stock"         // A股
    case usStock = "us_stock"       // 美股
    case goldSilver = "gold_silver" // 金银
    case fund = "fund"              // 基金
    case forex = "forex"            // 外币汇率
    
    var displayName: String {
        switch self {
        case .aStock: return "A股"
        case .usStock: return "美股"
        case .goldSilver: return "金银"
        case .fund: return "基金"
        case .forex: return "外汇"
        }
    }
}
