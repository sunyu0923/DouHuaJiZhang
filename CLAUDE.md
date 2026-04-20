# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

本项目是一个 iOS 端的项目，为记账软件。

---

## 项目概述

**豆花记账 (DouHuaJiZhang)** — 多用户协同记账 iOS 应用，以灰泰迪"豆花"为核心 IP，支持家庭/团队共享账本，目标承载 8,000–10,000 人同时在线。

**核心模块（8大模块）**:
1. **注册登录** — 手机号+密码/验证码、微信登录
2. **账本首页** — 收支概览、日历视图、统计图表
3. **家庭组共享记账** — 多成员协同、权限分级
4. **记账（交易）** — 计算器输入、30个支出+9个收入分类
5. **攒钱计划** — 月度/年度目标、进度追踪
6. **理财管理** — 实时行情（A股/美股/金银/基金/外汇）、个人投资管理
7. **生理健康记录（豆花健康记）** — 拉屎记录+月经周期追踪
8. **个人设置** — 勋章系统、主题切换、数据备份、通知管理

---

## 技术栈

### iOS 客户端
- **语言**: Swift 5.9+
- **最低部署版本**: iOS 17.0
- **UI 框架**: SwiftUI（主体）+ UIKit（复杂组件）
- **架构模式**: TCA (The Composable Architecture)
- **本地持久化**: SwiftData
- **网络层**: URLSession + async/await
- **实时通信**: WebSocket（URLSessionWebSocketTask）
- **依赖管理**: Swift Package Manager (SPM)
- **图表**: Swift Charts

### 后端服务（配套开发）
- **运行时**: Go 1.22+
- **API 协议**: REST + WebSocket
- **数据库**: PostgreSQL + Redis
- **消息队列**: Redis Streams
- **对象存储**: OSS / S3
- **部署**: Kubernetes + HPA

---

## 项目结构

```
DouHuaJiZhang/
├── Package.swift
├── Sources/
│   └── DouHuaJiZhang/
│       ├── App/                    # App 入口、根 Store
│       │   ├── DouHuaJiZhangApp.swift
│       │   └── AppReducer.swift
│       │
│       ├── Features/               # 功能模块（每个模块独立 Reducer）
│       │   ├── Auth/               # 登录/注册/OAuth
│       │   ├── Ledger/             # 账本管理（首页/切换/家庭组）
│       │   ├── Transaction/        # 记账（新增/编辑/删除/计算器）
│       │   ├── Statistics/         # 统计图表（饼图/折线图）
│       │   ├── Savings/            # 攒钱计划
│       │   ├── Finance/            # 理财管理（行情/投资）
│       │   ├── HealthRecord/       # 生理记录（拉屎/月经）
│       │   ├── Settings/           # 个人设置/勋章/主题
│       │   └── Sync/               # 协同同步（WebSocket + 冲突解决）
│       │
│       ├── Core/
│       │   ├── Models/             # Swift 值类型 Domain Models
│       │   ├── Network/            # APIClient（依赖注入）
│       │   ├── WebSocket/          # 实时同步客户端
│       │   ├── Persistence/        # SwiftData Store
│       │   └── Keychain/           # Token 安全存储
│       │
│       └── UI/
│           ├── DesignSystem/       # 颜色/字体/间距 Token
│           ├── Components/         # 可复用 SwiftUI 组件
│           └── DouhuaIP/           # 豆花 IP 形象和语句系统
│
└── Tests/
    └── DouHuaJiZhangTests/
```

---

## 核心数据模型

```swift
// 用户
struct User: Identifiable, Codable { id, phone, nickname, avatarURL, createdAt }

// 账本
struct Ledger: Identifiable, Codable { id, name, type(personal/family), currency(ISO4217), members, vectorClock }

// 账单
struct Transaction: Identifiable, Codable { id, ledgerId, creatorId, amount(Decimal), category, note, attachments, date, createdAt, updatedAt }

// 分类 — 支出30个 + 收入9个
enum TransactionCategory: String, Codable, CaseIterable { ... }

// 攒钱计划
struct SavingsPlan: Identifiable, Codable { id, monthlyGoal(Decimal), yearlyGoal(Decimal), month, year }

// 投资产品
struct Investment: Identifiable, Codable { id, name, type, amount(Decimal), currentValue, maturityDate? }

// 拉屎记录
struct PoopRecord: Identifiable, Codable { id, userId, date, time, note }

// 月经记录
struct MenstrualRecord: Identifiable, Codable { id, userId, startDate, endDate, cycleLength }

// 勋章
struct Badge: Identifiable, Codable { id, type, name, isUnlocked, unlockedAt? }

// 协同操作
struct SyncOperation: Codable { operationId, ledgerId, userId, type, payload, vectorClock, timestamp }
```

---

## 开发规范

### iOS 代码规范
- 所有网络请求通过 `APIClient` 依赖注入，禁止在 View 层直接调用
- Reducer 中副作用统一通过 `Effect` 返回，禁止在 Reducer 外部修改 State
- 金额计算全部使用 `Decimal`，禁止 `Float`/`Double`
- 敏感数据（token、用户ID）只存 Keychain，不存 UserDefaults
- 每个 Feature 模块包含：`*Feature.swift`（Reducer）、`*View.swift`（视图）

### UI 规范
- 整体风格："可爱治愈风"
- 主色调：浅粉色 (#FFD1DC)、米白色 (#FFF8F0)
- 按钮/图标：圆润设计，无尖锐边角
- 字体：圆润无衬线字体
- 豆花 IP：每个页面都有豆花卡通形象 + 场景化拟人语句

### 后端规范
- 所有写操作幂等（客户端携带 `operationId`）
- 金额类型用 `NUMERIC(15,2)`
- 账本操作必须鉴权

---

## 性能基准目标

| 指标 | 目标 |
|------|------|
| API P99 响应时间 | < 200ms |
| WebSocket 消息延迟 | < 100ms |
| iOS 冷启动时间 | < 1.5s |
| 账单列表首屏渲染 | < 0.5s |
| 并发 WebSocket 连接 | 10,000 |

---

## 构建 & 运行

```bash
# 用 Xcode 打开项目
open Package.swift

# 或直接用 xcodebuild
xcodebuild -scheme DouHuaJiZhang -destination 'platform=iOS Simulator,name=iPhone 16'
```
