import SwiftUI
import ComposableArchitecture

/// 攒钱计划首页视图
struct SavingsView: View {
    @Bindable var store: StoreOf<SavingsFeature>
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                // 豆花 IP
                DouhuaIPView(
                    size: .medium,
                    mood: .happy,
                    showQuote: true,
                    quote: store.douhuaQuote
                )
                .padding(.top, DesignSystem.Spacing.sm)
                
                // 目标设置区
                goalSettingSection
                
                // 目标统计区
                if let progress = store.progress {
                    progressSection(progress)
                }
                
                // 月度明细区
                monthlyDetailSection
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .pageBackground()
        .navigationTitle("攒钱计划")
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Goal Setting
    
    private var goalSettingSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("月度攒钱目标")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.balance)
                Spacer()
                HStack {
                    Text("¥")
                        .font(DesignSystem.Typography.bodyBold)
                    TextField("0", text: Binding(
                        get: { store.monthlyGoalInput },
                        set: { store.send(.setMonthlyGoal($0)) }
                    ))
                    .keyboardType(.decimalPad)
                    .font(DesignSystem.Typography.amountMedium)
                    .frame(width: 120)
                    .multilineTextAlignment(.trailing)
                }
            }
            
            HStack {
                Text("年度攒钱目标")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.balance)
                Spacer()
                HStack {
                    Text("¥")
                        .font(DesignSystem.Typography.bodyBold)
                    TextField("0", text: Binding(
                        get: { store.yearlyGoalInput },
                        set: { store.send(.setYearlyGoal($0)) }
                    ))
                    .keyboardType(.decimalPad)
                    .font(DesignSystem.Typography.amountMedium)
                    .frame(width: 120)
                    .multilineTextAlignment(.trailing)
                }
            }
            
            RoundedButton("保存目标") {
                store.send(.saveGoal)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Progress
    
    private func progressSection(_ progress: SavingsProgress) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // 进度条
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                HStack {
                    Text("本月攒钱进度")
                        .font(DesignSystem.Typography.bodyBold)
                    Spacer()
                    Text(progress.status.displayName)
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(progress.status == .exceeded ? DesignSystem.Colors.income : DesignSystem.Colors.expense)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignSystem.Colors.separator)
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignSystem.Colors.primary)
                            .frame(
                                width: min(geometry.size.width * CGFloat(progress.progressRatio), geometry.size.width),
                                height: 12
                            )
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("已攒: ")
                        .font(DesignSystem.Typography.caption)
                    AmountText(progress.actualSaved, size: .small)
                    Text(" / 目标: ")
                        .font(DesignSystem.Typography.caption)
                    AmountText(progress.targetAmount, size: .small)
                }
            }
            
            Divider()
            
            // 累计数据
            HStack {
                VStack {
                    Text("累计攒钱")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    AmountText(progress.actualSaved, type: .income, size: .medium)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("差额")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    AmountText(
                        progress.difference,
                        type: progress.difference >= 0 ? .income : .expense,
                        size: .medium
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Monthly Detail
    
    private var monthlyDetailSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("月度明细")
                .font(DesignSystem.Typography.subtitle)
                .foregroundStyle(DesignSystem.Colors.balance)
            
            ForEach(store.plans, id: \.id) { plan in
                HStack {
                    Text("\(plan.year)年\(plan.month)月")
                        .font(DesignSystem.Typography.body)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("目标: ¥\(plan.monthlyGoal)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                    if plan.canModify {
                        Button("修改") {
                            store.send(.updateGoal(plan))
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.xxs)
                Divider()
            }
            
            if store.plans.isEmpty {
                EmptyStateView("还没有攒钱计划", icon: "banknote")
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
}
