# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

本项目是一个ios端的项目，为记账软件。

---

## 项目概述

**豆花记账 (DouHuaJiZhang)** — 多用户协同记账 iOS 应用，支持家庭/团队共享账本，目标承载 8,000–10,000 人同时在线。

---

## 技术栈选型

### iOS 客户端
- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI（主体）+ UIKit（复杂组件）
- **架构模式**: TCA (The Composable Architecture)
- **本地持久化**: SwiftData（iOS 17+）/ Core Data（兼容旧版）
- **网络层**: URLSession + Combine / async-await
- **实时通信**: WebSocket（原生 URLSessionWebSocketTask）
- **依赖管理**: Swift Package Manager (SPM)

### 后端服务（需配套开发）
- **运行时**: Go 1.22+（高并发首选）或 Node.js（Fastify）
- **API 协议**: REST + WebSocket（实时账单同步）
- **数据库**: PostgreSQL（主库）+ Redis（缓存/会话/pub-sub）
- **消息队列**: Redis Streams 或 Kafka（异步写入削峰）
- **对象存储**: OSS / S3（票据图片）
- **部署**: Kubernetes + Horizontal Pod Autoscaler

---

## 系统架构

### 并发架构设计（支撑 8k–10w 并发）

```
客户端 (iOS App)
    │
    ├── HTTPS REST API ──► API Gateway (Nginx/Kong)
    │                          │
    └── WebSocket ──────────► WS Gateway (独立服务)
                                   │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼
              API Service    账本服务         用户服务
             (无状态, N副本)  (Business Logic)  (Auth/Profile)
                    │              │
                    └──────┬───────┘
                           ▼
                    PostgreSQL (主从复制)
                    Redis Cluster (6节点)
                           │
                    消息队列 (削峰写入)
```

**关键容量规划**:
- 10k 并发 WebSocket 连接 → WS Gateway 单机可承载约 5万长连接，2节点足够
- 写操作峰值通过 Redis 缓冲后批量落库（Write-Behind 模式）
- 读操作命中率目标 >90%（Redis 热点账本缓存）
- PostgreSQL 连接池：PgBouncer，pool_size = CPU核数 × 2

### iOS 客户端分层架构 (TCA)

```
App Layer
├── Features/               # 功能模块（每个模块独立 Reducer）
│   ├── Auth/               # 登录/注册/OAuth
│   ├── Ledger/             # 账本管理（创建/加入/切换）
│   ├── Transaction/        # 记账（新增/编辑/删除）
│   ├── Statistics/         # 统计图表
│   ├── Sync/               # 协同同步（WebSocket + 冲突解决）
│   └── Settings/           # 个人设置
│
├── Core/
│   ├── Models/             # Swift 值类型 Domain Models
│   ├── Network/            # APIClient（依赖注入，可测试）
│   ├── WebSocketClient/    # 实时同步客户端
│   ├── Persistence/        # SwiftData Store
│   └── Keychain/           # Token 安全存储
│
└── UI/
    ├── DesignSystem/       # 颜色/字体/间距 Token
    └── Components/         # 可复用 SwiftUI 组件
```

### 实时协同同步策略

采用 **操作变换 (Operational Transformation) 简化版** + **乐观更新**:

1. 客户端本地立即写入（乐观 UI）
2. 操作以 `{userId, timestamp, operationType, payload, vectorClock}` 格式发送至 WebSocket
3. 服务端通过 Redis pub-sub 广播给同一账本的其他成员
4. 冲突检测：服务端维护账本级别的向量时钟，客户端收到冲突通知后 merge
5. 离线队列：App 断网时操作暂存本地，重连后按序回放

---

## 核心数据模型

```swift
// 账本
struct Ledger: Identifiable, Codable {
    let id: UUID
    var name: String
    var currency: String          // ISO 4217
    var members: [LedgerMember]
    var vectorClock: [String: Int] // userId -> version
}

// 账单条目
struct Transaction: Identifiable, Codable {
    let id: UUID
    let ledgerId: UUID
    let creatorId: UUID
    var amount: Decimal
    var category: Category
    var note: String
    var attachments: [URL]        // OSS 图片链接
    var createdAt: Date
    var updatedAt: Date
}

// 协同操作（WebSocket 消息）
struct SyncOperation: Codable {
    let operationId: UUID
    let ledgerId: UUID
    let userId: UUID
    let type: OperationType       // .create / .update / .delete
    let payload: Data             // JSON-encoded Transaction delta
    let vectorClock: [String: Int]
    let timestamp: Date
}
```

---

## 后端 API 规范

### 认证
- JWT（access token 15min） + Refresh Token（7天，存 Redis，支持主动吊销）
- Apple Sign In / 微信登录 OAuth

### 核心端点
```
POST   /auth/login
POST   /auth/refresh
GET    /ledgers                    # 我参与的账本列表
POST   /ledgers                    # 创建账本
POST   /ledgers/{id}/members       # 邀请成员（生成邀请码）
GET    /ledgers/{id}/transactions  # 分页查询（cursor-based）
POST   /ledgers/{id}/transactions  # 新建账单
PATCH  /ledgers/{id}/transactions/{txId}
DELETE /ledgers/{id}/transactions/{txId}
WS     /ws/ledgers/{id}            # 账本实时同步通道
```

---

## 开发规范

### iOS 代码规范
- 所有网络请求通过 `APIClient` 依赖注入，禁止在 View 层直接调用
- Reducer 中副作用统一通过 `Effect` 返回，禁止在 Reducer 外部修改 State
- 金额计算全部使用 `Decimal`，禁止 `Float`/`Double`
- 敏感数据（token、用户ID）只存 Keychain，不存 UserDefaults

### 后端规范
- 所有写操作幂等（客户端携带 `operationId`，服务端去重）
- 数据库字段金额类型用 `NUMERIC(15,2)`
- 账本操作必须鉴权：验证请求用户是该账本成员

---

## 性能基准目标

| 指标 | 目标 |
|------|------|
| API P99 响应时间 | < 200ms |
| WebSocket 消息延迟 | < 100ms |
| iOS 冷启动时间 | < 1.5s |
| 账单列表首屏渲染 | < 0.5s |
| 并发 WebSocket 连接 | 10,000 |
| 日活账单写入 QPS | 5,000 |
