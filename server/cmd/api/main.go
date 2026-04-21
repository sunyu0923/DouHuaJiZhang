package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/douhuajizhang/server/internal/config"
	"github.com/douhuajizhang/server/internal/handler"
	"github.com/douhuajizhang/server/internal/middleware"
	"github.com/douhuajizhang/server/internal/repository"
	"github.com/douhuajizhang/server/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

func main() {
	cfg := config.Load()

	// Database
	pool, err := pgxpool.New(context.Background(), cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer pool.Close()

	// Redis
	rdb := redis.NewClient(&redis.Options{
		Addr:     cfg.RedisAddr,
		Password: cfg.RedisPassword,
		DB:       cfg.RedisDB,
	})
	defer rdb.Close()

	// Repositories
	userRepo := repository.NewUserRepository(pool)
	ledgerRepo := repository.NewLedgerRepository(pool)
	transactionRepo := repository.NewTransactionRepository(pool)
	savingsRepo := repository.NewSavingsRepository(pool)
	investmentRepo := repository.NewInvestmentRepository(pool)
	healthRepo := repository.NewHealthRepository(pool)
	badgeRepo := repository.NewBadgeRepository(pool)

	// Services
	authService := service.NewAuthService(userRepo, rdb, cfg)
	userService := service.NewUserService(userRepo, badgeRepo)
	ledgerService := service.NewLedgerService(ledgerRepo, userRepo)
	transactionService := service.NewTransactionService(transactionRepo, ledgerRepo, rdb)
	savingsService := service.NewSavingsService(savingsRepo, transactionRepo)
	investmentService := service.NewInvestmentService(investmentRepo)
	healthService := service.NewHealthService(healthRepo)

	// Router
	r := gin.Default()
	r.Use(middleware.CORS())
	r.Use(middleware.RequestID())
	r.Use(middleware.RateLimiter(rdb))

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// API v1
	v1 := r.Group("/api")
	{
		// Auth (public)
		auth := v1.Group("/auth")
		handler.RegisterAuthRoutes(auth, authService)

		// Protected routes
		protected := v1.Group("")
		protected.Use(middleware.AuthRequired(cfg.JWTSecret))
		{
			handler.RegisterUserRoutes(protected.Group("/user"), userService)
			handler.RegisterLedgerRoutes(protected.Group("/ledgers"), ledgerService)
			handler.RegisterTransactionRoutes(protected.Group("/ledgers"), transactionService)
			handler.RegisterSavingsRoutes(protected.Group("/savings"), savingsService)
			handler.RegisterInvestmentRoutes(protected.Group("/investments"), investmentService)
			handler.RegisterMarketRoutes(protected.Group("/market"), investmentService)
			handler.RegisterHealthRoutes(protected.Group("/health"), healthService)
		}
	}

	// WebSocket
	wsHub := service.NewWSHub(rdb)
	go wsHub.Run()
	r.GET("/ws", middleware.AuthRequired(cfg.JWTSecret), func(c *gin.Context) {
		handler.HandleWebSocket(c, wsHub)
	})

	// HTTP Server
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("Server starting on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}
	log.Println("Server exited")
}
