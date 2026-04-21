import SwiftUI

/// 豆花 IP 形象视图 — 展示灰泰迪卡通形象
struct DouhuaIPView: View {
    let size: DouhuaSize
    let mood: DouhuaMood
    var showQuote: Bool = false
    var quote: String = ""
    
    enum DouhuaSize: Equatable {
        case small      // 32pt
        case medium     // 64pt
        case large      // 120pt
        case custom(CGFloat)
        
        var value: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 64
            case .large: return 120
            case .custom(let size): return size
            }
        }
    }
    
    enum DouhuaMood: String, Equatable {
        case happy = "😊"
        case waving = "👋"
        case writing = "✍️"
        case thinking = "🤔"
        case celebrating = "🎉"
        case sad = "😢"
        case sleeping = "😴"
        case eating = "🍖"
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // 豆花形象（使用 emoji 占位，后续替换为实际卡通形象资源）
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.background)
                    .frame(width: size.value, height: size.value)
                
                Text("🐩")
                    .font(.system(size: size.value * 0.5))
                
                // 心情标志
                Text(mood.rawValue)
                    .font(.system(size: size.value * 0.2))
                    .offset(x: size.value * 0.3, y: -size.value * 0.3)
            }
            
            // 语句气泡
            if showQuote && !quote.isEmpty {
                Text(quote)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.balance)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .fill(DesignSystem.Colors.cardBackground)
                            .shadow(
                                color: DesignSystem.Shadow.light.color,
                                radius: DesignSystem.Shadow.light.radius
                            )
                    )
                    .lineLimit(2)
            }
        }
    }
}

/// 圆润按钮
struct RoundedButton: View {
    let title: String
    let style: ButtonStyle
    let isEnabled: Bool
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case danger
        case outline
    }
    
    init(
        _ title: String,
        style: ButtonStyle = .primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.button)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.extraLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.extraLarge)
                        .stroke(borderColor, lineWidth: style == .outline ? 1.5 : 0)
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
    
    private var backgroundColor: Color {
        guard isEnabled else { return DesignSystem.Colors.disabled }
        switch style {
        case .primary: return DesignSystem.Colors.primary
        case .secondary: return DesignSystem.Colors.background
        case .danger: return DesignSystem.Colors.expense
        case .outline: return .clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return DesignSystem.Colors.balance
        case .danger: return .white
        case .outline: return DesignSystem.Colors.primary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outline: return DesignSystem.Colors.primary
        default: return .clear
        }
    }
}

/// 金额显示文本
struct AmountText: View {
    let amount: Decimal
    let type: AmountDisplayType
    let size: AmountSize
    
    enum AmountDisplayType {
        case expense
        case income
        case balance
        case neutral
    }
    
    enum AmountSize {
        case small
        case medium
        case large
    }
    
    init(_ amount: Decimal, type: AmountDisplayType = .neutral, size: AmountSize = .medium) {
        self.amount = amount
        self.type = type
        self.size = size
    }
    
    var body: some View {
        Text(formattedAmount)
            .font(font)
            .foregroundStyle(color)
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "¥0.00"
    }
    
    private var font: Font {
        switch size {
        case .small: return DesignSystem.Typography.amountSmall
        case .medium: return DesignSystem.Typography.amountMedium
        case .large: return DesignSystem.Typography.amountLarge
        }
    }
    
    private var color: Color {
        switch type {
        case .expense: return DesignSystem.Colors.expense
        case .income: return DesignSystem.Colors.income
        case .balance: return DesignSystem.Colors.balance
        case .neutral: return DesignSystem.Colors.balance
        }
    }
}

/// 收支概览卡片
struct SummaryCard: View {
    let title: String
    let amount: Decimal
    let type: AmountText.AmountDisplayType
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.white.opacity(0.8))
            AmountText(amount, type: .neutral, size: .medium)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}

/// 空状态视图
struct EmptyStateView: View {
    let message: String
    let iconName: String
    
    init(_ message: String, icon: String = "tray") {
        self.message = message
        self.iconName = icon
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.secondaryText)
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
