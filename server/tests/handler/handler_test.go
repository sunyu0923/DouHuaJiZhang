package handler_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/douhuajizhang/server/internal/handler"
	"github.com/douhuajizhang/server/internal/model"
	"github.com/douhuajizhang/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func init() {
	gin.SetMode(gin.TestMode)
}

// ============ Auth Handler Tests ============

func setupAuthRouter() *gin.Engine {
	r := gin.New()
	// AuthService with nil deps — only binding validation can be tested
	authSvc := service.NewAuthService(nil, nil, nil)
	auth := r.Group("/auth")
	handler.RegisterAuthRoutes(auth, authSvc)
	return r
}

func TestLogin_InvalidJSON(t *testing.T) {
	r := setupAuthRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/login", bytes.NewBufferString("not json"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestLogin_MissingPhone(t *testing.T) {
	r := setupAuthRouter()
	body := `{"password":"test123"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/login", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing phone, got %d", w.Code)
	}
}

func TestRegister_InvalidJSON(t *testing.T) {
	r := setupAuthRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/register", bytes.NewBufferString("{bad"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestRegister_MissingFields(t *testing.T) {
	r := setupAuthRouter()
	body := `{"phone":"13800138000"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/register", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing password & code, got %d", w.Code)
	}
}

func TestRegister_ShortPassword(t *testing.T) {
	r := setupAuthRouter()
	body := `{"phone":"13800138000","password":"12345","verification_code":"123456"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/register", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for short password, got %d", w.Code)
	}
}

func TestSendCode_InvalidJSON(t *testing.T) {
	r := setupAuthRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/send-code", bytes.NewBufferString("bad"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestSendCode_MissingPhone(t *testing.T) {
	r := setupAuthRouter()
	body := `{}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/send-code", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing phone, got %d", w.Code)
	}
}

func TestRefresh_InvalidJSON(t *testing.T) {
	r := setupAuthRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/refresh", bytes.NewBufferString("bad"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestRefresh_MissingToken(t *testing.T) {
	r := setupAuthRouter()
	body := `{}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/refresh", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing refresh_token, got %d", w.Code)
	}
}

// ============ User Handler Tests (auth required) ============

func setupProtectedUserRouter() *gin.Engine {
	r := gin.New()
	userSvc := service.NewUserService(nil, nil)
	userGroup := r.Group("/user")
	handler.RegisterUserRoutes(userGroup, userSvc)
	return r
}

func TestGetProfile_NoAuth(t *testing.T) {
	r := setupProtectedUserRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/user/profile", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestUpdateProfile_NoAuth(t *testing.T) {
	r := setupProtectedUserRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("PUT", "/user/profile", bytes.NewBufferString(`{}`))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestGetBadges_NoAuth(t *testing.T) {
	r := setupProtectedUserRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/user/badges", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

// ============ Ledger Handler Tests ============

func setupLedgerRouter() *gin.Engine {
	r := gin.New()
	ledgerSvc := service.NewLedgerService(nil, nil)
	txSvc := service.NewTransactionService(nil, nil, nil)
	ledgerGroup := r.Group("/ledgers")
	handler.RegisterLedgerRoutes(ledgerGroup, ledgerSvc)
	handler.RegisterTransactionRoutes(ledgerGroup, txSvc)
	return r
}

func TestGetLedgers_NoAuth(t *testing.T) {
	r := setupLedgerRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/ledgers", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestCreateLedger_NoAuth(t *testing.T) {
	r := setupLedgerRouter()
	body := `{"name":"test","type":"personal","currency":"CNY"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/ledgers", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestCreateLedger_InvalidJSON(t *testing.T) {
	r := setupLedgerRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/ledgers", bytes.NewBufferString("bad"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestCreateLedger_MissingName(t *testing.T) {
	r := setupLedgerRouter()
	body := `{"type":"personal","currency":"CNY"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/ledgers", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing name, got %d", w.Code)
	}
}

func TestCreateLedger_InvalidType(t *testing.T) {
	r := setupLedgerRouter()
	body := `{"name":"test","type":"invalid","currency":"CNY"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/ledgers", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid type, got %d", w.Code)
	}
}

// ============ Transaction Handler Tests ============

