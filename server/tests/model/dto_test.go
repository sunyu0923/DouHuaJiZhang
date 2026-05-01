package model_test

import (
	"encoding/json"
	"testing"

	"github.com/douhuajizhang/server/internal/model"
)

// ============ APIResponse Helper Tests ============

func TestSuccess_Response(t *testing.T) {
	resp := model.Success("hello")
	if resp.Code != 0 {
		t.Errorf("expected code 0, got %d", resp.Code)
	}
	if resp.Message != "success" {
		t.Errorf("expected message 'success', got %s", resp.Message)
	}
	if resp.Data != "hello" {
		t.Errorf("expected data 'hello', got %v", resp.Data)
	}
}

func TestSuccess_NilData(t *testing.T) {
	resp := model.Success(nil)
	if resp.Code != 0 {
		t.Errorf("expected code 0, got %d", resp.Code)
	}
	if resp.Data != nil {
		t.Errorf("expected nil data, got %v", resp.Data)
	}
}

func TestSuccess_MapData(t *testing.T) {
	data := map[string]int{"count": 5}
	resp := model.Success(data)
	if resp.Code != 0 {
		t.Errorf("expected code 0, got %d", resp.Code)
	}
	m, ok := resp.Data.(map[string]int)
	if !ok {
		t.Fatal("expected map[string]int data")
	}
	if m["count"] != 5 {
		t.Errorf("expected count=5, got %d", m["count"])
	}
}

func TestError_Response(t *testing.T) {
	resp := model.Error(400, "bad request")
	if resp.Code != 400 {
		t.Errorf("expected code 400, got %d", resp.Code)
	}
	if resp.Message != "bad request" {
		t.Errorf("expected message 'bad request', got %s", resp.Message)
	}
	if resp.Data != nil {
		t.Errorf("expected nil data, got %v", resp.Data)
	}
}

func TestError_InternalServerError(t *testing.T) {
	resp := model.Error(500, "内部错误")
	if resp.Code != 500 {
		t.Errorf("expected code 500, got %d", resp.Code)
	}
	if resp.Message != "内部错误" {
		t.Errorf("expected message '内部错误', got %s", resp.Message)
	}
}

func TestAPIResponse_JSONSerialization(t *testing.T) {
	resp := model.Success(map[string]string{"key": "value"})
	data, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("marshal error: %v", err)
	}
	var parsed model.APIResponse
	if err := json.Unmarshal(data, &parsed); err != nil {
		t.Fatalf("unmarshal error: %v", err)
	}
	if parsed.Code != 0 {
		t.Errorf("expected code 0, got %d", parsed.Code)
	}
}

func TestAPIResponse_DataOmitEmpty(t *testing.T) {
	resp := model.Error(404, "not found")
	data, _ := json.Marshal(resp)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if _, ok := m["data"]; ok {
		t.Error("data should be omitted when nil")
	}
}

// ============ PaginatedResponse Tests ============

func TestPaginatedResponse_Fields(t *testing.T) {
	resp := model.PaginatedResponse{
		Items:    []string{"a", "b", "c"},
		Total:    100,
		Page:     2,
		PageSize: 20,
	}
	if resp.Total != 100 {
		t.Errorf("expected total 100, got %d", resp.Total)
	}
	if resp.Page != 2 {
		t.Errorf("expected page 2, got %d", resp.Page)
	}
	if resp.PageSize != 20 {
		t.Errorf("expected page_size 20, got %d", resp.PageSize)
	}
}

func TestPaginatedResponse_JSONSerialization(t *testing.T) {
	resp := model.PaginatedResponse{
		Items:    []string{"item1"},
		Total:    1,
		Page:     1,
		PageSize: 10,
	}
	data, _ := json.Marshal(resp)
	var m map[string]interface{}
	json.Unmarshal(data, &m)
	if m["total"].(float64) != 1 {
		t.Errorf("expected total 1, got %v", m["total"])
	}
	if m["page"].(float64) != 1 {
		t.Errorf("expected page 1, got %v", m["page"])
	}
}

// ============ Request DTO Tests ============

func TestLoginRequest_Fields(t *testing.T) {
	req := model.LoginRequest{
		Phone:    "13800138000",
		Password: "test123",
	}
	if req.Phone != "13800138000" {
		t.Errorf("wrong phone: %s", req.Phone)
	}
	if req.Password != "test123" {
		t.Errorf("wrong password: %s", req.Password)
	}
}

func TestLoginRequest_VerificationCode(t *testing.T) {
	req := model.LoginRequest{
		Phone:            "13800138000",
		VerificationCode: "123456",
	}
	if req.VerificationCode != "123456" {
		t.Errorf("expected code 123456, got %s", req.VerificationCode)
	}
	if req.Password != "" {
		t.Error("expected empty password")
	}
}

func TestRegisterRequest_Fields(t *testing.T) {
	req := model.RegisterRequest{
		Phone:            "13800138000",
		Password:         "abc123",
		VerificationCode: "654321",
	}
	if req.Phone != "13800138000" {
		t.Errorf("wrong phone: %s", req.Phone)
	}
	if req.VerificationCode != "654321" {
		t.Errorf("wrong code: %s", req.VerificationCode)
	}
}

