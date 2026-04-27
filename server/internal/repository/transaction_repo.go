package repository

import (
	"context"
	"fmt"

	"github.com/douhuajizhang/server/internal/model"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
)

type TransactionRepository struct {
	pool *pgxpool.Pool
}

func NewTransactionRepository(pool *pgxpool.Pool) *TransactionRepository {
	return &TransactionRepository{pool: pool}
}

func (r *TransactionRepository) Create(ctx context.Context, tx *model.Transaction) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO transactions (id, operation_id, ledger_id, creator_id, amount, type, category, note, date, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		 ON CONFLICT (operation_id) DO NOTHING`,
		tx.ID, tx.OperationID, tx.LedgerID, tx.CreatorID, tx.Amount, tx.Type, tx.Category, tx.Note, tx.Date, tx.CreatedAt, tx.UpdatedAt,
	)
	return err
}

func (r *TransactionRepository) GetByID(ctx context.Context, id uuid.UUID) (*model.Transaction, error) {
	tx := &model.Transaction{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, operation_id, ledger_id, creator_id, amount, type, category, note, date, created_at, updated_at
		 FROM transactions WHERE id = $1`, id,
	).Scan(&tx.ID, &tx.OperationID, &tx.LedgerID, &tx.CreatorID, &tx.Amount, &tx.Type, &tx.Category, &tx.Note, &tx.Date, &tx.CreatedAt, &tx.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return tx, nil
}

func (r *TransactionRepository) GetPaginated(ctx context.Context, ledgerID uuid.UUID, page, pageSize int) ([]model.Transaction, int64, error) {
	var total int64
	err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM transactions WHERE ledger_id = $1`, ledgerID,
	).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	rows, err := r.pool.Query(ctx,
		`SELECT id, operation_id, ledger_id, creator_id, amount, type, category, note, date, created_at, updated_at
		 FROM transactions WHERE ledger_id = $1
		 ORDER BY date DESC, created_at DESC
		 LIMIT $2 OFFSET $3`, ledgerID, pageSize, offset,
	)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var txns []model.Transaction
	for rows.Next() {
		var t model.Transaction
		err := rows.Scan(&t.ID, &t.OperationID, &t.LedgerID, &t.CreatorID, &t.Amount, &t.Type, &t.Category, &t.Note, &t.Date, &t.CreatedAt, &t.UpdatedAt)
		if err != nil {
			return nil, 0, err
		}
		txns = append(txns, t)
	}
	return txns, total, nil
}

func (r *TransactionRepository) Delete(ctx context.Context, ledgerID, id uuid.UUID) (bool, error) {
	tag, err := r.pool.Exec(ctx, `DELETE FROM transactions WHERE ledger_id = $1 AND id = $2`, ledgerID, id)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() > 0, nil
}

func (r *TransactionRepository) GetStatistics(ctx context.Context, ledgerID uuid.UUID, month, year int) (*model.StatisticsData, error) {
	datePrefix := fmt.Sprintf("%04d-%02d", year, month)

	// Total expense/income
	var totalExpense, totalIncome decimal.Decimal
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END), 0),
		        COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END), 0)
		 FROM transactions WHERE ledger_id = $1 AND TO_CHAR(date, 'YYYY-MM') = $2`,
		ledgerID, datePrefix,
	).Scan(&totalExpense, &totalIncome)
	if err != nil {
		return nil, err
	}

	// Category breakdown
	rows, err := r.pool.Query(ctx,
		`SELECT category, SUM(amount) as total
		 FROM transactions WHERE ledger_id = $1 AND TO_CHAR(date, 'YYYY-MM') = $2 AND type = 'expense'
		 GROUP BY category ORDER BY total DESC`, ledgerID, datePrefix,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var breakdown []model.CategoryAmount
	for rows.Next() {
		var ca model.CategoryAmount
		var amount decimal.Decimal
		err := rows.Scan(&ca.Category, &amount)
		if err != nil {
			return nil, err
		}
		ca.Amount = amount.String()
		if !totalExpense.IsZero() {
			pct, _ := amount.Div(totalExpense).Float64()
			ca.Percentage = pct
		}
		breakdown = append(breakdown, ca)
	}

	// Daily trend
	dRows, err := r.pool.Query(ctx,
		`SELECT date::text,
		        COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END), 0),
		        COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END), 0)
		 FROM transactions WHERE ledger_id = $1 AND TO_CHAR(date, 'YYYY-MM') = $2
		 GROUP BY date ORDER BY date`, ledgerID, datePrefix,
	)
	if err != nil {
		return nil, err
	}
	defer dRows.Close()

	var daily []model.DailyAmount
	for dRows.Next() {
		var da model.DailyAmount
		var exp, inc decimal.Decimal
		err := dRows.Scan(&da.Date, &exp, &inc)
		if err != nil {
			return nil, err
		}
		da.Expense = exp.String()
		da.Income = inc.String()
		daily = append(daily, da)
	}

	return &model.StatisticsData{
		TotalExpense:      totalExpense.String(),
		TotalIncome:       totalIncome.String(),
		Balance:           totalIncome.Sub(totalExpense).String(),
		CategoryBreakdown: breakdown,
		DailyTrend:        daily,
	}, nil
}

func (r *TransactionRepository) GetCalendarData(ctx context.Context, ledgerID uuid.UUID, month, year int) ([]model.CalendarDayData, error) {
	datePrefix := fmt.Sprintf("%04d-%02d", year, month)
	rows, err := r.pool.Query(ctx,
		`SELECT date::text,
		        COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END), 0),
		        COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END), 0)
		 FROM transactions WHERE ledger_id = $1 AND TO_CHAR(date, 'YYYY-MM') = $2
		 GROUP BY date ORDER BY date`, ledgerID, datePrefix,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var data []model.CalendarDayData
	for rows.Next() {
		var d model.CalendarDayData
		var exp, inc decimal.Decimal
		err := rows.Scan(&d.Date, &exp, &inc)
		if err != nil {
			return nil, err
		}
		d.Expense = exp.String()
		d.Income = inc.String()
		data = append(data, d)
	}
	return data, nil
}

// CheckOperationExists 检查幂等操作是否已存在
func (r *TransactionRepository) CheckOperationExists(ctx context.Context, operationID uuid.UUID) (bool, error) {
	var exists bool
	err := r.pool.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM transactions WHERE operation_id = $1)`, operationID,
	).Scan(&exists)
	return exists, err
}

// MonthlyTotals 获取月度收支总计 (用于攒钱进度)
func (r *TransactionRepository) MonthlyTotals(ctx context.Context, userID uuid.UUID, month, year int) (decimal.Decimal, decimal.Decimal, error) {
	datePrefix := fmt.Sprintf("%04d-%02d", year, month)
	var totalIncome, totalExpense decimal.Decimal
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(SUM(CASE WHEN t.type='income' THEN t.amount ELSE 0 END), 0),
		        COALESCE(SUM(CASE WHEN t.type='expense' THEN t.amount ELSE 0 END), 0)
		 FROM transactions t
		 JOIN ledger_members lm ON t.ledger_id = lm.ledger_id
		 WHERE lm.user_id = $1 AND TO_CHAR(t.date, 'YYYY-MM') = $2`,
		userID, datePrefix,
	).Scan(&totalIncome, &totalExpense)
	return totalIncome, totalExpense, err
}
