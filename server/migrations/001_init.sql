-- 豆花记账 PostgreSQL Schema
-- 所有金额使用 NUMERIC(15,2)

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- 用户表
-- ============================================
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone       VARCHAR(20) NOT NULL UNIQUE,
    nickname    VARCHAR(50) NOT NULL DEFAULT '豆花用户',
    avatar_url  TEXT,
    password_hash TEXT NOT NULL,
    wechat_openid VARCHAR(100) UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_wechat ON users(wechat_openid) WHERE wechat_openid IS NOT NULL;

-- ============================================
-- 账本表
-- ============================================
CREATE TABLE ledgers (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(50) NOT NULL,
    type            VARCHAR(20) NOT NULL CHECK (type IN ('personal', 'family')),
    currency        VARCHAR(10) NOT NULL DEFAULT 'CNY',
    cover_image_url TEXT,
    vector_clock    JSONB NOT NULL DEFAULT '{"clocks":{}}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- 账本成员表 (多对多 users <-> ledgers)
-- ============================================
CREATE TABLE ledger_members (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ledger_id   UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role        VARCHAR(20) NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (ledger_id, user_id)
);

CREATE INDEX idx_ledger_members_ledger ON ledger_members(ledger_id);
CREATE INDEX idx_ledger_members_user ON ledger_members(user_id);

-- ============================================
-- 账单/交易表
-- ============================================
CREATE TABLE transactions (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operation_id UUID NOT NULL UNIQUE,  -- 幂等键
    ledger_id    UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    creator_id   UUID NOT NULL REFERENCES users(id),
    amount       NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    type         VARCHAR(20) NOT NULL CHECK (type IN ('expense', 'income')),
    category     VARCHAR(50) NOT NULL,
    note         VARCHAR(200) DEFAULT '',
    date         DATE NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transactions_ledger ON transactions(ledger_id);
CREATE INDEX idx_transactions_creator ON transactions(creator_id);
CREATE INDEX idx_transactions_date ON transactions(ledger_id, date DESC);
CREATE INDEX idx_transactions_category ON transactions(ledger_id, category);
CREATE UNIQUE INDEX idx_transactions_operation ON transactions(operation_id);

-- ============================================
-- 攒钱计划表
-- ============================================
CREATE TABLE savings_plans (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    monthly_goal   NUMERIC(15,2) NOT NULL CHECK (monthly_goal >= 0),
    yearly_goal    NUMERIC(15,2) NOT NULL CHECK (yearly_goal >= 0),
    month          INT NOT NULL CHECK (month BETWEEN 1 AND 12),
    year           INT NOT NULL CHECK (year >= 2020),
    modified_count INT NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, month, year)
);

CREATE INDEX idx_savings_plans_user ON savings_plans(user_id, year, month);

-- ============================================
-- 投资表
-- ============================================
CREATE TABLE investments (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name           VARCHAR(100) NOT NULL,
    type           VARCHAR(30) NOT NULL CHECK (type IN ('stock', 'fund', 'fixed_deposit', 'gold', 'forex', 'bond', 'crypto', 'other')),
    amount         NUMERIC(15,2) NOT NULL CHECK (amount >= 0),
    current_value  NUMERIC(15,2) NOT NULL DEFAULT 0,
    maturity_date  DATE,
    interest_rate  NUMERIC(8,4),
    symbol         VARCHAR(20),
    quantity       NUMERIC(15,4),
    buy_price      NUMERIC(15,4),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_investments_user ON investments(user_id);

-- ============================================
-- 拉屎记录表
-- ============================================
CREATE TABLE poop_records (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date       DATE NOT NULL,
    time       TIME NOT NULL,
    note       VARCHAR(20) DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_poop_records_user_date ON poop_records(user_id, date DESC);

-- ============================================
-- 月经记录表
-- ============================================
CREATE TABLE menstrual_records (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    start_date   DATE NOT NULL,
    end_date     DATE,
    cycle_length INT NOT NULL DEFAULT 28 CHECK (cycle_length BETWEEN 15 AND 60),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_menstrual_records_user ON menstrual_records(user_id, start_date DESC);

-- ============================================
-- 勋章表
-- ============================================
CREATE TABLE badges (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type        VARCHAR(50) NOT NULL,
    name        VARCHAR(100) NOT NULL,
    is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    unlocked_at TIMESTAMPTZ,
    UNIQUE (user_id, type)
);

CREATE INDEX idx_badges_user ON badges(user_id);

-- ============================================
-- 幂等操作记录表 (用于确保写操作幂等)
-- ============================================
CREATE TABLE idempotency_keys (
    key         UUID PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id),
    response    JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 自动清理30天前的幂等键
CREATE INDEX idx_idempotency_keys_created ON idempotency_keys(created_at);

-- ============================================
-- 同步操作日志表 (WebSocket 协同)
-- ============================================
CREATE TABLE sync_operations (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operation_id UUID NOT NULL,
    ledger_id    UUID NOT NULL REFERENCES ledgers(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users(id),
    type         VARCHAR(20) NOT NULL CHECK (type IN ('create', 'update', 'delete')),
    payload      JSONB NOT NULL,
    vector_clock JSONB NOT NULL DEFAULT '{"clocks":{}}',
    timestamp    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sync_operations_ledger ON sync_operations(ledger_id, timestamp DESC);

-- ============================================
-- 刷新令牌表
-- ============================================
CREATE TABLE refresh_tokens (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- ============================================
-- 验证码表
-- ============================================
CREATE TABLE verification_codes (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone      VARCHAR(20) NOT NULL,
    code       VARCHAR(6) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_verification_codes_phone ON verification_codes(phone, created_at DESC);

-- ============================================
-- 更新时间触发器
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ledgers_updated_at BEFORE UPDATE ON ledgers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_savings_plans_updated_at BEFORE UPDATE ON savings_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_investments_updated_at BEFORE UPDATE ON investments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menstrual_records_updated_at BEFORE UPDATE ON menstrual_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
