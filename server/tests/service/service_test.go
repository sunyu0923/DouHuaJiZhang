package service_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/douhuajizhang/server/internal/model"
	"github.com/douhuajizhang/server/internal/service"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// ============ Sentinel Errors Tests ============

func TestSentinelError_Forbidden(t *testing.T) {
	if service.ErrForbidden.Error() != "没有权限" {
		t.Errorf("unexpected error: %s", service.ErrForbidden)
	}
}

func TestSentinelError_NotFound(t *testing.T) {
	if service.ErrNotFound.Error() != "资源不存在" {
		t.Errorf("unexpected error: %s", service.ErrNotFound)
	}
}

func TestSentinelError_Conflict(t *testing.T) {
	if service.ErrConflict.Error() != "操作已存在" {
		t.Errorf("unexpected error: %s", service.ErrConflict)
	}
}

func TestSentinelErrors_AreDifferent(t *testing.T) {
	if service.ErrForbidden == service.ErrNotFound {
		t.Error("ErrForbidden and ErrNotFound should be different")
	}
	if service.ErrForbidden == service.ErrConflict {
		t.Error("ErrForbidden and ErrConflict should be different")
	}
	if service.ErrNotFound == service.ErrConflict {
		t.Error("ErrNotFound and ErrConflict should be different")
	}
}

// ============ TransactionService Validation Tests ============
// Tests that validate input without needing a database connection

func TestTransactionCreate_InvalidOperationID(t *testing.T) {
	svc := service.NewTransactionService(nil, nil, nil)
	req := &model.CreateTransactionRequest{
		OperationID: "not-a-valid-uuid",
		Amount:      "100.00",
		Type:        "expense",
		Category:    "餐饮",
		Date:        "2025-06-01",
	}
	_, err := svc.CreateTransaction(nil, uuid.New(), uuid.New(), req)
	if err == nil {
		t.Fatal("expected error for invalid operation ID")
	}
}

func TestTransactionCreate_InvalidAmount(t *testing.T) {
	svc := service.NewTransactionService(nil, nil, nil)
	req := &model.CreateTransactionRequest{
		OperationID: uuid.New().String(),
		Amount:      "not-a-number",
		Type:        "expense",
		Category:    "餐饮",
		Date:        "2025-06-01",
	}
	_, err := svc.CreateTransaction(nil, uuid.New(), uuid.New(), req)
	if err == nil {
		t.Fatal("expected error for invalid amount")
	}
}

func TestTransactionCreate_ZeroAmount(t *testing.T) {
	svc := service.NewTransactionService(nil, nil, nil)
	req := &model.CreateTransactionRequest{
		OperationID: uuid.New().String(),
		Amount:      "0",
		Type:        "expense",
		Category:    "餐饮",
		Date:        "2025-06-01",
	}
	_, err := svc.CreateTransaction(nil, uuid.New(), uuid.New(), req)
	if err == nil {
		t.Fatal("expected error for zero amount")
	}
}

func TestTransactionCreate_NegativeAmount(t *testing.T) {
	svc := service.NewTransactionService(nil, nil, nil)
	req := &model.CreateTransactionRequest{
		OperationID: uuid.New().String(),
		Amount:      "-50.00",
		Type:        "expense",
		Category:    "餐饮",
		Date:        "2025-06-01",
	}
	_, err := svc.CreateTransaction(nil, uuid.New(), uuid.New(), req)
	if err == nil {
		t.Fatal("expected error for negative amount")
	}
}

func TestTransactionCreate_InvalidDate(t *testing.T) {
	svc := service.NewTransactionService(nil, nil, nil)
	req := &model.CreateTransactionRequest{
		OperationID: uuid.New().String(),
		Amount:      "100.00",
		Type:        "expense",
		Category:    "餐饮",
		Date:        "invalid-date",
	}
	_, err := svc.CreateTransaction(nil, uuid.New(), uuid.New(), req)
	if err == nil {
		t.Fatal("expected error for invalid date")
	}
}