func TestCreateLedgerRequest_Fields(t *testing.T) {
	tests := []struct {
		name     string
		req      model.CreateLedgerRequest
		wantType string
	}{
		{"personal", model.CreateLedgerRequest{Name: "我的账本", Type: "personal", Currency: "CNY"}, "personal"},
		{"family", model.CreateLedgerRequest{Name: "家庭账本", Type: "family", Currency: "USD"}, "family"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.req.Type != tt.wantType {
				t.Errorf("expected type %s, got %s", tt.wantType, tt.req.Type)
			}
		})
	}
}

func TestUpdateProfileRequest_DoesNotBindUserIdentity(t *testing.T) {
	data := []byte(`{"id":"550e8400-e29b-41d4-a716-446655440000","phone":"13900139000","nickname":"豆花","avatar_url":"https://example.com/a.png"}`)
	var req model.UpdateProfileRequest
	if err := json.Unmarshal(data, &req); err != nil {
		t.Fatalf("unmarshal error: %v", err)
	}
	if req.Nickname == nil || *req.Nickname != "豆花" {
		t.Fatalf("expected nickname to bind, got %v", req.Nickname)
	}
	if req.AvatarURL == nil || *req.AvatarURL != "https://example.com/a.png" {
		t.Fatalf("expected avatar_url to bind, got %v", req.AvatarURL)
	}
}

func TestCreateTransactionRequest_Fields(t *testing.T) {
	req := model.CreateTransactionRequest{
		OperationID: "550e8400-e29b-41d4-a716-446655440000",
		Amount:      "99.50",
		Type:        "expense",
		Category:    "餐饮",
		Note:        "午饭",
		Date:        "2025-06-01",
	}
	if req.Amount != "99.50" {
		t.Errorf("wrong amount: %s", req.Amount)
	}
	if req.Type != "expense" {
		t.Errorf("wrong type: %s", req.Type)
	}
}

func TestInviteMemberRequest_Fields(t *testing.T) {
	req := model.InviteMemberRequest{Phone: "13900139000"}
	if req.Phone != "13900139000" {
		t.Errorf("wrong phone: %s", req.Phone)
	}
}

func TestUpdateMemberRoleRequest_Fields(t *testing.T) {
	tests := []struct {
		role string
	}{
		{"admin"},
		{"member"},
	}
	for _, tt := range tests {
		req := model.UpdateMemberRoleRequest{Role: tt.role}
		if req.Role != tt.role {
			t.Errorf("expected role %s, got %s", tt.role, req.Role)
		}
	}
}

// ============ Statistics DTO Tests ============

func TestStatisticsData_Fields(t *testing.T) {
	stats := model.StatisticsData{
		TotalExpense: "1000.00",
		TotalIncome:  "5000.00",
		Balance:      "4000.00",
		CategoryBreakdown: []model.CategoryAmount{
			{Category: "餐饮", Amount: "500.00", Percentage: 0.5},
		},
		DailyTrend: []model.DailyAmount{
			{Date: "2025-06-01", Expense: "100.00", Income: "0"},
		},
	}
	if stats.Balance != "4000.00" {
		t.Errorf("expected balance 4000.00, got %s", stats.Balance)
	}
	if len(stats.CategoryBreakdown) != 1 {
		t.Fatalf("expected 1 category, got %d", len(stats.CategoryBreakdown))
	}
	if stats.CategoryBreakdown[0].Percentage != 0.5 {
		t.Errorf("expected percentage 0.5, got %f", stats.CategoryBreakdown[0].Percentage)
	}
}

func TestCalendarDayData_Fields(t *testing.T) {
	day := model.CalendarDayData{
		Date:    "2025-06-15",
		Expense: "200.00",
		Income:  "0",
	}
	if day.Date != "2025-06-15" {
		t.Errorf("expected date 2025-06-15, got %s", day.Date)
	}
}

func TestSendCodeRequest_Fields(t *testing.T) {
	req := model.SendCodeRequest{Phone: "13800138000"}
	if req.Phone != "13800138000" {
		t.Errorf("wrong phone: %s", req.Phone)
	}
}

func TestWechatLoginRequest_Fields(t *testing.T) {
	req := model.WechatLoginRequest{Code: "wx_code_123"}
	if req.Code != "wx_code_123" {
		t.Errorf("wrong code: %s", req.Code)
	}
}

func TestRefreshTokenRequest_Fields(t *testing.T) {
	req := model.RefreshTokenRequest{RefreshToken: "some-refresh-token"}
	if req.RefreshToken != "some-refresh-token" {
		t.Errorf("wrong token: %s", req.RefreshToken)
	}
}

func TestAuthResponse_Fields(t *testing.T) {
	resp := model.AuthResponse{
		Token:        "access-token",
		RefreshToken: "refresh-token",
		User:         model.User{Phone: "13800138000"},
	}
	if resp.Token != "access-token" {
		t.Errorf("wrong token: %s", resp.Token)
	}
	if resp.User.Phone != "13800138000" {
		t.Errorf("wrong user phone: %s", resp.User.Phone)
	}
}
