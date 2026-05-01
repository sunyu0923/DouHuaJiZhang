package repository_test

import (
	"os"
	"strings"
	"testing"
)

func mustReadRepositoryFile(t *testing.T, path string) string {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read %s: %v", path, err)
	}
	return string(data)
}

func TestTransactionDeleteSQLScopesToLedger(t *testing.T) {
	source := mustReadRepositoryFile(t, "../../internal/repository/transaction_repo.go")

	if strings.Contains(source, "DELETE FROM transactions WHERE id = $1`") {
		t.Fatal("transaction deletion must not be available by transaction id alone")
	}
	if !strings.Contains(source, "DELETE FROM transactions WHERE ledger_id = $1 AND id = $2") {
		t.Fatal("transaction deletion must include ledger_id and transaction id")
	}
}

func TestPrivateDeleteSQLScopesToUser(t *testing.T) {
	source := mustReadRepositoryFile(t, "../../internal/repository/other_repos.go")

	for _, forbidden := range []string{
		"DELETE FROM investments WHERE id = $1`",
		"DELETE FROM poop_records WHERE id = $1`",
		"DELETE FROM menstrual_records WHERE id = $1`",
	} {
		if strings.Contains(source, forbidden) {
			t.Fatalf("unscoped delete remains in repository: %s", forbidden)
		}
	}

	for _, required := range []string{
		"DELETE FROM investments WHERE id = $1 AND user_id = $2",
		"DELETE FROM poop_records WHERE id = $1 AND user_id = $2",
		"DELETE FROM menstrual_records WHERE id = $1 AND user_id = $2",
	} {
		if !strings.Contains(source, required) {
			t.Fatalf("expected scoped delete SQL not found: %s", required)
		}
	}
}
