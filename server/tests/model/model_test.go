package model_test

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/douhuajizhang/server/internal/model"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// ============ VectorClock Tests ============

func TestVectorClock_ScanNil(t *testing.T) {
	vc := &model.VectorClock{}
	if err := vc.Scan(nil); err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
	if vc.Clocks == nil {
		t.Fatal("expected Clocks to be initialized")
	}
	if len(vc.Clocks) != 0 {
		t.Fatalf("expected empty Clocks map, got %d entries", len(vc.Clocks))
	}
}

func TestVectorClock_ScanBytes(t *testing.T) {
	data := []byte(`{"clocks":{"user1":3,"user2":5}}`)
	vc := &model.VectorClock{}
	if err := vc.Scan(data); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if vc.Clocks["user1"] != 3 {
		t.Errorf("expected user1=3, got %d", vc.Clocks["user1"])
	}
	if vc.Clocks["user2"] != 5 {
		t.Errorf("expected user2=5, got %d", vc.Clocks["user2"])
	}
}

func TestVectorClock_ScanString(t *testing.T) {
	vc := &model.VectorClock{}
	if err := vc.Scan(`{"clocks":{"a":1}}`); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if vc.Clocks["a"] != 1 {
		t.Errorf("expected a=1, got %d", vc.Clocks["a"])
	}
}

func TestVectorClock_ScanInvalidType(t *testing.T) {
	vc := &model.VectorClock{}
	if err := vc.Scan(12345); err == nil {
		t.Fatal("expected error for invalid type")
	}
}

func TestVectorClock_ScanInvalidJSON(t *testing.T) {
	vc := &model.VectorClock{}
	if err := vc.Scan([]byte(`{invalid`)); err == nil {
		t.Fatal("expected error for invalid JSON")
	}
}

func TestVectorClock_Value(t *testing.T) {
	vc := model.VectorClock{Clocks: map[string]int{"u1": 2, "u2": 4}}
	val, err := vc.Value()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	data, ok := val.([]byte)
	if !ok {
		t.Fatal("expected []byte from Value()")
	}
	var parsed model.VectorClock
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("failed to unmarshal Value output: %v", err)
	}
	if parsed.Clocks["u1"] != 2 || parsed.Clocks["u2"] != 4 {
		t.Errorf("unexpected parsed values: %v", parsed.Clocks)
	}
}

func TestVectorClock_ValueEmpty(t *testing.T) {
	vc := model.VectorClock{Clocks: map[string]int{}}
	val, err := vc.Value()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if string(val.([]byte)) != `{"clocks":{}}` {
		t.Errorf("unexpected output: %s", string(val.([]byte)))
	}
}

func TestVectorClock_ScanEmptyBytes(t *testing.T) {
	vc := &model.VectorClock{}
	if err := vc.Scan([]byte(`{"clocks":{}}`)); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(vc.Clocks) != 0 {
		t.Errorf("expected empty clocks, got %d", len(vc.Clocks))
	}
}

func TestVectorClock_RoundTrip(t *testing.T) {
	original := model.VectorClock{Clocks: map[string]int{"nodeA": 10, "nodeB": 20, "nodeC": 1}}
	val, err := original.Value()
	if err != nil {
		t.Fatalf("Value error: %v", err)
	}
	restored := &model.VectorClock{}
	if err := restored.Scan(val); err != nil {
		t.Fatalf("Scan error: %v", err)
	}
	for k, v := range original.Clocks {
		if restored.Clocks[k] != v {
			t.Errorf("key %s: expected %d, got %d", k, v, restored.Clocks[k])
		}
	}
}

// ============ User Tests ============

func TestUser_PasswordHiddenInJSON(t *testing.T) {
	u := model.User{
		ID:       uuid.New(),
		Phone:    "13800138000",
		Nickname: "豆花用户",
		Password: "secret_hash",
	}
	data, _ := json.Marshal(u)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if _, ok := m["password"]; ok {
		t.Error("password should not appear in JSON output")
	}
	if _, ok := m["password_hash"]; ok {
		t.Error("password_hash should not appear in JSON output")
	}
}

func TestUser_AvatarURLOmitEmpty(t *testing.T) {
	u := model.User{ID: uuid.New(), Phone: "100", Nickname: "test"}
	data, _ := json.Marshal(u)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if _, ok := m["avatar_url"]; ok {
		t.Error("avatar_url should be omitted when nil")
	}
}

