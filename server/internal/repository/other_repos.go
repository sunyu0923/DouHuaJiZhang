package repository

import (
	"context"

	"github.com/douhuajizhang/server/internal/model"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type SavingsRepository struct{ pool *pgxpool.Pool }

func NewSavingsRepository(pool *pgxpool.Pool) *SavingsRepository {
	return &SavingsRepository{pool: pool}
}

func (r *SavingsRepository) Create(ctx context.Context, plan *model.SavingsPlan) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO savings_plans (id, user_id, monthly_goal, yearly_goal, month, year, modified_count, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		plan.ID, plan.UserID, plan.MonthlyGoal, plan.YearlyGoal, plan.Month, plan.Year, plan.ModifiedCount, plan.CreatedAt, plan.UpdatedAt,
	)
	return err
}

func (r *SavingsRepository) GetByUserAndYear(ctx context.Context, userID uuid.UUID, year int) ([]model.SavingsPlan, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, user_id, monthly_goal, yearly_goal, month, year, modified_count, created_at, updated_at
		 FROM savings_plans WHERE user_id = $1 AND year = $2 ORDER BY month`, userID, year,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var plans []model.SavingsPlan
	for rows.Next() {
		var p model.SavingsPlan
		err := rows.Scan(&p.ID, &p.UserID, &p.MonthlyGoal, &p.YearlyGoal, &p.Month, &p.Year, &p.ModifiedCount, &p.CreatedAt, &p.UpdatedAt)
		if err != nil {
			return nil, err
		}
		plans = append(plans, p)
	}
	return plans, nil
}

func (r *SavingsRepository) GetByID(ctx context.Context, id uuid.UUID) (*model.SavingsPlan, error) {
	p := &model.SavingsPlan{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, user_id, monthly_goal, yearly_goal, month, year, modified_count, created_at, updated_at
		 FROM savings_plans WHERE id = $1`, id,
	).Scan(&p.ID, &p.UserID, &p.MonthlyGoal, &p.YearlyGoal, &p.Month, &p.Year, &p.ModifiedCount, &p.CreatedAt, &p.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *SavingsRepository) Update(ctx context.Context, plan *model.SavingsPlan) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE savings_plans SET monthly_goal=$2, yearly_goal=$3, modified_count=$4 WHERE id=$1`,
		plan.ID, plan.MonthlyGoal, plan.YearlyGoal, plan.ModifiedCount,
	)
	return err
}

// -------- Investment --------

type InvestmentRepository struct{ pool *pgxpool.Pool }

func NewInvestmentRepository(pool *pgxpool.Pool) *InvestmentRepository {
	return &InvestmentRepository{pool: pool}
}

func (r *InvestmentRepository) Create(ctx context.Context, inv *model.Investment) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO investments (id, user_id, name, type, amount, current_value, maturity_date, interest_rate, symbol, quantity, buy_price, created_at, updated_at)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`,
		inv.ID, inv.UserID, inv.Name, inv.Type, inv.Amount, inv.CurrentValue,
		inv.MaturityDate, inv.InterestRate, inv.Symbol, inv.Quantity, inv.BuyPrice, inv.CreatedAt, inv.UpdatedAt,
	)
	return err
}

func (r *InvestmentRepository) GetByUserID(ctx context.Context, userID uuid.UUID) ([]model.Investment, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, user_id, name, type, amount, current_value, maturity_date, interest_rate, symbol, quantity, buy_price, created_at, updated_at
		 FROM investments WHERE user_id = $1 ORDER BY created_at DESC`, userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []model.Investment
	for rows.Next() {
		var i model.Investment
		err := rows.Scan(&i.ID, &i.UserID, &i.Name, &i.Type, &i.Amount, &i.CurrentValue,
			&i.MaturityDate, &i.InterestRate, &i.Symbol, &i.Quantity, &i.BuyPrice, &i.CreatedAt, &i.UpdatedAt)
		if err != nil {
			return nil, err
		}
		list = append(list, i)
	}
	return list, nil
}

func (r *InvestmentRepository) Delete(ctx context.Context, id, userID uuid.UUID) (bool, error) {
	result, err := r.pool.Exec(ctx, `DELETE FROM investments WHERE id = $1 AND user_id = $2`, id, userID)
	if err != nil {
		return false, err
	}
	return result.RowsAffected() > 0, nil
}

// -------- Health --------

type HealthRepository struct{ pool *pgxpool.Pool }

func NewHealthRepository(pool *pgxpool.Pool) *HealthRepository {
	return &HealthRepository{pool: pool}
}

func (r *HealthRepository) CreatePoopRecord(ctx context.Context, record *model.PoopRecord) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO poop_records (id, user_id, date, time, note, created_at)
		 VALUES ($1,$2,$3,$4,$5,$6)`,
		record.ID, record.UserID, record.Date, record.Time, record.Note, record.CreatedAt,
	)
	return err
}

