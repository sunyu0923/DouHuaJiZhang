import SwiftUI
import ComposableArchitecture

/// 理财首页视图 — 行情 + 投资入口
struct FinanceView: View {
    @Bindable var store: StoreOf<FinanceFeature>
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                // 豆花 IP
                DouhuaIPView(
                    size: .medium,
                    mood: .thinking,
                    showQuote: true,
                    quote: store.douhuaQuote
                )
                
                // 分类切换
                categoryPicker
                
                // 行情列表
                marketQuotesList
                
                // 我的投资入口
                investmentSummary
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .pageBackground()
        .navigationTitle("理财行情")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.toggleInvestmentList)
                } label: {
                    Text("我的投资")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    // MARK: - Category Picker
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                categoryButton(nil, "全部")
                ForEach(MarketCategory.allCases, id: \.self) { category in
                    categoryButton(category, category.displayName)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xxs)
        }
    }
    
    private func categoryButton(_ category: MarketCategory?, _ title: String) -> some View {
        Button {
            store.send(.selectMarketCategory(category))
        } label: {
            Text(title)
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(
                    store.selectedMarketCategory == category ? .white : DesignSystem.Colors.balance
                )
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xxs)
                .background(
                    store.selectedMarketCategory == category
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.cardBackground
                )
                .clipShape(Capsule())
        }
    }
    
    // MARK: - Market Quotes
    
    private var marketQuotesList: some View {
        VStack(spacing: 0) {
            ForEach(store.marketQuotes) { quote in
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        Text(quote.name)
                            .font(DesignSystem.Typography.bodyBold)
                            .foregroundStyle(DesignSystem.Colors.balance)
                        Text(quote.category.displayName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxxs) {
                        AmountText(quote.price, size: .small)
                        
                        HStack(spacing: DesignSystem.Spacing.xxxs) {
                            Text(quote.isUp ? "+" : "")
                            Text("\(NSDecimalNumber(decimal: quote.change).doubleValue, specifier: "%.2f")")
                            Text("(\(quote.changePercent * 100, specifier: "%.2f")%)")
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(quote.isUp ? DesignSystem.Colors.stockUp : quote.isDown ? DesignSystem.Colors.stockDown : DesignSystem.Colors.secondaryText)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
                
                if quote.id != store.marketQuotes.last?.id {
                    Divider()
                }
            }
            
            if store.marketQuotes.isEmpty && !store.isLoading {
                EmptyStateView("暂无行情数据", icon: "chart.line.uptrend.xyaxis")
            }
            
            if store.isLoading {
                ProgressView()
                    .padding()
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
    
    // MARK: - Investment Summary
    
    private var investmentSummary: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("我的投资")
                    .font(DesignSystem.Typography.subtitle)
                Spacer()
                Button {
                    store.send(.showAddInvestment)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
            
            HStack {
                VStack {
                    Text("总投入")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    AmountText(store.totalInvestment, size: .medium)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("总收益")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    AmountText(
                        store.totalProfit,
                        type: store.totalProfit >= 0 ? .income : .expense,
                        size: .medium
                    )
                }
                .frame(maxWidth: .infinity)
            }
            
            // 投资列表
            ForEach(store.investments, id: \.id) { investment in
                Button {
                    store.send(.showInvestmentDetail(investment))
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(investment.name)
                                .font(DesignSystem.Typography.bodyBold)
                                .foregroundStyle(DesignSystem.Colors.balance)
                            Text(investment.type.displayName)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            AmountText(investment.currentValue, size: .small)
                            Text("\(investment.profitRate * 100, specifier: "%.2f")%")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(investment.profit >= 0 ? DesignSystem.Colors.income : DesignSystem.Colors.expense)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
}
