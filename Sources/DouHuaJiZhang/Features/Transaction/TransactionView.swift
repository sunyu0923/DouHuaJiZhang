import SwiftUI
import ComposableArchitecture

/// 记账页面视图 — 收支选择 + 分类网格 + 计算器
struct TransactionView: View {
    @Bindable var store: StoreOf<TransactionFeature>
    
    let columns5 = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    
    var body: some View {
        VStack(spacing: 0) {
            // 豆花形象
            DouhuaIPView(
                size: .medium,
                mood: .writing,
                showQuote: true,
                quote: store.douhuaQuote
            )
            .padding(.top, DesignSystem.Spacing.sm)
            
            // 收支选择
            transactionTypePicker
            
            // 分类选择
            ScrollView {
                categoryGrid
            }
            .frame(maxHeight: 200)
            
            Divider()
            
            // 备注输入
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                TextField("添加备注", text: $store.note)
                    .font(DesignSystem.Typography.body)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            
            // 计算器
            calculatorSection
        }
        .pageBackground()
        .navigationTitle("记账")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    store.send(.dismiss)
                }
            }
        }
    }
    
    // MARK: - Transaction Type Picker
    
    private var transactionTypePicker: some View {
        HStack(spacing: 0) {
            transactionTypeButton(.expense, "支出")
            transactionTypeButton(.income, "收入")
        }
        .padding(.horizontal, DesignSystem.Spacing.xxl)
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    private func transactionTypeButton(_ type: TransactionType, _ title: String) -> some View {
        Button {
            store.send(.setTransactionType(type))
        } label: {
            Text(title)
                .font(DesignSystem.Typography.bodyBold)
                .foregroundStyle(store.transactionType == type ? .white : DesignSystem.Colors.balance)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    store.transactionType == type
                    ? (type == .expense ? DesignSystem.Colors.expense : DesignSystem.Colors.income)
                    : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        }
    }
    
    // MARK: - Category Grid
    
    private var categoryGrid: some View {
        LazyVGrid(columns: columns5, spacing: DesignSystem.Spacing.sm) {
            ForEach(store.currentCategories, id: \.self) { category in
                categoryItem(category)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private func categoryItem(_ category: TransactionCategory) -> some View {
        let isSelected = store.selectedCategory == category
        return Button {
            store.send(.selectCategory(category))
        } label: {
            VStack(spacing: DesignSystem.Spacing.xxs) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : category.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : category.color)
                }
                
                Text(category.displayName)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(DesignSystem.Colors.balance)
                    .lineLimit(1)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
    
    // MARK: - Calculator
    
    private var calculatorSection: some View {
        VStack(spacing: 0) {
            // Display
            HStack {
                // 日期选择
                DatePicker(
                    "",
                    selection: $store.selectedDate.sending(\.setDate),
                    displayedComponents: .date
                )
                .labelsHidden()
                .scaleEffect(0.85)
                
                Spacer()
                
                Text(store.calculatorDisplay)
                    .font(DesignSystem.Typography.amountLarge)
                    .foregroundStyle(DesignSystem.Colors.balance)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            
            // Keys
            let keys: [[TransactionFeature.CalculatorKey]] = [
                [.seven, .eight, .nine, .backspace],
                [.four, .five, .six, .plus],
                [.one, .two, .three, .minus],
                [.dot, .zero, .clear, .equals],
            ]
            
            VStack(spacing: 1) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(row, id: \.self) { key in
                            calculatorButton(key)
                        }
                    }
                }
            }
            .background(DesignSystem.Colors.separator)
            
            // 完成按钮
            RoundedButton("完成", isEnabled: store.canSubmit) {
                store.send(.submit)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .background(DesignSystem.Colors.cardBackground)
    }
    
    private func calculatorButton(_ key: TransactionFeature.CalculatorKey) -> some View {
        Button {
            store.send(.calculatorInput(key))
        } label: {
            Text(key.rawValue)
                .font(DesignSystem.Typography.calculator)
                .foregroundStyle(keyColor(key))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(keyBackground(key))
        }
    }
    
    private func keyColor(_ key: TransactionFeature.CalculatorKey) -> Color {
        switch key {
        case .plus, .minus, .multiply, .divide, .clear:
            return DesignSystem.Colors.primary
        case .equals:
            return .white
        case .backspace:
            return DesignSystem.Colors.secondaryText
        default:
            return DesignSystem.Colors.balance
        }
    }
    
    private func keyBackground(_ key: TransactionFeature.CalculatorKey) -> Color {
        switch key {
        case .equals:
            return DesignSystem.Colors.primary
        default:
            return DesignSystem.Colors.cardBackground
        }
    }
}
