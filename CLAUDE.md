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
├── run_tests.sh                    # 测试运行脚本 (macOS/Linux)
├── run_tests.ps1                   # 测试运行脚本 (Windows)
├── Sources/
│   └── DouHuaJiZhang/
│       ├── App/                    # App 入口、根 Store
│       │   ├── DouHuaJiZhangApp.swift
│       │   ├── AppFeature.swift    # 根 Reducer（Tab 路由 + 认证）
│       │   └── ContentView.swift
│       │
│       ├── Features/               # 功能模块（每个模块 Reducer + View）
│       │   ├── Auth/               # 登录/注册
│       │   │   ├── AuthFeature.swift
│       │   │   └── AuthView.swift
│       │   ├── Ledger/             # 账本管理（首页/切换）
│       │   │   ├── LedgerFeature.swift
│       │   │   └── LedgerView.swift
│       │   ├── Transaction/        # 记账（计算器输入 + 分类选择）
│       │   │   ├── TransactionFeature.swift
│       │   │   └── TransactionView.swift
│       │   ├── Savings/            # 攒钱计划
│       │   │   ├── SavingsFeature.swift
│       │   │   └── SavingsView.swift
│       │   ├── Finance/            # 理财管理（行情 + 投资）
│       │   │   ├── FinanceFeature.swift
│       │   │   └── FinanceView.swift
│       │   ├── HealthRecord/       # 生理记录（拉屎 + 月经）
│       │   │   ├── HealthRecordFeature.swift
│       │   │   └── HealthRecordView.swift
│       │   └── Settings/           # 个人设置/勋章
│       │       ├── SettingsFeature.swift
│       │       └── SettingsView.swift
│       │
│       ├── Core/
│       │   ├── Models/             # Swift 值类型 Domain Models
│       │   │   ├── User.swift
│       │   │   ├── Ledger.swift        # Ledger + VectorClock + LedgerMember
│       │   │   ├── Transaction.swift
│       │   │   ├── TransactionCategory.swift  # 30 支出 + 9 收入分类
│       │   │   ├── SavingsPlan.swift    # SavingsPlan + SavingsProgress
│       │   │   ├── Investment.swift     # Investment + MarketQuote
│       │   │   ├── HealthRecord.swift   # PoopRecord + MenstrualRecord
│       │   │   ├── Badge.swift
│       │   │   └── SyncOperation.swift
│       │   ├── Network/            # APIClient（@DependencyClient）
│       │   │   └── APIClient.swift     # APIError + DTOs + 40+ endpoints
│       │   ├── WebSocket/          # 实时同步客户端
│       │   │   └── WebSocketClient.swift
│       │   └── Keychain/           # Token 安全存储
│       │       └── KeychainClient.swift  # @DependencyClient
│       │
│       └── UI/
│           ├── DesignSystem/       # 颜色/字体/间距 Token
│           │   └── DesignSystem.swift
│           ├── Components/         # 可复用 SwiftUI 组件
│           │   └── Components.swift
│           └── DouhuaIP/           # 豆花 IP 形象和语句系统
│               └── DouhuaQuoteManager.swift  # 37 场景 × 多条语句
│
├── Tests/
│   └── DouHuaJiZhangTests/
│       ├── Core/
│       │   ├── Models/             # 模型单元测试
│       │   │   ├── UserTests.swift
│       │   │   ├── TransactionModelTests.swift
│       │   │   ├── TransactionCategoryTests.swift
│       │   │   ├── LedgerModelTests.swift      # 含 VectorClock 测试
│       │   │   ├── SavingsPlanTests.swift       # 含 SavingsProgress 测试
│       │   │   ├── InvestmentModelTests.swift   # 含 profit/profitRate 测试
│       │   │   ├── HealthRecordModelTests.swift
│       │   │   ├── BadgeTests.swift
│       │   │   └── SyncOperationModelTests.swift
│       │   └── Network/
│       │       └── APITypesTests.swift         # APIError + DTO 测试
│       ├── Features/               # Feature Reducer 测试（TCA TestStore）
│       │   ├── AppFeatureTests.swift
│       │   ├── AuthFeatureTests.swift       # 登录/注册/锁定/OTP
│       │   ├── LedgerFeatureTests.swift     # 月份导航/数据加载
│       │   ├── TransactionFeatureTests.swift # 计算器全按键测试
│       │   ├── SavingsFeatureTests.swift    # 目标保存/修改
│       │   ├── FinanceFeatureTests.swift    # 行情/投资增删
│       │   ├── HealthRecordFeatureTests.swift # 拉屎/月经记录
│       │   └── SettingsFeatureTests.swift   # 个人信息/勋章/登出
│       └── UI/
│           └── DouhuaQuoteManagerTests.swift # IP 语句覆盖测试
│
└── server/                         # Go 后端服务
    ├── go.mod
    ├── go.sum
    ├── cmd/
    │   └── api/
    │       └── main.go             # 应用入口（路由注册、优雅关停）
    ├── internal/
    │   ├── config/
    │   │   └── config.go           # 环境变量配置加载
    │   ├── model/
    │   │   ├── model.go            # Domain Models（User, Ledger, Transaction 等）
    │   │   └── dto.go              # 请求/响应 DTO + APIResponse
    │   ├── middleware/
    │   │   ├── auth.go             # JWT 认证中间件 + Claims
    │   │   └── middleware.go       # CORS、RequestID、RateLimiter
    │   ├── service/
    │   │   ├── services.go         # 业务逻辑（User/Ledger/Transaction/Savings/Investment/Health）
    │   │   ├── auth_service.go     # 认证服务（登录/注册/验证码/刷新Token）
    │   │   ├── ws_hub.go           # WebSocket Hub（广播/注册/注销）
    │   │   └── generate_code_test.go # 未导出函数 generateCode 的包内测试
    │   ├── handler/
    │   │   ├── handlers.go         # HTTP 路由处理器（8 组路由注册）
    │   │   └── websocket.go        # WebSocket 升级 + 读写 Pump
    │   └── repository/
    │       ├── user_repo.go
    │       ├── ledger_repo.go
    │       ├── transaction_repo.go
    │       ├── savings_repo.go
    │       ├── investment_repo.go
    │       ├── health_repo.go
    │       └── badge_repo.go
    └── tests/                      # 后端单元测试（独立于 internal）
        ├── model/
        │   ├── model_test.go       # VectorClock、JSON 序列化、模型字段
        │   └── dto_test.go         # DTO 验证、APIResponse、分页
        ├── middleware/
        │   └── middleware_test.go   # JWT 认证、CORS、RequestID
        ├── service/
        │   └── service_test.go     # 业务逻辑验证、月经预测算法、WSHub
        ├── handler/
        │   └── handler_test.go     # HTTP 端点测试（请求绑定、鉴权检查）
        └── config/
            └── config_test.go      # 配置加载、环境变量覆盖
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

