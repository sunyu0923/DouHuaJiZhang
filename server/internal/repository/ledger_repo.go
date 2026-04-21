package repository

import (
	"context"

	"github.com/douhuajizhang/server/internal/model"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type LedgerRepository struct {
	pool *pgxpool.Pool
}

func NewLedgerRepository(pool *pgxpool.Pool) *LedgerRepository {
	return &LedgerRepository{pool: pool}
}

func (r *LedgerRepository) Create(ctx context.Context, ledger *model.Ledger) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	_, err = tx.Exec(ctx,
		`INSERT INTO ledgers (id, name, type, currency, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6)`,
		ledger.ID, ledger.Name, ledger.Type, ledger.Currency, ledger.CreatedAt, ledger.UpdatedAt,
	)
	if err != nil {
		return err
	}

	// Add creator as owner
	if len(ledger.Members) > 0 {
		member := ledger.Members[0]
		_, err = tx.Exec(ctx,
			`INSERT INTO ledger_members (id, ledger_id, user_id, role, joined_at)
			 VALUES ($1, $2, $3, $4, $5)`,
			member.ID, ledger.ID, member.UserID, "owner", member.JoinedAt,
		)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

func (r *LedgerRepository) GetByID(ctx context.Context, id uuid.UUID) (*model.Ledger, error) {
	ledger := &model.Ledger{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, name, type, currency, cover_image_url, vector_clock, created_at, updated_at
		 FROM ledgers WHERE id = $1`, id,
	).Scan(&ledger.ID, &ledger.Name, &ledger.Type, &ledger.Currency,
		&ledger.CoverImageURL, &ledger.VectorClock, &ledger.CreatedAt, &ledger.UpdatedAt)
	if err != nil {
		return nil, err
	}

	members, err := r.GetMembers(ctx, id)
	if err != nil {
		return nil, err
	}
	ledger.Members = members
	return ledger, nil
}

func (r *LedgerRepository) GetByUserID(ctx context.Context, userID uuid.UUID) ([]model.Ledger, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT l.id, l.name, l.type, l.currency, l.cover_image_url, l.vector_clock, l.created_at, l.updated_at
		 FROM ledgers l
		 JOIN ledger_members lm ON l.id = lm.ledger_id
		 WHERE lm.user_id = $1
		 ORDER BY l.created_at DESC`, userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ledgers []model.Ledger
	for rows.Next() {
		var l model.Ledger
		err := rows.Scan(&l.ID, &l.Name, &l.Type, &l.Currency,
			&l.CoverImageURL, &l.VectorClock, &l.CreatedAt, &l.UpdatedAt)
		if err != nil {
			return nil, err
		}
		ledgers = append(ledgers, l)
	}
	return ledgers, nil
}

func (r *LedgerRepository) GetMembers(ctx context.Context, ledgerID uuid.UUID) ([]model.LedgerMember, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT lm.id, lm.ledger_id, lm.user_id, u.nickname, u.avatar_url, lm.role, lm.joined_at
		 FROM ledger_members lm
		 JOIN users u ON lm.user_id = u.id
		 WHERE lm.ledger_id = $1`, ledgerID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var members []model.LedgerMember
	for rows.Next() {
		var m model.LedgerMember
		err := rows.Scan(&m.ID, &m.LedgerID, &m.UserID, &m.Nickname, &m.AvatarURL, &m.Role, &m.JoinedAt)
		if err != nil {
			return nil, err
		}
		members = append(members, m)
	}
	return members, nil
}

func (r *LedgerRepository) AddMember(ctx context.Context, member *model.LedgerMember) error {
	_, err := r.pool.Exec(ctx,
		`INSERT INTO ledger_members (id, ledger_id, user_id, role, joined_at)
		 VALUES ($1, $2, $3, $4, $5)`,
		member.ID, member.LedgerID, member.UserID, member.Role, member.JoinedAt,
	)
	return err
}

func (r *LedgerRepository) RemoveMember(ctx context.Context, ledgerID, userID uuid.UUID) error {
	_, err := r.pool.Exec(ctx,
		`DELETE FROM ledger_members WHERE ledger_id = $1 AND user_id = $2`, ledgerID, userID,
	)
	return err
}

func (r *LedgerRepository) IsMember(ctx context.Context, ledgerID, userID uuid.UUID) (bool, string, error) {
	var role string
	err := r.pool.QueryRow(ctx,
		`SELECT role FROM ledger_members WHERE ledger_id = $1 AND user_id = $2`,
		ledgerID, userID,
	).Scan(&role)
	if err != nil {
		return false, "", err
	}
	return true, role, nil
}

func (r *LedgerRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM ledgers WHERE id = $1`, id)
	return err
}