func TestCreateTransaction_InvalidJSON(t *testing.T) {
	r := setupLedgerRouter()
	ledgerID := uuid.New().String()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/ledgers/"+ledgerID+"/transactions", bytes.NewBufferString("bad"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestCreateTransaction_MissingFields(t *testing.T) {
	r := setupLedgerRouter()
	ledgerID := uuid.New().String()
	body := `{"amount":"100"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/ledgers/"+ledgerID+"/transactions", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing fields, got %d", w.Code)
	}
}

func TestCreateTransaction_InvalidType(t *testing.T) {
	r := setupLedgerRouter()
	ledgerID := uuid.New().String()
	body := `{"operation_id":"` + uuid.New().String() + `","amount":"100","type":"invalid","category":"餐饮","date":"2025-06-01"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/ledgers/"+ledgerID+"/transactions", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid type, got %d", w.Code)
	}
}

func TestCreateTransaction_NoAuth(t *testing.T) {
	r := setupLedgerRouter()
	ledgerID := uuid.New().String()
	body := `{"operation_id":"` + uuid.New().String() + `","amount":"100","type":"expense","category":"餐饮","date":"2025-06-01"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/ledgers/"+ledgerID+"/transactions", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

// ============ Savings Handler Tests ============

func setupSavingsRouter() *gin.Engine {
	r := gin.New()
	savingsSvc := service.NewSavingsService(nil, nil)
	handler.RegisterSavingsRoutes(r.Group("/savings"), savingsSvc)
	return r
}

func TestGetSavings_NoAuth(t *testing.T) {
	r := setupSavingsRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/savings", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestCreateSavings_NoAuth(t *testing.T) {
	r := setupSavingsRouter()
	body := `{"monthly_goal":"3000","yearly_goal":"36000","month":6,"year":2025}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/savings", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestCreateSavings_InvalidJSON(t *testing.T) {
	r := setupSavingsRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/savings", bytes.NewBufferString("bad"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	// Will fail at GetUserID first (401) since it checks auth before binding
	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

// ============ Investment Handler Tests ============

func setupInvestmentRouter() *gin.Engine {
	r := gin.New()
	r.Use(gin.Recovery()) // Prevent panic from nil repo calls
	investmentSvc := service.NewInvestmentService(nil)
	handler.RegisterInvestmentRoutes(r.Group("/investments"), investmentSvc)
	handler.RegisterMarketRoutes(r.Group("/market"), investmentSvc)
	return r
}

func TestGetInvestments_NoAuth(t *testing.T) {
	r := setupInvestmentRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/investments", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestCreateInvestment_NoAuth(t *testing.T) {
	r := setupInvestmentRouter()
	body := `{"name":"基金A","type":"fund","amount":"10000","current_value":"10500"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/investments", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestDeleteInvestment_NoAuth(t *testing.T) {
	r := setupInvestmentRouter()
	id := uuid.New().String()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("DELETE", "/investments/"+id, nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

// ============ Health Handler Tests ============

func setupHealthRouter() *gin.Engine {
	r := gin.New()
	healthSvc := service.NewHealthService(nil)
	handler.RegisterHealthRoutes(r.Group("/health"), healthSvc)
	return r
}

func TestGetPoopRecords_NoAuth(t *testing.T) {
	r := setupHealthRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/health/poop?month=6&year=2025", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestCreatePoopRecord_NoAuth(t *testing.T) {
	r := setupHealthRouter()
	body := `{"note":"正常"}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/health/poop", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestGetMenstrualRecords_NoAuth(t *testing.T) {
	r := setupHealthRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/health/menstrual", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestCreateMenstrualRecord_NoAuth(t *testing.T) {
	r := setupHealthRouter()
	body := `{"start_date":"2025-06-01","cycle_length":28}`
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/health/menstrual", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestMenstrualPrediction_NoAuth(t *testing.T) {
	r := setupHealthRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/health/menstrual/prediction", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

// ============ Response Format Tests ============

func TestErrorResponse_Format(t *testing.T) {
	r := setupAuthRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/login", bytes.NewBufferString("bad"))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	var resp model.APIResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to parse response: %v", err)
	}
	if resp.Code != 400 {
		t.Errorf("expected error code 400, got %d", resp.Code)
	}
	if resp.Message == "" {
		t.Error("expected non-empty error message")
	}
}