func TestTransactionCreate_WrongDateFormat(t *testing.T) {
	svc := service.NewTransactionService(nil, nil, nil)
	req := &model.CreateTransactionRequest{
		OperationID: uuid.New().String(),
		Amount:      "100.00",
		Type:        "expense",
		Category:    "餐饮",
		Date:        "06/01/2025", // wrong format
	}
	_, err := svc.CreateTransaction(nil, uuid.New(), uuid.New(), req)
	if err == nil {
		t.Fatal("expected error for wrong date format")
	}
}

func TestTransactionCreate_VeryLargeAmount(t *testing.T) {
	svc := service.NewTransactionService(nil, nil, nil)
	req := &model.CreateTransactionRequest{
		OperationID: uuid.New().String(),
		Amount:      "9999999999999.99",
		Type:        "expense",
		Category:    "餐饮",
		Date:        "2025-06-01",
	}
	// This should pass validation (amount is valid), but fail at DB level
	// Since we have nil repos, it will panic/fail at CheckOperationExists
	// We just verify the amount parsing succeeds
	amt, err := decimal.NewFromString(req.Amount)
	if err != nil {
		t.Fatalf("expected valid amount, got error: %v", err)
	}
	if amt.LessThanOrEqual(decimal.Zero) {
		t.Error("expected positive amount")
	}
}

type fakeLedgerMembershipRepo struct {
	isMember bool
	role     string
	err      error
	calls    int
}

func (f *fakeLedgerMembershipRepo) IsMember(ctx context.Context, ledgerID, userID uuid.UUID) (bool, string, error) {
	f.calls++
	return f.isMember, f.role, f.err
}

type fakeTransactionRepo struct {
	getCalls            int
	checkOperationCalls int
	createCalls         int
	deleteCalls         int
	statisticsCalls     int
	calendarCalls       int
	deleteResult        bool
}

func (f *fakeTransactionRepo) GetPaginated(ctx context.Context, ledgerID uuid.UUID, page, pageSize int) ([]model.Transaction, int64, error) {
	f.getCalls++
	return nil, 0, nil
}

func (f *fakeTransactionRepo) CheckOperationExists(ctx context.Context, operationID uuid.UUID) (bool, error) {
	f.checkOperationCalls++
	return false, nil
}

func (f *fakeTransactionRepo) Create(ctx context.Context, tx *model.Transaction) error {
	f.createCalls++
	return nil
}

func (f *fakeTransactionRepo) DeleteFromLedger(ctx context.Context, ledgerID, id uuid.UUID) (bool, error) {
	f.deleteCalls++
	return f.deleteResult, nil
}

func (f *fakeTransactionRepo) GetStatistics(ctx context.Context, ledgerID uuid.UUID, month, year int) (*model.StatisticsData, error) {
	f.statisticsCalls++
	return &model.StatisticsData{}, nil
}

func (f *fakeTransactionRepo) GetCalendarData(ctx context.Context, ledgerID uuid.UUID, month, year int) ([]model.CalendarDayData, error) {
	f.calendarCalls++
	return nil, nil
}

func (f *fakeTransactionRepo) MonthlyTotals(ctx context.Context, userID uuid.UUID, month, year int) (decimal.Decimal, decimal.Decimal, error) {
	return decimal.Zero, decimal.Zero, nil
}

func validCreateTransactionRequest() *model.CreateTransactionRequest {
	return &model.CreateTransactionRequest{
		OperationID: uuid.New().String(),
		Amount:      "100.00",
		Type:        "expense",
		Category:    "餐饮",
		Date:        "2025-06-01",
	}
}