func TestUser_AvatarURLPresent(t *testing.T) {
	avatar := "https://example.com/avatar.png"
	u := model.User{ID: uuid.New(), Phone: "100", Nickname: "test", AvatarURL: &avatar}
	data, _ := json.Marshal(u)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if m["avatar_url"] != avatar {
		t.Errorf("expected avatar_url %s, got %v", avatar, m["avatar_url"])
	}
}

func TestUser_JSONRoundTrip(t *testing.T) {
	now := time.Now().Truncate(time.Millisecond)
	u := model.User{
		ID:        uuid.New(),
		Phone:     "13800138000",
		Nickname:  "测试用户",
		CreatedAt: now,
		UpdatedAt: now,
	}
	data, err := json.Marshal(u)
	if err != nil {
		t.Fatalf("marshal error: %v", err)
	}
	var parsed model.User
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("unmarshal error: %v", err)
	}
	if parsed.Phone != "13800138000" {
		t.Errorf("expected phone 13800138000, got %s", parsed.Phone)
	}
	if parsed.Nickname != "测试用户" {
		t.Errorf("expected nickname 测试用户, got %s", parsed.Nickname)
	}
}

// ============ Transaction Tests ============

func TestTransaction_JSONRoundTrip(t *testing.T) {
	tx := model.Transaction{
		ID:          uuid.New(),
		OperationID: uuid.New(),
		LedgerID:    uuid.New(),
		CreatorID:   uuid.New(),
		Amount:      decimal.NewFromFloat(99.50),
		Type:        "expense",
		Category:    "餐饮",
		Note:        "午饭",
		Date:        time.Now().Truncate(time.Second),
		CreatedAt:   time.Now().Truncate(time.Second),
		UpdatedAt:   time.Now().Truncate(time.Second),
	}
	data, err := json.Marshal(tx)
	if err != nil {
		t.Fatalf("marshal error: %v", err)
	}
	var parsed model.Transaction
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("unmarshal error: %v", err)
	}
	if !parsed.Amount.Equal(tx.Amount) {
		t.Errorf("expected amount %s, got %s", tx.Amount, parsed.Amount)
	}
	if parsed.Category != "餐饮" {
		t.Errorf("expected category 餐饮, got %s", parsed.Category)
	}
	if parsed.Type != "expense" {
		t.Errorf("expected type expense, got %s", parsed.Type)
	}
}

func TestTransaction_DecimalPrecision(t *testing.T) {
	tx := model.Transaction{
		Amount: decimal.RequireFromString("12345.67"),
	}
	data, _ := json.Marshal(tx)
	var parsed model.Transaction
	json.Unmarshal(data, &parsed)
	if !parsed.Amount.Equal(decimal.RequireFromString("12345.67")) {
		t.Errorf("precision lost: got %s", parsed.Amount)
	}
}

// ============ Ledger Tests ============

func TestLedger_WithMembers(t *testing.T) {
	ledger := model.Ledger{
		ID:       uuid.New(),
		Name:     "家庭账本",
		Type:     "family",
		Currency: "CNY",
		Members: []model.LedgerMember{
			{ID: uuid.New(), Role: "owner"},
			{ID: uuid.New(), Role: "member"},
		},
	}
	data, _ := json.Marshal(ledger)
	var parsed model.Ledger
	json.Unmarshal(data, &parsed)
	if len(parsed.Members) != 2 {
		t.Fatalf("expected 2 members, got %d", len(parsed.Members))
	}
	if parsed.Members[0].Role != "owner" {
		t.Errorf("expected first member role owner, got %s", parsed.Members[0].Role)
	}
}

func TestLedger_CoverImageOmitEmpty(t *testing.T) {
	ledger := model.Ledger{ID: uuid.New(), Name: "test", Type: "personal", Currency: "CNY"}
	data, _ := json.Marshal(ledger)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if _, ok := m["cover_image_url"]; ok {
		t.Error("cover_image_url should be omitted when nil")
	}
}

// ============ SavingsPlan Tests ============

func TestSavingsPlan_JSONRoundTrip(t *testing.T) {
	plan := model.SavingsPlan{
		ID:            uuid.New(),
		UserID:        uuid.New(),
		MonthlyGoal:   decimal.NewFromFloat(3000),
		YearlyGoal:    decimal.NewFromFloat(36000),
		Month:         6,
		Year:          2025,
		ModifiedCount: 2,
	}
	data, _ := json.Marshal(plan)
	var parsed model.SavingsPlan
	json.Unmarshal(data, &parsed)
	if parsed.Month != 6 || parsed.Year != 2025 {
		t.Errorf("expected month=6 year=2025, got month=%d year=%d", parsed.Month, parsed.Year)
	}
	if !parsed.MonthlyGoal.Equal(decimal.NewFromFloat(3000)) {
		t.Errorf("unexpected monthly goal: %s", parsed.MonthlyGoal)
	}
	if parsed.ModifiedCount != 2 {
		t.Errorf("expected modified_count=2, got %d", parsed.ModifiedCount)
	}
}

