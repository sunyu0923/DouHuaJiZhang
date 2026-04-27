package service

import (
	"context"
	"testing"

	"github.com/douhuajizhang/server/internal/model"
	"github.com/google/uuid"
)

func TestTransactionServiceRejectsNonMemberBeforeWriting(t *testing.T) {
	svc := NewTransactionService(nil, nil, nil)

	req := &model.CreateTransactionRequest{
		OperationID: uuid.NewString(),
		Amount:      "100",
		Type:        "expense",
		Category:    "餐饮",
		Date:        "2026-04-27",
	}

	tx, err := svc.CreateTransaction(context.Background(), uuid.New(), uuid.New(), req)
	if err != ErrForbidden {
		t.Fatalf("expected ErrForbidden, got tx=%v err=%v", tx, err)
	}
}

func TestTransactionServiceRejectsNonMemberBeforeReading(t *testing.T) {
	svc := NewTransactionService(nil, nil, nil)

	_, _, err := svc.GetTransactions(context.Background(), uuid.New(), uuid.New(), 1, 20)
	if err != ErrForbidden {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
}
