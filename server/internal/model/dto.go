package model

// LoginRequest 登录请求
type LoginRequest struct {
	Phone            string `json:"phone" binding:"required"`
	Password         string `json:"password,omitempty"`
	VerificationCode string `json:"verification_code,omitempty"`
}

// RegisterRequest 注册请求
type RegisterRequest struct {
	Phone            string `json:"phone" binding:"required"`
	Password         string `json:"password" binding:"required,min=6,max=18"`
	VerificationCode string `json:"verification_code" binding:"required"`
}

// SendCodeRequest 发送验证码请求
type SendCodeRequest struct {
	Phone string `json:"phone" binding:"required"`
}

// WechatLoginRequest 微信登录请求
type WechatLoginRequest struct {
	Code string `json:"code" binding:"required"`
}

// RefreshTokenRequest 刷新令牌请求
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// AuthResponse 认证响应
type AuthResponse struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token"`
	User         User   `json:"user"`
}

// CreateLedgerRequest 创建账本
type CreateLedgerRequest struct {
	Name     string `json:"name" binding:"required,min=1,max=20"`
	Type     string `json:"type" binding:"required,oneof=personal family"`
	Currency string `json:"currency" binding:"required"`
}

// CreateTransactionRequest 创建账单
type CreateTransactionRequest struct {
	OperationID string `json:"operation_id" binding:"required,uuid"`
	Amount      string `json:"amount" binding:"required"`
	Type        string `json:"type" binding:"required,oneof=expense income"`
	Category    string `json:"category" binding:"required"`
	Note        string `json:"note" binding:"max=200"`
	Date        string `json:"date" binding:"required"`
}

// InviteMemberRequest 邀请成员
type InviteMemberRequest struct {
	Phone string `json:"phone" binding:"required"`
}

// UpdateMemberRoleRequest 更新成员角色
type UpdateMemberRoleRequest struct {
	Role string `json:"role" binding:"required,oneof=admin member"`
}

// APIResponse 统一响应格式
type APIResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// PaginatedResponse 分页响应
type PaginatedResponse struct {
	Items    interface{} `json:"items"`
	Total    int64       `json:"total"`
	Page     int         `json:"page"`
	PageSize int         `json:"page_size"`
}

// StatisticsData 统计数据
type StatisticsData struct {
	TotalExpense      string            `json:"total_expense"`
	TotalIncome       string            `json:"total_income"`
	Balance           string            `json:"balance"`
	CategoryBreakdown []CategoryAmount  `json:"category_breakdown"`
	DailyTrend        []DailyAmount     `json:"daily_trend"`
}

// CategoryAmount 分类金额
type CategoryAmount struct {
	Category   string  `json:"category"`
	Amount     string  `json:"amount"`
	Percentage float64 `json:"percentage"`
}

// DailyAmount 日金额
type DailyAmount struct {
	Date    string `json:"date"`
	Expense string `json:"expense"`
	Income  string `json:"income"`
}

// CalendarDayData 日历数据
type CalendarDayData struct {
	Date    string `json:"date"`
	Expense string `json:"expense"`
	Income  string `json:"income"`
}

// Success 返回成功响应
func Success(data interface{}) APIResponse {
	return APIResponse{
		Code:    0,
		Message: "success",
		Data:    data,
	}
}

// Error 返回错误响应
func Error(code int, message string) APIResponse {
	return APIResponse{
		Code:    code,
		Message: message,
	}
}