func (r *HealthRepository) GetPoopRecords(ctx context.Context, userID uuid.UUID, month, year int) ([]model.PoopRecord, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, user_id, date, time, note, created_at FROM poop_records
		 WHERE user_id = $1 AND EXTRACT(MONTH FROM date) = $2 AND EXTRACT(YEAR FROM date) = $3
		 ORDER BY date DESC, time DESC`, userID, month, year,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var records []model.PoopRecord
	for rows.Next() {
		var r model.PoopRecord
		err := rows.Scan(&r.ID, &r.UserID, &r.Date, &r.Time, &r.Note, &r.CreatedAt)
		if err != nil {
			return nil, err
		}
		records = append(records, r)
	}
	return records, nil
}

func (r *HealthRepository) DeletePoopRecord(ctx context.Context, id, userID uuid.UUID) (bool, error) {
	result, err := r.pool.Exec(ctx, `DELETE FROM poop_records WHERE id = $1 AND user_id = $2`, id, userID)
	if err != nil {
		return false, err
	}
	return result.RowsAffected() > 0, nil
}

func (r *HealthRepository) CreateMenstrualRecord(ctx context.Context, record *model.MenstrualRecord) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO menstrual_records (id, user_id, start_date, end_date, cycle_length, created_at, updated_at)
		 VALUES ($1,$2,$3,$4,$5,$6,$7)`,
		record.ID, record.UserID, record.StartDate, record.EndDate, record.CycleLength, record.CreatedAt, record.UpdatedAt,
	)
	return err
}

func (r *HealthRepository) GetMenstrualRecords(ctx context.Context, userID uuid.UUID) ([]model.MenstrualRecord, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, user_id, start_date, end_date, cycle_length, created_at, updated_at
		 FROM menstrual_records WHERE user_id = $1 ORDER BY start_date DESC`, userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var records []model.MenstrualRecord
	for rows.Next() {
		var r model.MenstrualRecord
		err := rows.Scan(&r.ID, &r.UserID, &r.StartDate, &r.EndDate, &r.CycleLength, &r.CreatedAt, &r.UpdatedAt)
		if err != nil {
			return nil, err
		}
		records = append(records, r)
	}
	return records, nil
}

func (r *HealthRepository) DeleteMenstrualRecord(ctx context.Context, id, userID uuid.UUID) (bool, error) {
	result, err := r.pool.Exec(ctx, `DELETE FROM menstrual_records WHERE id = $1 AND user_id = $2`, id, userID)
	if err != nil {
		return false, err
	}
	return result.RowsAffected() > 0, nil
}

// -------- Badge --------

type BadgeRepository struct{ pool *pgxpool.Pool }

func NewBadgeRepository(pool *pgxpool.Pool) *BadgeRepository {
	return &BadgeRepository{pool: pool}
}

func (r *BadgeRepository) GetByUserID(ctx context.Context, userID uuid.UUID) ([]model.Badge, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, user_id, type, name, is_unlocked, unlocked_at FROM badges WHERE user_id = $1`, userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var badges []model.Badge
	for rows.Next() {
		var b model.Badge
		err := rows.Scan(&b.ID, &b.UserID, &b.Type, &b.Name, &b.IsUnlocked, &b.UnlockedAt)
		if err != nil {
			return nil, err
		}
		badges = append(badges, b)
	}
	return badges, nil
}

func (r *BadgeRepository) Unlock(ctx context.Context, userID uuid.UUID, badgeType, name string) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO badges (id, user_id, type, name, is_unlocked, unlocked_at)
		 VALUES ($1, $2, $3, $4, true, NOW())
		 ON CONFLICT (user_id, type) DO UPDATE SET is_unlocked = true, unlocked_at = NOW()`,
		uuid.New(), userID, badgeType, name,
	)
	return err
}
