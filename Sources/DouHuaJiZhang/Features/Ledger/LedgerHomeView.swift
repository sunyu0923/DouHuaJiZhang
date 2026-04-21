import SwiftUI
import ComposableArchitecture
import Charts

/// 账本首页视图
struct LedgerHomeView: View {
    @Bindable var store: StoreOf<LedgerFeature>
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                // 顶部 IP 区域
                headerSection
                
                // 收支概览
                summarySection
                
                // 日历视图
                calendarSection
                
                // 统计图表
                if let statistics = store.statistics {
                    statisticsSection(statistics)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .pageBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                // 账本图标 + 名称
                Button {
                    store.send(.showLedgerSwitch)
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "book.fill")
                        Text(store.currentLedger?.name ?? "我的账本")
                            .font(DesignSystem.Typography.bodyBold)
                    }
                    .foregroundStyle(DesignSystem.Colors.balance)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                // 记账按钮
                Button {
                    store.send(.showAddTransaction)
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .sheet(item: $store.scope(state: \.addTransaction, action: \.addTransaction)) { txStore in
            NavigationStack {
                TransactionView(store: txStore)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            DouhuaIPView(
                size: .medium,
                mood: .happy,
                showQuote: true,
                quote: DouhuaQuoteManager.greetingQuote()
            )
            Spacer()
        }
        .padding(.top, DesignSystem.Spacing.xs)
    }
    
    // MARK: - Summary
    
    private var summarySection: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            SummaryCard(
                title: "支出",
                amount: store.totalExpense,
                type: .expense,
                backgroundColor: DesignSystem.Colors.expense
            )
            SummaryCard(
                title: "收入",
                amount: store.totalIncome,
                type: .income,
                backgroundColor: DesignSystem.Colors.income
            )
            SummaryCard(
                title: "结余",
                amount: store.balance,
                type: .balance,
                backgroundColor: Color.gray.opacity(0.7)
            )
        }
    }
    
    // MARK: - Calendar
    
    private var calendarSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // 月份切换
            HStack {
                Button {
                    store.send(.previousMonth)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Text("\(String(store.currentYear))年\(store.currentMonth)月")
                    .font(DesignSystem.Typography.subtitle)
                    .foregroundStyle(DesignSystem.Colors.balance)
                
                Spacer()
                
                Button {
                    store.send(.nextMonth)
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
            }
            
            // 星期标题
            let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: DesignSystem.Spacing.xxs) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                }
                
                // 日期格子
                ForEach(store.calendarData) { dayData in
                    VStack(spacing: 1) {
                        Text(dayString(from: dayData.date))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.balance)
                        
                        if dayData.expense > 0 {
                            Text("-\(shortAmount(dayData.expense))")
                                .font(.system(size: 8, design: .rounded))
                                .foregroundStyle(DesignSystem.Colors.expense)
                        }
                        if dayData.income > 0 {
                            Text("+\(shortAmount(dayData.income))")
                                .font(.system(size: 8, design: .rounded))
                                .foregroundStyle(DesignSystem.Colors.income)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .onTapGesture {
                        store.send(.selectDate(dayData.date))
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Statistics
    
    private func statisticsSection(_ data: StatisticsData) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 支出分类饼图
            if !data.categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("支出分类统计")
                        .font(DesignSystem.Typography.subtitle)
                        .foregroundStyle(DesignSystem.Colors.balance)
                    
                    Chart(data.categoryBreakdown) { item in
                        SectorMark(
                            angle: .value("金额", NSDecimalNumber(decimal: item.amount).doubleValue),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.category.color)
                        .annotation(position: .overlay) {
                            if item.percentage > 0.05 {
                                Text(item.category.displayName)
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 200)
                }
                .padding(DesignSystem.Spacing.md)
                .cardStyle()
            }
            
            // 日趋势折线图
            if !data.dailyTrend.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("日收支趋势")
                        .font(DesignSystem.Typography.subtitle)
                        .foregroundStyle(DesignSystem.Colors.balance)
                    
                    Chart(data.dailyTrend) { item in
                        LineMark(
                            x: .value("日期", item.date),
                            y: .value("支出", NSDecimalNumber(decimal: item.expense).doubleValue)
                        )
                        .foregroundStyle(DesignSystem.Colors.expense)
                        
                        LineMark(
                            x: .value("日期", item.date),
                            y: .value("收入", NSDecimalNumber(decimal: item.income).doubleValue)
                        )
                        .foregroundStyle(DesignSystem.Colors.income)
                    }
                    .frame(height: 200)
                }
                .padding(DesignSystem.Spacing.md)
                .cardStyle()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func dayString(from dateString: String) -> String {
        let parts = dateString.split(separator: "-")
        return parts.count >= 3 ? String(parts[2]) : dateString
    }
    
    private func shortAmount(_ amount: Decimal) -> String {
        let value = NSDecimalNumber(decimal: amount).doubleValue
        if value >= 10000 {
            return String(format: "%.1fw", value / 10000)
        } else if value >= 1000 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
}
