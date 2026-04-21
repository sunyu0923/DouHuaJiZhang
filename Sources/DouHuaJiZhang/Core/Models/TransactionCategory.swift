import SwiftUI

/// 收支类型
enum TransactionType: String, Codable, Equatable, Sendable, CaseIterable {
    case expense = "expense"
    case income = "income"
    
    var displayName: String {
        switch self {
        case .expense: return "支出"
        case .income: return "收入"
        }
    }
}

/// 交易分类 — 支出30个 + 收入9个
enum TransactionCategory: String, Codable, Equatable, Sendable, CaseIterable {
    // MARK: - 支出分类 (30个)
    case dining = "dining"                   // 餐饮
    case shopping = "shopping"               // 购物
    case transport = "transport"             // 交通
    case entertainment = "entertainment"     // 娱乐
    case housing = "housing"                 // 住房
    case utilities = "utilities"             // 水电
    case communication = "communication"     // 通讯
    case medical = "medical"                 // 医疗
    case education = "education"             // 教育
    case travel = "travel"                   // 旅行
    case clothing = "clothing"               // 服饰
    case beauty = "beauty"                   // 美容
    case sports = "sports"                   // 运动
    case pets = "pets"                       // 宠物
    case gifts = "gifts"                     // 礼物
    case socializing = "socializing"         // 社交
    case snacks = "snacks"                   // 零食
    case fruits = "fruits"                   // 水果
    case vegetables = "vegetables"           // 蔬菜
    case drinks = "drinks"                   // 饮品
    case digital = "digital"                 // 数码
    case household = "household"             // 家居
    case baby = "baby"                       // 母婴
    case elderly = "elderly"                 // 长辈
    case maintenance = "maintenance"         // 维修
    case books = "books"                     // 书籍
    case office = "office"                   // 办公
    case insurance = "insurance"             // 保险
    case tax = "tax"                         // 税费
    case otherExpense = "other_expense"      // 其他支出
    
    // MARK: - 收入分类 (9个)
    case salary = "salary"                   // 工资
    case bonus = "bonus"                     // 奖金
    case partTime = "part_time"              // 兼职
    case investmentIncome = "investment_income" // 理财收入
    case redPacket = "red_packet"            // 红包
    case reimbursement = "reimbursement"     // 报销
    case rental = "rental"                   // 租金
    case secondHand = "second_hand"          // 闲置
    case otherIncome = "other_income"        // 其他收入
    
    /// 所属收支类型
    var transactionType: TransactionType {
        switch self {
        case .salary, .bonus, .partTime, .investmentIncome,
             .redPacket, .reimbursement, .rental, .secondHand, .otherIncome:
            return .income
        default:
            return .expense
        }
    }
    
    /// 显示名称
    var displayName: String {
        switch self {
        // 支出
        case .dining: return "餐饮"
        case .shopping: return "购物"
        case .transport: return "交通"
        case .entertainment: return "娱乐"
        case .housing: return "住房"
        case .utilities: return "水电"
        case .communication: return "通讯"
        case .medical: return "医疗"
        case .education: return "教育"
        case .travel: return "旅行"
        case .clothing: return "服饰"
        case .beauty: return "美容"
        case .sports: return "运动"
        case .pets: return "宠物"
        case .gifts: return "礼物"
        case .socializing: return "社交"
        case .snacks: return "零食"
        case .fruits: return "水果"
        case .vegetables: return "蔬菜"
        case .drinks: return "饮品"
        case .digital: return "数码"
        case .household: return "家居"
        case .baby: return "母婴"
        case .elderly: return "长辈"
        case .maintenance: return "维修"
        case .books: return "书籍"
        case .office: return "办公"
        case .insurance: return "保险"
        case .tax: return "税费"
        case .otherExpense: return "其他支出"
        // 收入
        case .salary: return "工资"
        case .bonus: return "奖金"
        case .partTime: return "兼职"
        case .investmentIncome: return "理财收入"
        case .redPacket: return "红包"
        case .reimbursement: return "报销"
        case .rental: return "租金"
        case .secondHand: return "闲置"
        case .otherIncome: return "其他收入"
        }
    }
    
