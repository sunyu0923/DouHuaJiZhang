import SwiftUI
import ComposableArchitecture
import Charts

/// 生理记录首页视图 — 拉屎记录 + 月经记录
struct HealthRecordView: View {
    @Bindable var store: StoreOf<HealthRecordFeature>
    
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
                
                // 记录类型切换
                recordTypePicker
                
                // 成员切换区（家庭组可见）
                if !store.familyMembers.isEmpty {
                    memberSwitcher
                }
                
                // 内容区
                switch store.recordType {
                case .poop:
                    poopSection
                case .menstrual:
                    menstrualSection
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .pageBackground()
        .navigationTitle("豆花健康记")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if store.recordType == .poop {
                        store.send(.showAddPoopRecord)
                    } else {
                        store.send(.showAddMenstrualRecord)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Record Type Picker
    
    private var recordTypePicker: some View {
        Picker("记录类型", selection: Binding(
            get: { store.recordType },
            set: { store.send(.switchRecordType($0)) }
        )) {
            Text("拉屎").tag(HealthRecordFeature.RecordType.poop)
            Text("月经").tag(HealthRecordFeature.RecordType.menstrual)
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Member Switcher
    
    private var memberSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(store.familyMembers) { member in
                    Button {
                        store.send(.switchUser(member.userId))
                    } label: {
                        VStack(spacing: DesignSystem.Spacing.xxxs) {
                            Circle()
                                .fill(store.selectedUserId == member.userId ? DesignSystem.Colors.primary : DesignSystem.Colors.separator)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(member.nickname.prefix(1)))
                                        .font(DesignSystem.Typography.caption)
                                )
                            Text(member.nickname)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.balance)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Poop Section
    
    private var poopSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 当日记录
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("今日拉屎记录")
                    .font(DesignSystem.Typography.subtitle)
                    .foregroundStyle(DesignSystem.Colors.balance)
                
                if store.todayPoopCount > 0 {
                    HStack {
                        VStack {
                            Text("\(store.todayPoopCount)")
                                .font(DesignSystem.Typography.amountLarge)
                                .foregroundStyle(DesignSystem.Colors.balance)
                            Text("次")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                        
                        if let lastTime = store.lastPoopTime {
                            VStack {
                                Text(lastTime, style: .time)
                                    .font(DesignSystem.Typography.amountMedium)
                                    .foregroundStyle(DesignSystem.Colors.balance)
                                Text("最近一次")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                        }
                    }
                } else {
                    Text("今日未记录")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .cardStyle()
            
            // 统计区
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // 周期切换
                Picker("统计周期", selection: Binding(
                    get: { store.statsPeriod },
                    set: { store.send(.setStatsPeriod($0)) }
                )) {
                    ForEach(HealthRecordFeature.StatsPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                
                // 柱状图
                if !store.poopRecords.isEmpty {
                    Chart(store.poopRecords) { record in
                        BarMark(
                            x: .value("日期", record.date, unit: .day),
                            y: .value("次数", 1)
                        )
                        .foregroundStyle(Color.brown.opacity(0.7))
                    }
                    .frame(height: 200)
                } else {
                    EmptyStateView("暂无记录", icon: "chart.bar")
                }
            }
            .padding(DesignSystem.Spacing.md)
            .cardStyle()
            
            // 记录列表
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("历史记录")
                    .font(DesignSystem.Typography.subtitle)
                
                ForEach(store.poopRecords) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.date, style: .date)
                                .font(DesignSystem.Typography.body)
                            Text(record.time, style: .time)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                        Spacer()
                        if !record.note.isEmpty {
                            Text(record.note)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                        Button {
                            store.send(.deletePoopRecord(record.id))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(DesignSystem.Colors.expense)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    Divider()
                }
            }
            .padding(DesignSystem.Spacing.md)
            .cardStyle()
        }
    }
    
    // MARK: - Menstrual Section
    
    private var menstrualSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 预测信息
            if let prediction = store.prediction {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("月经预测")
                        .font(DesignSystem.Typography.subtitle)
                    
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        VStack {
                            Text(prediction.nextPeriodDate, style: .date)
                                .font(DesignSystem.Typography.bodyBold)
                            Text("下次月经")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                        
                        VStack {
                            Text(prediction.ovulationDate, style: .date)
                                .font(DesignSystem.Typography.bodyBold)
                            Text("排卵日")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                        
                        VStack {
                            Text("\(prediction.averageCycleLength)天")
                                .font(DesignSystem.Typography.bodyBold)
                            Text("平均周期")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .cardStyle()
            }
            
            // 月经记录列表
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("月经记录")
                    .font(DesignSystem.Typography.subtitle)
                
                ForEach(store.menstrualRecords) { record in
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Circle()
                                    .fill(DesignSystem.Colors.menstrualPeriod)
                                    .frame(width: 8, height: 8)
                                Text(record.startDate, style: .date)
                                    .font(DesignSystem.Typography.body)
                                if let endDate = record.endDate {
                                    Text("~")
                                    Text(endDate, style: .date)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            if let days = record.durationDays {
                                Text("持续\(days)天")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                        }
                        Spacer()
                        Button {
                            store.send(.deleteMenstrualRecord(record.id))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(DesignSystem.Colors.expense)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    Divider()
                }
                
                if store.menstrualRecords.isEmpty {
                    EmptyStateView("暂无月经记录", icon: "calendar")
                }
            }
            .padding(DesignSystem.Spacing.md)
            .cardStyle()
        }
    }
}
