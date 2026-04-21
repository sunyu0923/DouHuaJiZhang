import SwiftUI

/// 设计系统 — 颜色、字体、间距、圆角 Token
enum DesignSystem {
    
    // MARK: - Colors
    enum Colors {
        /// 主色调 - 浅粉色
        static let primary = Color(hex: "FFD1DC")
        /// 背景色 - 米白色
        static let background = Color(hex: "FFF8F0")
        /// 卡片白
        static let cardBackground = Color.white
        /// 支出红
        static let expense = Color(hex: "FF6B6B")
        /// 收入绿
        static let income = Color(hex: "51CF66")
        /// 结余黑
        static let balance = Color(hex: "333333")
        /// 次要文字
        static let secondaryText = Color(hex: "999999")
        /// 分隔线
        static let separator = Color(hex: "F0F0F0")
        /// 底部菜单栏背景
        static let tabBarBackground = Color(hex: "2C2C2C")
        /// 未选中图标
        static let tabBarInactive = Color.white.opacity(0.6)
        /// 选中图标
        static let tabBarActive = Color(hex: "FFD1DC")
        /// 按钮禁用
        static let disabled = Color(hex: "CCCCCC")
        /// 渐变粉
        static let gradientPink = LinearGradient(
            colors: [Color(hex: "FFD1DC"), Color(hex: "FFB6C1")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        /// 涨 - 红色
        static let stockUp = Color.red
        /// 跌 - 绿色
        static let stockDown = Color.green
        /// 月经标记 - 红色
        static let menstrualPeriod = Color.red
        /// 排卵期标记 - 黄色
        static let ovulation = Color.yellow
        /// 预测日期标记 - 蓝色
        static let prediction = Color.blue
    }
    
    // MARK: - Typography
    enum Typography {
        /// 大标题
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        /// 标题
        static let title = Font.system(size: 22, weight: .bold, design: .rounded)
        /// 副标题
        static let subtitle = Font.system(size: 18, weight: .semibold, design: .rounded)
        /// 正文
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        /// 正文加粗
        static let bodyBold = Font.system(size: 16, weight: .bold, design: .rounded)
        /// 小字
        static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
        /// 小字加粗
        static let captionBold = Font.system(size: 13, weight: .semibold, design: .rounded)
        /// 金额大字
        static let amountLarge = Font.system(size: 32, weight: .bold, design: .rounded)
        /// 金额中字
        static let amountMedium = Font.system(size: 20, weight: .bold, design: .rounded)
        /// 金额小字
        static let amountSmall = Font.system(size: 14, weight: .semibold, design: .rounded)
        /// 计算器数字
        static let calculator = Font.system(size: 24, weight: .medium, design: .rounded)
        /// 按钮文字
        static let button = Font.system(size: 17, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let full: CGFloat = 999
    }
    
    // MARK: - Shadow
    enum Shadow {
        static let light = ShadowStyle(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifier Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .shadow(
                color: DesignSystem.Shadow.light.color,
                radius: DesignSystem.Shadow.light.radius,
                x: DesignSystem.Shadow.light.x,
                y: DesignSystem.Shadow.light.y
            )
    }
    
    func pageBackground() -> some View {
        self.background(DesignSystem.Colors.background.ignoresSafeArea())
    }
}
