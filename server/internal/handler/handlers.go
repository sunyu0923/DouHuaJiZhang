package handler

import (
	"net/http"
	"strconv"

	"github.com/douhuajizhang/server/internal/middleware"
	"github.com/douhuajizhang/server/internal/model"
	"github.com/douhuajizhang/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// RegisterAuthRoutes 注册认证路由
func RegisterAuthRoutes(r *gin.RouterGroup, svc *service.AuthService) {
	r.POST("/login", func(c *gin.Context) {
		var req model.LoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		resp, err := svc.Login(c.Request.Context(), &req)
		if err != nil {
			c.JSON(http.StatusUnauthorized, model.Error(401, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(resp))
	})

	r.POST("/register", func(c *gin.Context) {
		var req model.RegisterRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		resp, err := svc.Register(c.Request.Context(), &req)
		if err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(resp))
	})

	r.POST("/send-code", func(c *gin.Context) {
		var req model.SendCodeRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		if err := svc.SendVerificationCode(c.Request.Context(), req.Phone); err != nil {
			c.JSON(http.StatusTooManyRequests, model.Error(429, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(nil))
	})

	r.POST("/refresh", func(c *gin.Context) {
		var req model.RefreshTokenRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		resp, err := svc.RefreshToken(c.Request.Context(), req.RefreshToken)
		if err != nil {
			c.JSON(http.StatusUnauthorized, model.Error(401, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(resp))
	})
}

// RegisterUserRoutes 注册用户路由
func RegisterUserRoutes(r *gin.RouterGroup, svc *service.UserService) {
	r.GET("/profile", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		user, err := svc.GetProfile(c.Request.Context(), userID)
		if err != nil {
			c.JSON(http.StatusNotFound, model.Error(404, "用户不存在"))
			return
		}
		c.JSON(http.StatusOK, model.Success(user))
	})

	r.PUT("/profile", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		user, err := svc.GetProfile(c.Request.Context(), userID)
		if err != nil {
			c.JSON(http.StatusNotFound, model.Error(404, "用户不存在"))
			return
		}
		if err := c.ShouldBindJSON(user); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		if err := svc.UpdateProfile(c.Request.Context(), user); err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(user))
	})

	r.GET("/badges", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		badges, err := svc.GetBadges(c.Request.Context(), userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(badges))
	})
}

// RegisterLedgerRoutes 注册账本路由
func RegisterLedgerRoutes(r *gin.RouterGroup, svc *service.LedgerService) {
	r.GET("", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		ledgers, err := svc.GetLedgers(c.Request.Context(), userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(ledgers))
	})

	r.POST("", func(c *gin.Context) {
		var req model.CreateLedgerRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		userID := middleware.GetUserID(c)
		ledger, err := svc.CreateLedger(c.Request.Context(), userID, &req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusCreated, model.Success(ledger))
	})

	r.DELETE("/:id", func(c *gin.Context) {
		id, _ := uuid.Parse(c.Param("id"))
		userID := middleware.GetUserID(c)
		if err := svc.Delete(c.Request.Context(), id, userID); err != nil {
			c.JSON(http.StatusForbidden, model.Error(403, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(nil))
	})

	// Family group
	r.POST("/:id/members", func(c *gin.Context) {
		id, _ := uuid.Parse(c.Param("id"))
		var req model.InviteMemberRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		userID := middleware.GetUserID(c)
		if err := svc.InviteMember(c.Request.Context(), id, userID, req.Phone); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(nil))
	})

	r.DELETE("/:id/members/:userId", func(c *gin.Context) {
		id, _ := uuid.Parse(c.Param("id"))
		targetID, _ := uuid.Parse(c.Param("userId"))
		userID := middleware.GetUserID(c)
		if err := svc.RemoveMember(c.Request.Context(), id, userID, targetID); err != nil {
			c.JSON(http.StatusForbidden, model.Error(403, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(nil))
	})
}

// RegisterTransactionRoutes 注册交易路由
func RegisterTransactionRoutes(r *gin.RouterGroup, svc *service.TransactionService) {
	r.GET("/:id/transactions", func(c *gin.Context) {
		ledgerID, _ := uuid.Parse(c.Param("id"))
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		txns, total, err := svc.GetTransactions(c.Request.Context(), ledgerID, page, pageSize)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(model.PaginatedResponse{
			Items: txns, Total: total, Page: page, PageSize: pageSize,
		}))
	})

	r.POST("/:id/transactions", func(c *gin.Context) {
		ledgerID, _ := uuid.Parse(c.Param("id"))
		var req model.CreateTransactionRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		userID := middleware.GetUserID(c)
		tx, err := svc.CreateTransaction(c.Request.Context(), ledgerID, userID, &req)
		if err != nil {
			if err == service.ErrConflict {
				c.JSON(http.StatusConflict, model.Error(409, "操作已存在"))
				return
			}
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusCreated, model.Success(tx))
	})

	r.DELETE("/:id/transactions/:txId", func(c *gin.Context) {
		txID, _ := uuid.Parse(c.Param("txId"))
		if err := svc.DeleteTransaction(c.Request.Context(), txID); err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(nil))
	})

	// Statistics
	r.GET("/:id/statistics", func(c *gin.Context) {
		ledgerID, _ := uuid.Parse(c.Param("id"))
		month, _ := strconv.Atoi(c.Query("month"))
		year, _ := strconv.Atoi(c.Query("year"))
		stats, err := svc.GetStatistics(c.Request.Context(), ledgerID, month, year)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(stats))
	})

	r.GET("/:id/calendar", func(c *gin.Context) {
		ledgerID, _ := uuid.Parse(c.Param("id"))
		month, _ := strconv.Atoi(c.Query("month"))
		year, _ := strconv.Atoi(c.Query("year"))
		data, err := svc.GetCalendar(c.Request.Context(), ledgerID, month, year)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(data))
	})
}