### iOS 客户端

```bash
# 用 Xcode 打开项目
open Package.swift

# 或直接用 xcodebuild
xcodebuild -scheme DouHuaJiZhang -destination 'platform=iOS Simulator,name=iPhone 16'

# 运行 Swift 单元测试
swift test
# 或
xcodebuild test -scheme DouHuaJiZhang -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Go 后端

```bash
# 进入后端目录
cd server

# 运行所有 Go 测试
go test ./... -v -count=1

# 仅运行 tests/ 目录下的测试（独立于 internal）
go test ./tests/... -v -count=1

# 生成测试覆盖率报告
go test ./... -coverprofile=coverage.out -count=1
go tool cover -html=coverage.out -o coverage.html

# 启动后端服务
go run ./cmd/api
```

### 一键测试脚本

```bash
# macOS / Linux
./run_tests.sh              # 运行全部测试（Swift + Go）
./run_tests.sh go           # 仅 Go 测试
./run_tests.sh go cover     # Go 测试 + 覆盖率
./run_tests.sh go tests     # 仅 tests/ 目录
./run_tests.sh swift        # 仅 Swift 测试

# Windows PowerShell
.\run_tests.ps1              # 运行全部测试
.\run_tests.ps1 go           # 仅 Go 测试
.\run_tests.ps1 go -GoOption cover  # Go + 覆盖率
```

---

## 测试规范

### 测试组织

#### iOS 测试
- **模型测试** (`Tests/.../Core/Models/`): 测试 init 默认值、computed properties、Codable 序列化、Equatable
- **Feature 测试** (`Tests/.../Features/`): 使用 TCA `TestStore` 进行 Reducer 状态机测试
- **UI 测试** (`Tests/.../UI/`): 测试 DouhuaQuoteManager 语句覆盖率

#### Go 后端测试
测试文件统一放在 `server/tests/` 目录下，与 `internal/` 分离，便于管理：
- **模型测试** (`tests/model/`): VectorClock Scan/Value、JSON 序列化、DTO 验证、APIResponse
- **中间件测试** (`tests/middleware/`): JWT 认证、CORS 头、RequestID 生成
- **服务测试** (`tests/service/`): 业务验证逻辑、月经预测算法、WSHub 通信
- **处理器测试** (`tests/handler/`): HTTP 请求绑定验证、鉴权检查（httptest）
- **配置测试** (`tests/config/`): 默认值、环境变量覆盖

### TCA 测试模式
```swift
// 1. 创建 TestStore，用 withDependencies 注入 mock
let store = TestStore(initialState: SomeFeature.State()) {
    SomeFeature()
} withDependencies: {
    $0.apiClient.fetchXxx = { ... }  // @DependencyClient 自动生成 testValue
}

// 2. 发送 Action，断言 State 变化
await store.send(.someAction) { $0.someField = expectedValue }

// 3. 接收异步 Action
await store.receive(\.someResponse) { $0.isLoading = false }

// 4. 非确定性并行 Effect 用 skipReceivedActions()
await store.skipReceivedActions()
```

### 测试要点
- VectorClock: increment/merged/happenedBefore（并发/顺序/相同）
- 计算器: 全 18 键、小数限制 2 位、表达式求值、防除零
- 认证: 3 次失败锁定、10 分钟自动解锁（TestClock）、OTP 倒计时
- 攒钱: canModify 修改限制、SavingsProgress 状态判定
- 投资: profit/profitRate 计算、总额联动