    /// SF Symbols 图标名称
    var iconName: String {
        switch self {
        case .dining: return "fork.knife"
        case .shopping: return "bag.fill"
        case .transport: return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .communication: return "phone.fill"
        case .medical: return "cross.case.fill"
        case .education: return "graduationcap.fill"
        case .travel: return "airplane"
        case .clothing: return "tshirt.fill"
        case .beauty: return "sparkles"
        case .sports: return "figure.run"
        case .pets: return "pawprint.fill"
        case .gifts: return "gift.fill"
        case .socializing: return "person.2.fill"
        case .snacks: return "cup.and.saucer.fill"
        case .fruits: return "leaf.fill"
        case .vegetables: return "carrot.fill"
        case .drinks: return "mug.fill"
        case .digital: return "desktopcomputer"
        case .household: return "sofa.fill"
        case .baby: return "stroller.fill"
        case .elderly: return "heart.fill"
        case .maintenance: return "wrench.fill"
        case .books: return "book.fill"
        case .office: return "briefcase.fill"
        case .insurance: return "shield.fill"
        case .tax: return "doc.text.fill"
        case .otherExpense: return "ellipsis.circle.fill"
        case .salary: return "yensign.circle.fill"
        case .bonus: return "star.circle.fill"
        case .partTime: return "clock.fill"
        case .investmentIncome: return "chart.line.uptrend.xyaxis"
        case .redPacket: return "envelope.fill"
        case .reimbursement: return "arrow.uturn.backward.circle.fill"
        case .rental: return "building.2.fill"
        case .secondHand: return "arrow.3.trianglepath"
        case .otherIncome: return "plus.circle.fill"
        }
    }
    
    /// 分类颜色
    var color: Color {
        switch self {
        case .dining: return .orange
        case .shopping: return .pink
        case .transport: return .blue
        case .entertainment: return .purple
        case .housing: return .brown
        case .utilities: return .yellow
        case .communication: return .cyan
        case .medical: return .red
        case .education: return .indigo
        case .travel: return .teal
        case .clothing: return .mint
        case .beauty: return .pink
        case .sports: return .green
        case .pets: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .gifts: return .red
        case .socializing: return .orange
        case .snacks: return Color(red: 1.0, green: 0.6, blue: 0.4)
        case .fruits: return .green
        case .vegetables: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .drinks: return .cyan
        case .digital: return .gray
        case .household: return .brown
        case .baby: return .pink
        case .elderly: return .red
        case .maintenance: return .gray
        case .books: return .indigo
        case .office: return .blue
        case .insurance: return .teal
        case .tax: return .gray
        case .otherExpense: return .secondary
        case .salary: return .green
        case .bonus: return .yellow
        case .partTime: return .orange
        case .investmentIncome: return .teal
        case .redPacket: return .red
        case .reimbursement: return .blue
        case .rental: return .brown
        case .secondHand: return .mint
        case .otherIncome: return .secondary
        }
    }
    
    /// 支出分类列表
    static var expenseCategories: [TransactionCategory] {
        allCases.filter { $0.transactionType == .expense }
    }
    
    /// 收入分类列表
    static var incomeCategories: [TransactionCategory] {
        allCases.filter { $0.transactionType == .income }
    }
    
    /// 豆花IP语句 — 选择分类时触发
    var douhuaQuote: String {
        switch self {
        case .dining: return "又去吃好吃的啦，记得留钱给豆花买零食哦～"
        case .shopping: return "买了什么好东西呀，给豆花看看～"
        case .transport: return "出门啦？路上注意安全哦～"
        case .entertainment: return "玩得开心吗？记得回来陪豆花～"
        case .pets: return "是给豆花买的吗？太开心啦！"
        case .salary: return "发工资啦！可以给豆花攒更多狗粮钱啦～"
        case .bonus: return "发奖金啦！豆花也想要奖励～"
        case .redPacket: return "收到红包啦，好幸运呀～"
        default: return "记下来咯，豆花帮你管好每一笔～"
        }
    }
}
