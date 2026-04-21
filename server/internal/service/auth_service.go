package service

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"time"

	"github.com/douhuajizhang/server/internal/config"
	"github.com/douhuajizhang/server/internal/model"
	"github.com/douhuajizhang/server/internal/repository"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"golang.org/x/crypto/bcrypt"

	"github.com/douhuajizhang/server/internal/middleware"
)

type AuthService struct {
	userRepo *repository.UserRepository
	rdb      *redis.Client
	cfg      *config.Config
}

func NewAuthService(userRepo *repository.UserRepository, rdb *redis.Client, cfg *config.Config) *AuthService {
	return &AuthService{userRepo: userRepo, rdb: rdb, cfg: cfg}
}

func (s *AuthService) Login(ctx context.Context, req *model.LoginRequest) (*model.AuthResponse, error) {
	user, err := s.userRepo.GetByPhone(ctx, req.Phone)
	if err != nil {
		return nil, errors.New("用户不存在")
	}

	if req.Password != "" {
		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
			return nil, errors.New("密码错误")
		}
	} else if req.VerificationCode != "" {
		if err := s.verifyCode(ctx, req.Phone, req.VerificationCode); err != nil {
			return nil, err
		}
	} else {
		return nil, errors.New("请提供密码或验证码")
	}

	return s.generateTokens(user)
}

func (s *AuthService) Register(ctx context.Context, req *model.RegisterRequest) (*model.AuthResponse, error) {
	// Verify code
	if err := s.verifyCode(ctx, req.Phone, req.VerificationCode); err != nil {
		return nil, err
	}

	// Check existing
	if existing, _ := s.userRepo.GetByPhone(ctx, req.Phone); existing != nil {
		return nil, errors.New("手机号已注册")
	}

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		ID:        uuid.New(),
		Phone:     req.Phone,
		Nickname:  "豆花用户",
		Password:  string(hash),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}

	return s.generateTokens(user)
}

func (s *AuthService) SendVerificationCode(ctx context.Context, phone string) error {
	// Rate limit: 1 code per 60s
	key := fmt.Sprintf("sms_rate:%s", phone)
	if s.rdb.Exists(ctx, key).Val() > 0 {
		return errors.New("验证码发送过于频繁")
	}

	// Generate 6-digit code
	code := generateCode()

	// Store in Redis (5 min expiry)
	codeKey := fmt.Sprintf("sms_code:%s", phone)
	s.rdb.Set(ctx, codeKey, code, 5*time.Minute)
	s.rdb.Set(ctx, key, "1", 60*time.Second)

	// TODO: Send SMS via provider
	fmt.Printf("[DEV] Verification code for %s: %s\n", phone, code)

	return nil
}

func (s *AuthService) RefreshToken(ctx context.Context, refreshToken string) (*model.AuthResponse, error) {
	claims := &middleware.Claims{}
	token, err := jwt.ParseWithClaims(refreshToken, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(s.cfg.JWTSecret), nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("刷新令牌无效")
	}

	userID, _ := uuid.Parse(claims.UserID)
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, errors.New("用户不存在")
	}

	return s.generateTokens(user)
}

func (s *AuthService) generateTokens(user *model.User) (*model.AuthResponse, error) {
	// Access token (72h)
	accessClaims := middleware.Claims{
		UserID: user.ID.String(),
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(s.cfg.JWTExpiry) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessString, err := accessToken.SignedString([]byte(s.cfg.JWTSecret))
	if err != nil {
		return nil, err
	}

	// Refresh token (30d)
	refreshClaims := middleware.Claims{
		UserID: user.ID.String(),
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshString, err := refreshToken.SignedString([]byte(s.cfg.JWTSecret))
	if err != nil {
		return nil, err
	}

	return &model.AuthResponse{
		Token:        accessString,
		RefreshToken: refreshString,
		User:         *user,
	}, nil
}

func (s *AuthService) verifyCode(ctx context.Context, phone, code string) error {
	key := fmt.Sprintf("sms_code:%s", phone)
	stored, err := s.rdb.Get(ctx, key).Result()
	if err != nil || stored != code {
		return errors.New("验证码错误或已过期")
	}
	s.rdb.Del(ctx, key)
	return nil
}

func generateCode() string {
	n, _ := rand.Int(rand.Reader, big.NewInt(1000000))
	return fmt.Sprintf("%06d", n.Int64())
}