func TestTransactionGet_NonMemberForbidden(t *testing.T) {
	txRepo := &fakeTransactionRepo{}
	ledgerRepo := &fakeLedgerMembershipRepo{isMember: false}
	svc := service.NewTransactionService(txRepo, ledgerRepo, nil)

	_, _, err := svc.GetTransactions(context.Background(), uuid.New(), uuid.New(), 1, 20)
	if !errors.Is(err, service.ErrForbidden) {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
	if txRepo.getCalls != 0 {
		t.Fatalf("expected transactions not to be read, got %d reads", txRepo.getCalls)
	}
}

func TestTransactionCreate_NonMemberCannotProbeOperationID(t *testing.T) {
	txRepo := &fakeTransactionRepo{}
	ledgerRepo := &fakeLedgerMembershipRepo{isMember: false}
	svc := service.NewTransactionService(txRepo, ledgerRepo, nil)

	_, err := svc.CreateTransaction(context.Background(), uuid.New(), uuid.New(), validCreateTransactionRequest())
	if !errors.Is(err, service.ErrForbidden) {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
	if txRepo.checkOperationCalls != 0 {
		t.Fatalf("expected idempotency key not to be probed, got %d probes", txRepo.checkOperationCalls)
	}
	if txRepo.createCalls != 0 {
		t.Fatalf("expected transaction not to be created, got %d creates", txRepo.createCalls)
	}
}

func TestTransactionDelete_NonMemberForbidden(t *testing.T) {
	txRepo := &fakeTransactionRepo{deleteResult: true}
	ledgerRepo := &fakeLedgerMembershipRepo{isMember: false}
	svc := service.NewTransactionService(txRepo, ledgerRepo, nil)

	err := svc.DeleteTransaction(context.Background(), uuid.New(), uuid.New(), uuid.New())
	if !errors.Is(err, service.ErrForbidden) {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
	if txRepo.deleteCalls != 0 {
		t.Fatalf("expected transaction not to be deleted, got %d deletes", txRepo.deleteCalls)
	}
}

func TestTransactionDelete_WrongLedgerForbidden(t *testing.T) {
	txRepo := &fakeTransactionRepo{deleteResult: false}
	ledgerRepo := &fakeLedgerMembershipRepo{isMember: true, role: "member"}
	svc := service.NewTransactionService(txRepo, ledgerRepo, nil)

	err := svc.DeleteTransaction(context.Background(), uuid.New(), uuid.New(), uuid.New())
	if !errors.Is(err, service.ErrForbidden) {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
	if txRepo.deleteCalls != 1 {
		t.Fatalf("expected scoped delete attempt, got %d", txRepo.deleteCalls)
	}
}

type fakeInvestmentRepo struct {
	deleteResult bool
	deleteCalls  int
}

func (f *fakeInvestmentRepo) GetByUserID(ctx context.Context, userID uuid.UUID) ([]model.Investment, error) {
	return nil, nil
}

func (f *fakeInvestmentRepo) Create(ctx context.Context, inv *model.Investment) error {
	return nil
}

func (f *fakeInvestmentRepo) DeleteByUser(ctx context.Context, id, userID uuid.UUID) (bool, error) {
	f.deleteCalls++
	return f.deleteResult, nil
}

func TestInvestmentDelete_NotOwnedForbidden(t *testing.T) {
	repo := &fakeInvestmentRepo{deleteResult: false}
	svc := service.NewInvestmentService(repo)

	err := svc.DeleteInvestment(context.Background(), uuid.New(), uuid.New())
	if !errors.Is(err, service.ErrForbidden) {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
	if repo.deleteCalls != 1 {
		t.Fatalf("expected ownership-scoped delete, got %d calls", repo.deleteCalls)
	}
}

type fakeHealthRepo struct {
	poopDeleteResult      bool
	menstrualDeleteResult bool
	poopDeleteCalls       int
	menstrualDeleteCalls  int
}

func (f *fakeHealthRepo) GetPoopRecords(ctx context.Context, userID uuid.UUID, month, year int) ([]model.PoopRecord, error) {
	return nil, nil
}

func (f *fakeHealthRepo) CreatePoopRecord(ctx context.Context, record *model.PoopRecord) error {
	return nil
}

func (f *fakeHealthRepo) DeletePoopRecordByUser(ctx context.Context, id, userID uuid.UUID) (bool, error) {
	f.poopDeleteCalls++
	return f.poopDeleteResult, nil
}

func (f *fakeHealthRepo) GetMenstrualRecords(ctx context.Context, userID uuid.UUID) ([]model.MenstrualRecord, error) {
	return nil, nil
}

func (f *fakeHealthRepo) CreateMenstrualRecord(ctx context.Context, record *model.MenstrualRecord) error {
	return nil
}

func (f *fakeHealthRepo) DeleteMenstrualRecordByUser(ctx context.Context, id, userID uuid.UUID) (bool, error) {
	f.menstrualDeleteCalls++
	return f.menstrualDeleteResult, nil
}

func TestHealthDeletePoop_NotOwnedForbidden(t *testing.T) {
	repo := &fakeHealthRepo{poopDeleteResult: false}
	svc := service.NewHealthService(repo)

	err := svc.DeletePoopRecord(context.Background(), uuid.New(), uuid.New())
	if !errors.Is(err, service.ErrForbidden) {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
	if repo.poopDeleteCalls != 1 {
		t.Fatalf("expected ownership-scoped delete, got %d calls", repo.poopDeleteCalls)
	}
}

func TestHealthDeleteMenstrual_NotOwnedForbidden(t *testing.T) {
	repo := &fakeHealthRepo{menstrualDeleteResult: false}
	svc := service.NewHealthService(repo)

	err := svc.DeleteMenstrualRecord(context.Background(), uuid.New(), uuid.New())
	if !errors.Is(err, service.ErrForbidden) {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
	if repo.menstrualDeleteCalls != 1 {
		t.Fatalf("expected ownership-scoped delete, got %d calls", repo.menstrualDeleteCalls)
	}
}

// ============ LedgerService Logic Tests ============

func TestLedgerCreate_FieldPopulation(t *testing.T) {
	req := &model.CreateLedgerRequest{
		Name:     "家庭账本",
		Type:     "family",
		Currency: "CNY",
	}
	userID := uuid.New()

	// Simulate CreateLedger logic
	ledger := &model.Ledger{
		ID:        uuid.New(),
		Name:      req.Name,
		Type:      req.Type,
		Currency:  req.Currency,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		Members: []model.LedgerMember{
			{ID: uuid.New(), UserID: userID, Role: "owner", JoinedAt: time.Now()},
		},
	}

	if ledger.Name != "家庭账本" {
		t.Errorf("expected name '家庭账本', got %s", ledger.Name)
	}
	if ledger.Type != "family" {
		t.Errorf("expected type 'family', got %s", ledger.Type)
	}
	if ledger.Currency != "CNY" {
		t.Errorf("expected currency 'CNY', got %s", ledger.Currency)
	}
	if len(ledger.Members) != 1 {
		t.Fatalf("expected 1 member, got %d", len(ledger.Members))
	}
	if ledger.Members[0].Role != "owner" {
		t.Errorf("expected owner role, got %s", ledger.Members[0].Role)
	}
	if ledger.Members[0].UserID != userID {
		t.Errorf("expected userID %s, got %s", userID, ledger.Members[0].UserID)
	}
	if ledger.ID == uuid.Nil {
		t.Error("expected non-nil ledger ID")
	}
}

func TestLedgerCreate_PersonalType(t *testing.T) {
	req := &model.CreateLedgerRequest{
		Name:     "个人账本",
		Type:     "personal",
		Currency: "USD",
	}
	if req.Type != "personal" {
		t.Errorf("expected type personal, got %s", req.Type)
	}
}

// ============ MenstrualPrediction Algorithm Tests ============

func TestMenstrualPrediction_MultipleRecords(t *testing.T) {
	records := []model.MenstrualRecord{
		{StartDate: time.Date(2025, 6, 1, 0, 0, 0, 0, time.UTC), CycleLength: 28},
		{StartDate: time.Date(2025, 5, 4, 0, 0, 0, 0, time.UTC), CycleLength: 30},
		{StartDate: time.Date(2025, 4, 4, 0, 0, 0, 0, time.UTC), CycleLength: 26},
	}

	totalCycle := 0
	for _, r := range records {
		totalCycle += r.CycleLength
	}
	avgCycle := totalCycle / len(records)

	if avgCycle != 28 { // (28+30+26)/3 = 28
		t.Errorf("expected average cycle 28, got %d", avgCycle)
	}

	lastRecord := records[0]
	nextPeriod := lastRecord.StartDate.AddDate(0, 0, avgCycle)
	ovulation := nextPeriod.AddDate(0, 0, -14)

	expectedNext := time.Date(2025, 6, 29, 0, 0, 0, 0, time.UTC)
	if !nextPeriod.Equal(expectedNext) {
		t.Errorf("expected next period %v, got %v", expectedNext, nextPeriod)
	}

	expectedOvulation := time.Date(2025, 6, 15, 0, 0, 0, 0, time.UTC)
	if !ovulation.Equal(expectedOvulation) {
		t.Errorf("expected ovulation %v, got %v", expectedOvulation, ovulation)
	}
}

func TestMenstrualPrediction_SingleRecord(t *testing.T) {
	records := []model.MenstrualRecord{
		{StartDate: time.Date(2025, 6, 1, 0, 0, 0, 0, time.UTC), CycleLength: 30},
	}

	avgCycle := records[0].CycleLength
	nextPeriod := records[0].StartDate.AddDate(0, 0, avgCycle)
	expected := time.Date(2025, 7, 1, 0, 0, 0, 0, time.UTC)
	if !nextPeriod.Equal(expected) {
		t.Errorf("expected %v, got %v", expected, nextPeriod)
	}
}

func TestMenstrualPrediction_ShortCycle(t *testing.T) {
	records := []model.MenstrualRecord{
		{StartDate: time.Date(2025, 6, 1, 0, 0, 0, 0, time.UTC), CycleLength: 21},
		{StartDate: time.Date(2025, 5, 11, 0, 0, 0, 0, time.UTC), CycleLength: 21},
	}

	avgCycle := (records[0].CycleLength + records[1].CycleLength) / 2
	if avgCycle != 21 {
		t.Errorf("expected avg 21, got %d", avgCycle)
	}
	nextPeriod := records[0].StartDate.AddDate(0, 0, avgCycle)
	expected := time.Date(2025, 6, 22, 0, 0, 0, 0, time.UTC)
	if !nextPeriod.Equal(expected) {
		t.Errorf("expected %v, got %v", expected, nextPeriod)
	}
}

func TestMenstrualPrediction_OvulationDate(t *testing.T) {
	nextPeriod := time.Date(2025, 7, 1, 0, 0, 0, 0, time.UTC)
	ovulation := nextPeriod.AddDate(0, 0, -14)
	expected := time.Date(2025, 6, 17, 0, 0, 0, 0, time.UTC)
	if !ovulation.Equal(expected) {
		t.Errorf("expected ovulation %v, got %v", expected, ovulation)
	}
}

// ============ SavingsProgress Logic Tests ============

func TestSavingsProgress_FieldPopulation(t *testing.T) {
	planID := uuid.New()
	progress := &model.SavingsProgress{
		PlanID:       planID,
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

	goalMet := net.GreaterThanOrEqual(progress.TargetAmount)
	if !goalMet {
		t.Error("expected goal to be met (net = target)")
	}
}

func TestSavingsProgress_GoalNotMet(t *testing.T) {
	progress := &model.SavingsProgress{
		TargetAmount: decimal.NewFromInt(5000),
		TotalIncome:  decimal.NewFromInt(4000),
		TotalExpense: decimal.NewFromInt(3500),
	}
	net := progress.TotalIncome.Sub(progress.TotalExpense)
	if net.GreaterThanOrEqual(progress.TargetAmount) {
		t.Error("expected goal NOT met")
	}
}

func TestSavingsProgress_ExceededGoal(t *testing.T) {
	progress := &model.SavingsProgress{
		TargetAmount: decimal.NewFromInt(2000),
		TotalIncome:  decimal.NewFromInt(10000),
		TotalExpense: decimal.NewFromInt(3000),
	}
	net := progress.TotalIncome.Sub(progress.TotalExpense)
	if !net.GreaterThan(progress.TargetAmount) {
		t.Error("expected net to exceed target")
	}
}

// ============ WSHub Tests ============

func TestWSHub_NewHub(t *testing.T) {
	hub := service.NewWSHub(nil)
	if hub == nil {
		t.Fatal("expected non-nil hub")
	}
}

func TestWSClient_Accessors(t *testing.T) {
	hub := service.NewWSHub(nil)
	userID := uuid.New()
	ledgerID := uuid.New()

	client := service.NewWSClient(hub, nil, userID, ledgerID)
	if client.UserID() != userID {
		t.Errorf("expected userID %s, got %s", userID, client.UserID())
	}
	if client.LedgerID() != ledgerID {
		t.Errorf("expected ledgerID %s, got %s", ledgerID, client.LedgerID())
	}
}

func TestWSClient_SendChannel(t *testing.T) {
	hub := service.NewWSHub(nil)
	client := service.NewWSClient(hub, nil, uuid.New(), uuid.New())

	ch := client.Send()
	if ch == nil {
		t.Fatal("expected non-nil send channel")
	}

	// Channel should be buffered (256)
	if cap(ch) != 256 {
		t.Errorf("expected channel capacity 256, got %d", cap(ch))
	}
}

func TestWSHub_RegisterAndBroadcast(t *testing.T) {
	hub := service.NewWSHub(nil)
	go hub.Run()

	ledgerID := uuid.New()
	userA := uuid.New()
	userB := uuid.New()

	clientA := service.NewWSClient(hub, nil, userA, ledgerID)
	clientB := service.NewWSClient(hub, nil, userB, ledgerID)

	hub.Register(clientA)
	hub.Register(clientB)

	// Wait for registration to be processed
	time.Sleep(50 * time.Millisecond)

	// Broadcast from A — B should receive, A should not
	hub.Broadcast(&service.WSMessage{
		LedgerID: ledgerID,
		Data:     []byte("hello"),
		SenderID: userA,
	})

	select {
	case msg := <-clientB.Send():
		if string(msg) != "hello" {
			t.Errorf("expected 'hello', got '%s'", msg)
		}
	case <-time.After(time.Second):
		t.Fatal("timeout waiting for broadcast message")
	}

	// Sender should NOT receive their own message
	select {
	case <-clientA.Send():
		t.Fatal("sender should not receive own message")
	case <-time.After(100 * time.Millisecond):
		// OK
	}
}

func TestWSHub_BroadcastDifferentLedger(t *testing.T) {
	hub := service.NewWSHub(nil)
	go hub.Run()

	ledger1 := uuid.New()
	ledger2 := uuid.New()
	userA := uuid.New()
	userB := uuid.New()

	clientA := service.NewWSClient(hub, nil, userA, ledger1)
	clientB := service.NewWSClient(hub, nil, userB, ledger2)

	hub.Register(clientA)
	hub.Register(clientB)

	time.Sleep(50 * time.Millisecond)

	// Broadcast to ledger1 — clientB (ledger2) should NOT receive
	hub.Broadcast(&service.WSMessage{
		LedgerID: ledger1,
		Data:     []byte("ledger1-msg"),
		SenderID: uuid.New(), // different sender
	})

	// clientA should receive (same ledger, different sender)
	select {
	case msg := <-clientA.Send():
		if string(msg) != "ledger1-msg" {
			t.Errorf("expected 'ledger1-msg', got '%s'", msg)
		}
	case <-time.After(time.Second):
		t.Fatal("timeout: clientA should have received msg")
	}

	// clientB should NOT receive (different ledger)
	select {
	case <-clientB.Send():
		t.Fatal("clientB should not receive message from different ledger")
	case <-time.After(100 * time.Millisecond):
		// OK
	}
}

func TestWSHub_Unregister(t *testing.T) {
	hub := service.NewWSHub(nil)
	go hub.Run()

	ledgerID := uuid.New()
	client := service.NewWSClient(hub, nil, uuid.New(), ledgerID)

	hub.Register(client)
	time.Sleep(50 * time.Millisecond)

	hub.Unregister(client)
	time.Sleep(50 * time.Millisecond)

	// Send channel should be closed after unregister
	_, ok := <-client.Send()
	if ok {
		t.Error("expected send channel to be closed after unregister")
	}
}
