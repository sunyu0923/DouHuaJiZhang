package model

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// User 用户
type User struct {
	ID        uuid.UUID `json:"id" db:"id"`
	Phone     string    `json:"phone" db:"phone"`
	Nickname  string    `json:"nickname" db:"nickname"`
	AvatarURL *string   `json:"avatar_url,omitempty" db:"avatar_url"`
	Password  string    `json:"-" db:"password_hash"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// Ledger 账本
type Ledger struct {
	ID            uuid.UUID    `json:"id" db:"id"`
	Name          string       `json:"name" db:"name"`
	Type          string       `json:"type" db:"type"` // personal | family
	Currency      string       `json:"currency" db:"currency"`
	CoverImageURL *string      `json:"cover_image_url,omitempty" db:"cover_image_url"`
	VectorClock   VectorClock  `json:"vector_clock" db:"vector_clock"`
	CreatedAt     time.Time    `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time    `json:"updated_at" db:"updated_at"`
	Members       []LedgerMember `json:"members,omitempty"`
}

// LedgerMember 账本成员
type LedgerMember struct {
	ID        uuid.UUID `json:"id" db:"id"`
	LedgerID  uuid.UUID `json:"ledger_id" db:"ledger_id"`
	UserID    uuid.UUID `json:"user_id" db:"user_id"`
	Nickname  string    `json:"nickname" db:"nickname"`
	AvatarURL *string   `json:"avatar_url,omitempty" db:"avatar_url"`
	Role      string    `json:"role" db:"role"` // owner | admin | member
	JoinedAt  time.Time `json:"joined_at" db:"joined_at"`
}

// VectorClock 向量时钟
type VectorClock struct {
	Clocks map[string]int `json:"clocks"`
}

// Scan implements sql.Scanner for JSONB
func (vc *VectorClock) Scan(src interface{}) error {
	if src == nil {
		vc.Clocks = make(map[string]int)
		return nil
	}
	var data []byte
	switch v := src.(type) {
	case []byte:
		data = v
	case string:
		data = []byte(v)
	default:
		return fmt.Errorf("cannot scan %T into VectorClock", src)
	}
	return json.Unmarshal(data, vc)
}

// Value implements driver.Valuer for JSONB
func (vc VectorClock) Value() (driver.Value, error) {
	return json.Marshal(vc)
}

// Transaction 账单
type Transaction struct {
	ID          uuid.UUID       `json:"id" db:"id"`
	OperationID uuid.UUID       `json:"operation_id" db:"operation_id"`
	LedgerID    uuid.UUID       `json:"ledger_id" db:"ledger_id"`
	CreatorID   uuid.UUID       `json:"creator_id" db:"creator_id"`
	Amount      decimal.Decimal `json:"amount" db:"amount"`
	Type        string          `json:"type" db:"type"`         // expense | income
	Category    string          `json:"category" db:"category"`
	Note        string          `json:"note" db:"note"`
	Date        time.Time       `json:"date" db:"date"`
	CreatedAt   time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time       `json:"updated_at" db:"updated_at"`
}

// SavingsPlan 攒钱计划
type SavingsPlan struct {
	ID            uuid.UUID       `json:"id" db:"id"`
	UserID        uuid.UUID       `json:"user_id" db:"user_id"`
	MonthlyGoal   decimal.Decimal `json:"monthly_goal" db:"monthly_goal"`
	YearlyGoal    decimal.Decimal `json:"yearly_goal" db:"yearly_goal"`
	Month         int             `json:"month" db:"month"`
	Year          int             `json:"year" db:"year"`
	ModifiedCount int             `json:"modified_count" db:"modified_count"`
	CreatedAt     time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time       `json:"updated_at" db:"updated_at"`
}

// SavingsProgress 攒钱进度
type SavingsProgress struct {
	PlanID       uuid.UUID       `json:"plan_id"`
	Month        int             `json:"month"`
	Year         int             `json:"year"`
	TargetAmount decimal.Decimal `json:"target_amount"`
	TotalIncome  decimal.Decimal `json:"total_income"`
	TotalExpense decimal.Decimal `json:"total_expense"`
}

// Investment 投资
type Investment struct {
	ID           uuid.UUID        `json:"id" db:"id"`
	UserID       uuid.UUID        `json:"user_id" db:"user_id"`
	Name         string           `json:"name" db:"name"`
	Type         string           `json:"type" db:"type"`
	Amount       decimal.Decimal  `json:"amount" db:"amount"`
	CurrentValue decimal.Decimal  `json:"current_value" db:"current_value"`
	MaturityDate *time.Time       `json:"maturity_date,omitempty" db:"maturity_date"`
	InterestRate *decimal.Decimal `json:"interest_rate,omitempty" db:"interest_rate"`
	Symbol       *string          `json:"symbol,omitempty" db:"symbol"`
	Quantity     *decimal.Decimal `json:"quantity,omitempty" db:"quantity"`
	BuyPrice     *decimal.Decimal `json:"buy_price,omitempty" db:"buy_price"`
	CreatedAt    time.Time        `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time        `json:"updated_at" db:"updated_at"`
}

// MarketQuote 行情数据
type MarketQuote struct {
	ID            string          `json:"id"`
	Name          string          `json:"name"`
	Price         decimal.Decimal `json:"price"`
	Change        decimal.Decimal `json:"change"`
	ChangePercent float64         `json:"change_percent"`
	Category      string          `json:"category"`
	UpdatedAt     time.Time       `json:"updated_at"`
}

// PoopRecord 拉屎记录
type PoopRecord struct {
	ID        uuid.UUID `json:"id" db:"id"`
	UserID    uuid.UUID `json:"user_id" db:"user_id"`
	Date      time.Time `json:"date" db:"date"`
	Time      time.Time `json:"time" db:"time"`
	Note      string    `json:"note" db:"note"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// MenstrualRecord 月经记录
type MenstrualRecord struct {
	ID          uuid.UUID  `json:"id" db:"id"`
	UserID      uuid.UUID  `json:"user_id" db:"user_id"`
	StartDate   time.Time  `json:"start_date" db:"start_date"`
	EndDate     *time.Time `json:"end_date,omitempty" db:"end_date"`
	CycleLength int        `json:"cycle_length" db:"cycle_length"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
}

// MenstrualPrediction 月经预测
type MenstrualPrediction struct {
	NextPeriodDate    time.Time `json:"next_period_date"`
	OvulationDate     time.Time `json:"ovulation_date"`
	AverageCycleLength int      `json:"average_cycle_length"`
}

// Badge 勋章
type Badge struct {
	ID         uuid.UUID  `json:"id" db:"id"`
	UserID     uuid.UUID  `json:"user_id" db:"user_id"`
	Type       string     `json:"type" db:"type"`
	Name       string     `json:"name" db:"name"`
	IsUnlocked bool       `json:"is_unlocked" db:"is_unlocked"`
	UnlockedAt *time.Time `json:"unlocked_at,omitempty" db:"unlocked_at"`
}

// SyncOperation 同步操作
type SyncOperation struct {
	OperationID uuid.UUID   `json:"operation_id"`
	LedgerID    uuid.UUID   `json:"ledger_id"`
	UserID      uuid.UUID   `json:"user_id"`
	Type        string      `json:"type"` // create | update | delete
	Payload     interface{} `json:"payload"`
	VectorClock VectorClock `json:"vector_clock"`
	Timestamp   time.Time   `json:"timestamp"`
}
