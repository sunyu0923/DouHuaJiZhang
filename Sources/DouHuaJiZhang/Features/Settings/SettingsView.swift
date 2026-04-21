import SwiftUI
import ComposableArchitecture

/// 设置页视图
struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    
    var body: some View {
        List {
            // 个人信息区
            Section {
                HStack(spacing: DesignSystem.Spacing.md) {
                    // 头像
                    Button {
                        store.send(.updateAvatar)
                    } label: {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(DesignSystem.Colors.primary)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        Text(store.user?.nickname ?? "未登录")
                            .font(DesignSystem.Typography.subtitle)
                        if let user = store.user {
                            Text("ID: \(user.id.uuidString.prefix(8))")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
            
            // 记账数据
            Section("记账数据") {
                HStack {
                    statsItem("连续记账", "\(store.consecutiveDays)天")
                    Divider()
                    statsItem("总记账天数", "\(store.totalDays)天")
                    Divider()
                    statsItem("总笔数", "\(store.totalTransactions)笔")
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
            
            // 功能
            Section("功能") {
                Button {
                    store.send(.inviteFriend)
                } label: {
                    Label("邀请好友", systemImage: "person.badge.plus")
                }
                
                Button {
                    store.send(.showBadges)
                } label: {
                    Label("我的勋章", systemImage: "medal.fill")
                }
                
                NavigationLink {
                    Text("切换宠物形象") // TODO: Pet customization
                } label: {
                    Label("切换宠物形象", systemImage: "pawprint.fill")
                }
            }
            
            // 设置
            Section("设置") {
                Toggle(isOn: $store.isReminderEnabled) {
                    Label("记账提醒", systemImage: "bell.fill")
                }
                
                if store.isReminderEnabled {
                    DatePicker(
                        "提醒时间",
                        selection: $store.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Toggle(isOn: $store.isAmountHidden) {
                    Label("隐藏金额", systemImage: "eye.slash.fill")
                }
                
                Toggle(isOn: $store.isAppLockEnabled) {
                    Label("应用锁", systemImage: "lock.fill")
                }
                
                Button {
                    store.send(.clearCache)
                } label: {
                    Label("清理缓存", systemImage: "trash.fill")
                }
            }
            
            // 其他
            Section {
                NavigationLink {
                    Text("帮助与反馈") // TODO
                } label: {
                    Label("帮助与反馈", systemImage: "questionmark.circle.fill")
                }
                
                NavigationLink {
                    Text("关于我们") // TODO
                } label: {
                    Label("关于我们", systemImage: "info.circle.fill")
                }
            }
            
            // 退出登录
            Section {
                Button(role: .destructive) {
                    store.send(.logout)
                } label: {
                    HStack {
                        Spacer()
                        Text("退出登录")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    store.send(.dismiss)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    private func statsItem(_ title: String, _ value: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.xxxs) {
            Text(value)
                .font(DesignSystem.Typography.bodyBold)
                .foregroundStyle(DesignSystem.Colors.balance)
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