// RegisterSavingsRoutes 注册攒钱路由
func RegisterSavingsRoutes(r *gin.RouterGroup, svc *service.SavingsService) {
	r.GET("", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		year, _ := strconv.Atoi(c.DefaultQuery("year", "2026"))
		plans, err := svc.GetPlans(c.Request.Context(), userID, year)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(plans))
	})

	r.POST("", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		var plan model.SavingsPlan
		if err := c.ShouldBindJSON(&plan); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		plan.UserID = userID
		if err := svc.CreatePlan(c.Request.Context(), &plan); err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusCreated, model.Success(plan))
	})

	r.GET("/:id/progress", func(c *gin.Context) {
		planID, _ := uuid.Parse(c.Param("id"))
		userID := middleware.GetUserID(c)
		progress, err := svc.GetProgress(c.Request.Context(), planID, userID)
		if err != nil {
			c.JSON(http.StatusNotFound, model.Error(404, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(progress))
	})
}

// RegisterInvestmentRoutes 注册投资路由
func RegisterInvestmentRoutes(r *gin.RouterGroup, svc *service.InvestmentService) {
	r.GET("", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		investments, err := svc.GetInvestments(c.Request.Context(), userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(investments))
	})

	r.POST("", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		var inv model.Investment
		if err := c.ShouldBindJSON(&inv); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		inv.UserID = userID
		if err := svc.CreateInvestment(c.Request.Context(), &inv); err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusCreated, model.Success(inv))
	})

	r.DELETE("/:id", func(c *gin.Context) {
		id, _ := uuid.Parse(c.Param("id"))
		if err := svc.DeleteInvestment(c.Request.Context(), id); err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(nil))
	})
}

// RegisterMarketRoutes 注册行情路由
func RegisterMarketRoutes(r *gin.RouterGroup, svc *service.InvestmentService) {
	r.GET("/quotes", func(c *gin.Context) {
		category := c.Query("category")
		var cat *string
		if category != "" {
			cat = &category
		}
		quotes, err := svc.GetMarketQuotes(c.Request.Context(), cat)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(quotes))
	})
}

// RegisterHealthRoutes 注册健康路由
func RegisterHealthRoutes(r *gin.RouterGroup, svc *service.HealthService) {
	// Poop
	r.GET("/poop", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		queryUID := c.Query("user_id")
		targetID := userID
		if queryUID != "" {
			targetID, _ = uuid.Parse(queryUID)
		}
		month, _ := strconv.Atoi(c.Query("month"))
		year, _ := strconv.Atoi(c.Query("year"))
		records, err := svc.GetPoopRecords(c.Request.Context(), targetID, month, year)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(records))
	})

	r.POST("/poop", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		var record model.PoopRecord
		if err := c.ShouldBindJSON(&record); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		record.UserID = userID
		if err := svc.CreatePoopRecord(c.Request.Context(), &record); err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusCreated, model.Success(record))
	})

	r.DELETE("/poop/:id", func(c *gin.Context) {
		id, _ := uuid.Parse(c.Param("id"))
		if err := svc.DeletePoopRecord(c.Request.Context(), id); err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(nil))
	})

	// Menstrual
	r.GET("/menstrual", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		queryUID := c.Query("user_id")
		targetID := userID
		if queryUID != "" {
			targetID, _ = uuid.Parse(queryUID)
		}
		records, err := svc.GetMenstrualRecords(c.Request.Context(), targetID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(records))
	})

	r.POST("/menstrual", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		var record model.MenstrualRecord
		if err := c.ShouldBindJSON(&record); err != nil {
			c.JSON(http.StatusBadRequest, model.Error(400, err.Error()))
			return
		}
		record.UserID = userID
		if err := svc.CreateMenstrualRecord(c.Request.Context(), &record); err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusCreated, model.Success(record))
	})

	r.DELETE("/menstrual/:id", func(c *gin.Context) {
		id, _ := uuid.Parse(c.Param("id"))
		if err := svc.DeleteMenstrualRecord(c.Request.Context(), id); err != nil {
			c.JSON(http.StatusInternalServerError, model.Error(500, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(nil))
	})

	r.GET("/menstrual/prediction", func(c *gin.Context) {
		userID := middleware.GetUserID(c)
		queryUID := c.Query("user_id")
		targetID := userID
		if queryUID != "" {
			targetID, _ = uuid.Parse(queryUID)
		}
		prediction, err := svc.GetMenstrualPrediction(c.Request.Context(), targetID)
		if err != nil {
			c.JSON(http.StatusNotFound, model.Error(404, err.Error()))
			return
		}
		c.JSON(http.StatusOK, model.Success(prediction))
	})
}