// ============ SavingsProgress Tests ============

func TestSavingsProgress_NetSavings(t *testing.T) {
	progress := model.SavingsProgress{
		PlanID:       uuid.New(),
		Month:        6,
		Year:         2025,
		TargetAmount: decimal.NewFromInt(3000),
		TotalIncome:  decimal.NewFromInt(5000),
		TotalExpense: decimal.NewFromInt(2000),
	}
	net := progress.TotalIncome.Sub(progress.TotalExpense)
	if !net.Equal(decimal.NewFromInt(3000)) {
		t.Errorf("expected net savings 3000, got %s", net)
	}
}

func TestSavingsProgress_Deficit(t *testing.T) {
	progress := model.SavingsProgress{
		TargetAmount: decimal.NewFromInt(5000),
		TotalIncome:  decimal.NewFromInt(3000),
		TotalExpense: decimal.NewFromInt(4000),
	}
	net := progress.TotalIncome.Sub(progress.TotalExpense)
	if !net.IsNegative() {
		t.Error("expected negative net savings")
	}
}

// ============ Investment Tests ============

func TestInvestment_OptionalFieldsOmitted(t *testing.T) {
	inv := model.Investment{
		ID:           uuid.New(),
		UserID:       uuid.New(),
		Name:         "基金A",
		Type:         "fund",
		Amount:       decimal.NewFromFloat(10000),
		CurrentValue: decimal.NewFromFloat(10500),
	}
	data, _ := json.Marshal(inv)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if _, ok := m["maturity_date"]; ok {
		t.Error("maturity_date should be omitted when nil")
	}
	if _, ok := m["interest_rate"]; ok {
		t.Error("interest_rate should be omitted when nil")
	}
	if _, ok := m["symbol"]; ok {
		t.Error("symbol should be omitted when nil")
	}
}

func TestInvestment_WithOptionalFields(t *testing.T) {
	maturity := time.Date(2026, 12, 31, 0, 0, 0, 0, time.UTC)
	rate := decimal.NewFromFloat(0.035)
	symbol := "AAPL"
	qty := decimal.NewFromFloat(100)
	buyPrice := decimal.NewFromFloat(150.50)

	inv := model.Investment{
		ID:           uuid.New(),
		Name:         "苹果股票",
		Type:         "stock",
		Amount:       decimal.NewFromFloat(15050),
		CurrentValue: decimal.NewFromFloat(17000),
		MaturityDate: &maturity,
		InterestRate: &rate,
		Symbol:       &symbol,
		Quantity:     &qty,
		BuyPrice:     &buyPrice,
	}
	data, _ := json.Marshal(inv)
	var parsed model.Investment
	json.Unmarshal(data, &parsed)
	if parsed.Symbol == nil || *parsed.Symbol != "AAPL" {
		t.Error("expected symbol AAPL")
	}
	if parsed.BuyPrice == nil || !parsed.BuyPrice.Equal(buyPrice) {
		t.Error("expected buy_price 150.50")
	}
}

func TestInvestment_ProfitCalculation(t *testing.T) {
	inv := model.Investment{
		Amount:       decimal.NewFromFloat(10000),
		CurrentValue: decimal.NewFromFloat(12000),
	}
	profit := inv.CurrentValue.Sub(inv.Amount)
	if !profit.Equal(decimal.NewFromFloat(2000)) {
		t.Errorf("expected profit 2000, got %s", profit)
	}
	// Profit rate
	profitRate := profit.Div(inv.Amount)
	if !profitRate.Equal(decimal.NewFromFloat(0.2)) {
		t.Errorf("expected profit rate 0.2, got %s", profitRate)
	}
}

// ============ Health Record Tests ============

func TestPoopRecord_JSONFields(t *testing.T) {
	record := model.PoopRecord{
		ID:     uuid.New(),
		UserID: uuid.New(),
		Date:   time.Date(2025, 6, 1, 0, 0, 0, 0, time.UTC),
		Time:   time.Date(0, 1, 1, 8, 30, 0, 0, time.UTC),
		Note:   "正常",
	}
	data, _ := json.Marshal(record)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if m["note"] != "正常" {
		t.Errorf("expected note 正常, got %v", m["note"])
	}
}

