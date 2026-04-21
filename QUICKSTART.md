# 🐶 豆花记账 — 快速启动指南

## 目录
- [环境要求](#环境要求)
- [一键启动后端](#一键启动后端)
- [iOS 客户端构建](#ios-客户端构建)
- [本地开发模式](#本地开发模式)
- [API 接口速查](#api-接口速查)
- [环境变量说明](#环境变量说明)
- [常用运维命令](#常用运维命令)
- [故障排查](#故障排查)

---

## 环境要求

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| **Docker** | 24.0+ | [安装指南](https://docs.docker.com/get-docker/) |
| **Docker Compose** | V2 | Docker Desktop 自带 |
| **Go** | 1.22+ | 仅本地开发需要 |
| **Xcode** | 15.0+ | iOS 客户端构建 |
| **macOS** | 14.0+ (Sonoma) | Xcode 运行要求 |

---

## 一键启动后端

### Windows (PowerShell)

```powershell
# 克隆项目
git clone <repo-url> DouHuaJiZhang
cd DouHuaJiZhang

# 一键启动
.\start.ps1
```

### macOS / Linux

```bash
# 克隆项目
git clone <repo-url> DouHuaJiZhang
cd DouHuaJiZhang

# 添加执行权限 & 启动
chmod +x start.sh
./start.sh
```

启动后将自动:
1. ✅ 检查 Docker 环境
2. ✅ 生成 `.env` 配置文件
3. ✅ 启动 PostgreSQL 16 + Redis 7 + Go API
4. ✅ 自动执行数据库建表 (migrations)
5. ✅ 健康检查确认服务就绪

启动成功后输出:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🌐 API 地址:     http://localhost:8080
  📡 健康检查:     http://localhost:8080/health
  🐘 PostgreSQL:   localhost:5432
  🔴 Redis:        localhost:6379
  🔌 WebSocket:    ws://localhost:8080/ws
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## iOS 客户端构建

```bash
# 1. 在 macOS 上打开 Xcode 项目
open Package.swift

# 2. 选择 iPhone 16 模拟器作为目标设备

# 3. ⌘+R 运行
```

**注意**: iOS 客户端默认连接 `http://localhost:8080`，需确保后端已启动。

如在真机测试，需将 `APIClient.swift` 中的 `baseURL` 改为本机 IP:
```swift
// 例如: http://192.168.1.100:8080
```

---

## 本地开发模式

适用于需要调试 Go 后端代码的场景 — 仅用 Docker 启动数据库，Go 服务本地运行。

### Windows
```powershell
.\start.ps1 dev
```

### macOS / Linux
```bash
./start.sh db

# 然后手动启动 Go 服务
cd server
export DATABASE_URL="postgres://douhua:douhua_secret_2026@localhost:5432/douhuajizhang?sslmode=disable"
go run ./cmd/api
```

---

## API 接口速查

### 认证 (无需 Token)

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/register` | 注册 |
| POST | `/api/auth/login` | 登录 |
| POST | `/api/auth/send-code` | 发送验证码 |
| POST | `/api/auth/refresh` | 刷新 Token |

### 用户 (需 Token)

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/user/profile` | 获取个人信息 |
| PUT | `/api/user/profile` | 更新个人信息 |
| GET | `/api/user/badges` | 获取勋章列表 |

### 账本

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/ledgers` | 账本列表 |
| POST | `/api/ledgers` | 创建账本 |
| DELETE | `/api/ledgers/:id` | 删除账本 |
| POST | `/api/ledgers/:id/members` | 邀请成员 |
| DELETE | `/api/ledgers/:id/members/:userId` | 移除成员 |

### 交易

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/ledgers/:id/transactions?page=1&page_size=20` | 交易列表 |
| POST | `/api/ledgers/:id/transactions` | 新增交易 |
| DELETE | `/api/ledgers/:id/transactions/:txId` | 删除交易 |
| GET | `/api/ledgers/:id/statistics?month=4&year=2026` | 统计数据 |
| GET | `/api/ledgers/:id/calendar?month=4&year=2026` | 日历数据 |

### 攒钱计划

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/savings?year=2026` | 计划列表 |
| POST | `/api/savings` | 创建计划 |
| GET | `/api/savings/:id/progress` | 计划进度 |

### 投资 & 行情

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/investments` | 投资列表 |
| POST | `/api/investments` | 添加投资 |
| DELETE | `/api/investments/:id` | 删除投资 |
| GET | `/api/market/quotes?category=stock` | 行情数据 |

### 健康记录

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health/poop?month=4&year=2026` | 拉屎记录 |
| POST | `/api/health/poop` | 新增拉屎记录 |
| DELETE | `/api/health/poop/:id` | 删除拉屎记录 |
| GET | `/api/health/menstrual` | 月经记录 |
| POST | `/api/health/menstrual` | 新增月经记录 |
| DELETE | `/api/health/menstrual/:id` | 删除月经记录 |
| GET | `/api/health/menstrual/prediction` | 月经预测 |

### WebSocket

```
ws://localhost:8080/ws?ledger_id=<UUID>
Header: Authorization: Bearer <token>
```

### 请求示例

```bash
# 注册
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"Test@123456","verification_code":"123456"}'

# 登录
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"Test@123456"}'

# 创建账本 (携带 Token)
curl -X POST http://localhost:8080/api/ledgers \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"日常开销","type":"personal","currency":"CNY"}'

# 新增交易
curl -X POST http://localhost:8080/api/ledgers/<ledger_id>/transactions \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "operation_id":"550e8400-e29b-41d4-a716-446655440000",
    "amount":"25.50",
    "type":"expense",
    "category":"food",
    "note":"午餐",
    "date":"2026-04-21"
  }'
```

---

## 环境变量说明

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | `8080` | 服务端口 |
| `DATABASE_URL` | `postgres://douhua:...@postgres:5432/douhuajizhang` | PG 连接串 |
| `REDIS_ADDR` | `redis:6379` | Redis 地址 |
| `REDIS_PASSWORD` | _(空)_ | Redis 密码 |
| `JWT_SECRET` | `douhua-jwt-secret-...` | **生产必改** |
| `WECHAT_APP_ID` | _(空)_ | 微信登录 AppID |
| `WECHAT_SECRET` | _(空)_ | 微信登录 Secret |
| `OSS_BUCKET` | _(空)_ | 对象存储 Bucket |
| `OSS_ENDPOINT` | _(空)_ | 对象存储 Endpoint |

⚠️ **生产环境部署前，务必修改 `JWT_SECRET` 和数据库密码!**

---

## 常用运维命令

```bash
# 查看服务状态
cd server && docker compose ps

# 查看实时日志
docker compose logs -f api

# 仅查看数据库日志
docker compose logs -f postgres

# 重启 API 服务
docker compose restart api

# 进入 PostgreSQL 终端
docker compose exec postgres psql -U douhua -d douhuajizhang

# 进入 Redis 终端
docker compose exec redis redis-cli

# 停止所有服务
.\start.ps1 down        # Windows
./start.sh down          # macOS/Linux

# 停止并清除所有数据 (谨慎!)
.\start.ps1 clean        # Windows
./start.sh clean         # macOS/Linux
```

---

## 故障排查

### Docker Desktop 未运行
```
[✗] Docker 未运行，请启动 Docker Desktop
```
→ 启动 Docker Desktop 应用，等待状态变为 "Running"

### 端口被占用
```
Error: bind: address already in use
```
→ 查找并关闭占用端口的进程:
```bash
# macOS/Linux
lsof -i :8080
kill -9 <PID>

# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

### 数据库连接失败
```
Unable to connect to database
```
→ 确认 PostgreSQL 容器已启动:
```bash
docker compose ps postgres
docker compose logs postgres
```

### API 返回 401
→ Token 可能已过期，使用 `/api/auth/refresh` 刷新，或重新登录

### 开发环境验证码
开发模式下验证码会打印在控制台日志中:
```
[DEV] Verification code for 13800138000: 123456
```

---

## 项目结构一览

```
DouHuaJiZhang/
├── start.sh                    # macOS/Linux 启动脚本
├── start.ps1                   # Windows 启动脚本
├── QUICKSTART.md               # 本文件
├── Package.swift               # iOS SPM 配置
├── Sources/DouHuaJiZhang/      # iOS 客户端代码
│   ├── App/                    # 入口 + 根 Store
│   ├── Features/               # 8大功能模块
│   ├── Core/                   # 网络/存储/WebSocket
│   └── UI/                     # 设计系统 + 豆花 IP
└── server/                     # Go 后端
    ├── docker-compose.yml      # Docker 编排
    ├── Dockerfile              # API 容器构建
    ├── .env.example            # 环境变量模板
    ├── cmd/api/main.go         # 服务入口
    ├── internal/               # 业务代码
    │   ├── config/             # 配置
    │   ├── middleware/         # 中间件 (JWT/CORS/限流)
    │   ├── model/              # 数据模型 + DTO
    │   ├── repository/         # 数据访问层
    │   ├── service/            # 业务逻辑层
    │   └── handler/            # HTTP 处理器
    └── migrations/             # 数据库建表脚本
```
