package service

import (
	"context"
	"time"

	"github.com/douhuajizhang/server/internal/model"
	"github.com/douhuajizhang/server/internal/repository"
	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// UserService 用户服务
type UserService struct {
	userRepo  *repository.UserRepository
	badgeRepo *repository.BadgeRepository
}

func NewUserService(userRepo *repository.UserRepository, badgeRepo *repository.BadgeRepository) *UserService {
	return &UserService{userRepo: userRepo, badgeRepo: badgeRepo}
}

func (s *UserService) GetProfile(ctx context.Context, userID uuid.UUID) (*model.User, error) {
	return s.userRepo.GetByID(ctx, userID)
}

func (s *UserService) UpdateProfile(ctx context.Context, user *model.User) error {
	return s.userRepo.Update(ctx, user)
}

func (s *UserService) GetBadges(ctx context.Context, userID uuid.UUID) ([]model.Badge, error) {
	return s.badgeRepo.GetByUserID(ctx, userID)
}

// LedgerService 账本服务
type LedgerService struct {
	ledgerRepo *repository.LedgerRepository
	userRepo   *repository.UserRepository
}

func NewLedgerService(ledgerRepo *repository.LedgerRepository, userRepo *repository.UserRepository) *LedgerService {
	return &LedgerService{ledgerRepo: ledgerRepo, userRepo: userRepo}
}

func (s *LedgerService) GetLedgers(ctx context.Context, userID uuid.UUID) ([]model.Ledger, error) {
	return s.ledgerRepo.GetByUserID(ctx, userID)
}

func (s *LedgerService) CreateLedger(ctx context.Context, userID uuid.UUID, req *model.CreateLedgerRequest) (*model.Ledger, error) {
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
	if err := s.ledgerRepo.Create(ctx, ledger); err != nil {
		return nil, err
	}
	return ledger, nil
}

func (s *LedgerService) GetByID(ctx context.Context, id uuid.UUID) (*model.Ledger, error) {
	return s.ledgerRepo.GetByID(ctx, id)
}

func (s *LedgerService) Delete(ctx context.Context, ledgerID, userID uuid.UUID) error {
	isMember, role, err := s.ledgerRepo.IsMember(ctx, ledgerID, userID)
	if err != nil || !isMember || role != "owner" {
		return ErrForbidden
	}
	return s.ledgerRepo.Delete(ctx, ledgerID)
}

func (s *LedgerService) InviteMember(ctx context.Context, ledgerID, inviterID uuid.UUID, phone string) error {
	isMember, role, err := s.ledgerRepo.IsMember(ctx, ledgerID, inviterID)
	if err != nil || !isMember || (role != "owner" && role != "admin") {
		return ErrForbidden
	}
	user, err := s.userRepo.GetByPhone(ctx, phone)
	if err != nil {
		return ErrNotFound
	}
	member := &model.LedgerMember{
		ID:       uuid.New(),
		LedgerID: ledgerID,
		UserID:   user.ID,
		Role:     "member",
		JoinedAt: time.Now(),
	}
	return s.ledgerRepo.AddMember(ctx, member)
}

func (s *LedgerService) RemoveMember(ctx context.Context, ledgerID, removerID, targetID uuid.UUID) error {
	isMember, role, err := s.ledgerRepo.IsMember(ctx, ledgerID, removerID)
	if err != nil || !isMember || role != "owner" {
		return ErrForbidden
	}
	return s.ledgerRepo.RemoveMember(ctx, ledgerID, targetID)
}

// TransactionService 交易服务
type TransactionService struct {
	txRepo     *repository.TransactionRepository
	ledgerRepo *repository.LedgerRepository
	rdb        interface{} // redis for idempotency
}

func NewTransactionService(txRepo *repository.TransactionRepository, ledgerRepo *repository.LedgerRepository, rdb interface{}) *TransactionService {
	return &TransactionService{txRepo: txRepo, ledgerRepo: ledgerRepo, rdb: rdb}
}

func (s *TransactionService) GetTransactions(ctx context.Context, ledgerID uuid.UUID, page, pageSize int) ([]model.Transaction, int64, error) {
	return s.txRepo.GetPaginated(ctx, ledgerID, page, pageSize)
}

func (s *TransactionService) CreateTransaction(ctx context.Context, ledgerID, userID uuid.UUID, req *model.CreateTransactionRequest) (*model.Transaction, error) {
	opID, _ := uuid.Parse(req.OperationID)

	// Idempotency check
	exists, _ := s.txRepo.CheckOperationExists(ctx, opID)
	if exists {
		return nil, ErrConflict
	}

	amount, _ := decimal.NewFromString(req.Amount)
	date, _ := time.Parse("2006-01-02", req.Date)

	tx := &model.Transaction{
		ID:          uuid.New(),
		OperationID: opID,
		LedgerID:    ledgerID,
		CreatorID:   userID,
		Amount:      amount,
		Type:        req.Type,
		Category:    req.Category,
		Note:        req.Note,
		Date:        date,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := s.txRepo.Create(ctx, tx); err != nil {
		return nil, err
	}
	return tx, nil
}

func (s *TransactionService) DeleteTransaction(ctx context.Context, id uuid.UUID) error {
	return s.txRepo.Delete(ctx, id)
}

func (s *TransactionService) GetStatistics(ctx context.Context, ledgerID uuid.UUID, month, year int) (*model.StatisticsData, error) {
	return s.txRepo.GetStatistics(ctx, ledgerID, month, year)
}

func (s *TransactionService) GetCalendar(ctx context.Context, ledgerID uuid.UUID, month, year int) ([]model.CalendarDayData, error) {
	return s.txRepo.GetCalendarData(ctx, ledgerID, month, year)
}

// SavingsService 攒钱服务
type SavingsService struct {
	savingsRepo *repository.SavingsRepository
	txRepo      *repository.TransactionRepository
}

func NewSavingsService(savingsRepo *repository.SavingsRepository, txRepo *repository.TransactionRepository) *SavingsService {
	return &SavingsService{savingsRepo: savingsRepo, txRepo: txRepo}
}

func (s *SavingsService) GetPlans(ctx context.Context, userID uuid.UUID, year int) ([]model.SavingsPlan, error) {
	return s.savingsRepo.GetByUserAndYear(ctx, userID, year)
}

func (s *SavingsService) CreatePlan(ctx context.Context, plan *model.SavingsPlan) error {
	plan.ID = uuid.New()
	plan.CreatedAt = time.Now()
	plan.UpdatedAt = time.Now()
	return s.savingsRepo.Create(ctx, plan)
}

func (s *SavingsService) GetProgress(ctx context.Context, planID, userID uuid.UUID) (*model.SavingsProgress, error) {
	plan, err := s.savingsRepo.GetByID(ctx, planID)
	if err != nil {
		return nil, err
	}
	income, expense, err := s.txRepo.MonthlyTotals(ctx, userID, plan.Month, plan.Year)
	if err != nil {
		return nil, err
	}
	return &model.SavingsProgress{
		PlanID:       plan.ID,
		Month:        plan.Month,
		Year:         plan.Year,
		TargetAmount: plan.MonthlyGoal,
		TotalIncome:  income,
		TotalExpense: expense,
	}, nil
}

// InvestmentService 投资服务
type InvestmentService struct {
	investmentRepo *repository.InvestmentRepository
}

func NewInvestmentService(investmentRepo *repository.InvestmentRepository) *InvestmentService {
	return &InvestmentService{investmentRepo: investmentRepo}
}

func (s *InvestmentService) GetInvestments(ctx context.Context, userID uuid.UUID) ([]model.Investment, error) {
	return s.investmentRepo.GetByUserID(ctx, userID)
}

func (s *InvestmentService) CreateInvestment(ctx context.Context, inv *model.Investment) error {
	inv.ID = uuid.New()
	inv.CreatedAt = time.Now()
	inv.UpdatedAt = time.Now()
	return s.investmentRepo.Create(ctx, inv)
}

func (s *InvestmentService) DeleteInvestment(ctx context.Context, id uuid.UUID) error {
	return s.investmentRepo.Delete(ctx, id)
}

func (s *InvestmentService) GetMarketQuotes(ctx context.Context, category *string) ([]model.MarketQuote, error) {
	// TODO: Integrate with real market data API
	return []model.MarketQuote{}, nil
}

// HealthService 健康服务
type HealthService struct {
	healthRepo *repository.HealthRepository
}

func NewHealthService(healthRepo *repository.HealthRepository) *HealthService {
	return &HealthService{healthRepo: healthRepo}
}

func (s *HealthService) GetPoopRecords(ctx context.Context, userID uuid.UUID, month, year int) ([]model.PoopRecord, error) {
	return s.healthRepo.GetPoopRecords(ctx, userID, month, year)
}

func (s *HealthService) CreatePoopRecord(ctx context.Context, record *model.PoopRecord) error {
	record.ID = uuid.New()
	record.CreatedAt = time.Now()
	return s.healthRepo.CreatePoopRecord(ctx, record)
}

func (s *HealthService) DeletePoopRecord(ctx context.Context, id uuid.UUID) error {
	return s.healthRepo.DeletePoopRecord(ctx, id)
}

func (s *HealthService) GetMenstrualRecords(ctx context.Context, userID uuid.UUID) ([]model.MenstrualRecord, error) {
	return s.healthRepo.GetMenstrualRecords(ctx, userID)
}

func (s *HealthService) CreateMenstrualRecord(ctx context.Context, record *model.MenstrualRecord) error {
	record.ID = uuid.New()
	record.CreatedAt = time.Now()
	record.UpdatedAt = time.Now()
	return s.healthRepo.CreateMenstrualRecord(ctx, record)
}

func (s *HealthService) DeleteMenstrualRecord(ctx context.Context, id uuid.UUID) error {
	return s.healthRepo.DeleteMenstrualRecord(ctx, id)
}

func (s *HealthService) GetMenstrualPrediction(ctx context.Context, userID uuid.UUID) (*model.MenstrualPrediction, error) {
	records, err := s.healthRepo.GetMenstrualRecords(ctx, userID)
	if err != nil || len(records) == 0 {
		return nil, ErrNotFound
	}

	// Calculate average cycle length
	totalCycle := 0
	count := 0
	for _, r := range records {
		totalCycle += r.CycleLength
		count++
	}
	avgCycle := totalCycle / count

	lastRecord := records[0]
	nextPeriod := lastRecord.StartDate.AddDate(0, 0, avgCycle)
	ovulation := nextPeriod.AddDate(0, 0, -14)

	return &model.MenstrualPrediction{
		NextPeriodDate:     nextPeriod,
		OvulationDate:      ovulation,
		AverageCycleLength: avgCycle,
	}, nil
}

// Sentinel errors
var (
	ErrForbidden = errors.New("没有权限")
	ErrNotFound  = errors.New("资源不存在")
	ErrConflict  = errors.New("操作已存在")
)