func TestMenstrualRecord_EndDateOmitEmpty(t *testing.T) {
	record := model.MenstrualRecord{
		ID:          uuid.New(),
		UserID:      uuid.New(),
		StartDate:   time.Now(),
		CycleLength: 28,
	}
	data, _ := json.Marshal(record)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if _, ok := m["end_date"]; ok {
		t.Error("end_date should be omitted when nil")
	}
}

func TestMenstrualRecord_WithEndDate(t *testing.T) {
	endDate := time.Date(2025, 6, 5, 0, 0, 0, 0, time.UTC)
	record := model.MenstrualRecord{
		ID:          uuid.New(),
		StartDate:   time.Date(2025, 6, 1, 0, 0, 0, 0, time.UTC),
		EndDate:     &endDate,
		CycleLength: 28,
	}
	data, _ := json.Marshal(record)
	var parsed model.MenstrualRecord
	json.Unmarshal(data, &parsed)
	if parsed.EndDate == nil {
		t.Fatal("expected end_date to be present")
	}
}

func TestMenstrualPrediction_Fields(t *testing.T) {
	pred := model.MenstrualPrediction{
		NextPeriodDate:     time.Date(2025, 7, 1, 0, 0, 0, 0, time.UTC),
		OvulationDate:      time.Date(2025, 6, 17, 0, 0, 0, 0, time.UTC),
		AverageCycleLength: 28,
	}
	data, _ := json.Marshal(pred)
	var parsed model.MenstrualPrediction
	json.Unmarshal(data, &parsed)
	if parsed.AverageCycleLength != 28 {
		t.Errorf("expected avg cycle 28, got %d", parsed.AverageCycleLength)
	}
}

// ============ Badge Tests ============

func TestBadge_UnlockedAtOmitEmpty(t *testing.T) {
	badge := model.Badge{
		ID:         uuid.New(),
		UserID:     uuid.New(),
		Type:       "streak_7",
		Name:       "连续记账7天",
		IsUnlocked: false,
	}
	data, _ := json.Marshal(badge)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if _, ok := m["unlocked_at"]; ok {
		t.Error("unlocked_at should be omitted when nil")
	}
	if m["is_unlocked"] != false {
		t.Error("expected is_unlocked false")
	}
}

func TestBadge_Unlocked(t *testing.T) {
	now := time.Now()
	badge := model.Badge{
		ID:         uuid.New(),
		Type:       "streak_7",
		Name:       "连续记账7天",
		IsUnlocked: true,
		UnlockedAt: &now,
	}
	data, _ := json.Marshal(badge)
	var parsed model.Badge
	json.Unmarshal(data, &parsed)
	if !parsed.IsUnlocked {
		t.Error("expected is_unlocked true")
	}
	if parsed.UnlockedAt == nil {
		t.Error("expected unlocked_at to be present")
	}
}

// ============ SyncOperation Tests ============

func TestSyncOperation_JSONFields(t *testing.T) {
	op := model.SyncOperation{
		OperationID: uuid.New(),
		LedgerID:    uuid.New(),
		UserID:      uuid.New(),
		Type:        "create",
		Payload:     map[string]interface{}{"amount": 100},
		VectorClock: model.VectorClock{Clocks: map[string]int{"n1": 1}},
		Timestamp:   time.Now(),
	}
	data, _ := json.Marshal(op)
	var parsed map[string]interface{}
	json.Unmarshal(data, &parsed)
	if parsed["type"] != "create" {
		t.Errorf("expected type create, got %v", parsed["type"])
	}
}

// ============ MarketQuote Tests ============

func TestMarketQuote_JSONRoundTrip(t *testing.T) {
	quote := model.MarketQuote{
		ID:            "SH600519",
		Name:          "贵州茅台",
		Price:         decimal.NewFromFloat(1800.50),
		Change:        decimal.NewFromFloat(25.30),
		ChangePercent: 1.42,
		Category:      "a_stock",
		UpdatedAt:     time.Now().Truncate(time.Second),
	}
	data, _ := json.Marshal(quote)
	var parsed model.MarketQuote
	json.Unmarshal(data, &parsed)
	if parsed.Name != "贵州茅台" {
		t.Errorf("expected name 贵州茅台, got %s", parsed.Name)
	}
	if !parsed.Price.Equal(decimal.NewFromFloat(1800.50)) {
		t.Errorf("expected price 1800.50, got %s", parsed.Price)
	}
}
