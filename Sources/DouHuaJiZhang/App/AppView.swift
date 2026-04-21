import SwiftUI
import ComposableArchitecture

/// App 根视图 — TabView + Auth 全屏覆盖
struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            // Tab 1: 账本首页
            NavigationStack {
                LedgerHomeView(store: store.scope(state: \.ledger, action: \.ledger))
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                store.send(.showSettings)
                            } label: {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(DesignSystem.Colors.primary)
                            }
                        }
                    }
            }
            .tabItem {
                Label(AppFeature.Tab.ledger.title, systemImage: AppFeature.Tab.ledger.iconName)
            }
            .tag(AppFeature.Tab.ledger)
            
            // Tab 2: 攒钱计划
            NavigationStack {
                SavingsView(store: store.scope(state: \.savings, action: \.savings))
            }
            .tabItem {
                Label(AppFeature.Tab.savings.title, systemImage: AppFeature.Tab.savings.iconName)
            }
            .tag(AppFeature.Tab.savings)
            
            // Tab 3: 理财管理
            NavigationStack {
                FinanceView(store: store.scope(state: \.finance, action: \.finance))
            }
            .tabItem {
                Label(AppFeature.Tab.finance.title, systemImage: AppFeature.Tab.finance.iconName)
            }
            .tag(AppFeature.Tab.finance)
            
            // Tab 4: 豆花健康记
            NavigationStack {
                HealthRecordView(store: store.scope(state: \.health, action: \.health))
            }
            .tabItem {
                Label(AppFeature.Tab.health.title, systemImage: AppFeature.Tab.health.iconName)
            }
            .tag(AppFeature.Tab.health)
        }
        .tint(DesignSystem.Colors.primary)
        .fullScreenCover(item: $store.scope(state: \.auth, action: \.auth)) { authStore in
            AuthView(store: authStore)
        }
        .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
            NavigationStack {
                SettingsView(store: settingsStore)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}
