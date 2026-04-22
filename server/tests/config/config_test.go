package config_test

import (
	"os"
	"testing"

	"github.com/douhuajizhang/server/internal/config"
)

func TestConfig_DefaultValues(t *testing.T) {
	// Clear any env vars that might override defaults
	envVars := []string{"PORT", "DATABASE_URL", "REDIS_ADDR", "REDIS_PASSWORD", "JWT_SECRET"}
	saved := make(map[string]string)
	for _, key := range envVars {
		if v, ok := os.LookupEnv(key); ok {
			saved[key] = v
			os.Unsetenv(key)
		}
	}
	defer func() {
		for k, v := range saved {
			os.Setenv(k, v)
		}
	}()

	cfg := config.Load()

	if cfg.Port != "8080" {
		t.Errorf("expected default port 8080, got %s", cfg.Port)
	}
	if cfg.RedisAddr != "localhost:6379" {
		t.Errorf("expected default redis addr localhost:6379, got %s", cfg.RedisAddr)
	}
	if cfg.RedisDB != 0 {
		t.Errorf("expected default redis DB 0, got %d", cfg.RedisDB)
	}
	if cfg.JWTExpiry != 72 {
		t.Errorf("expected JWT expiry 72h, got %d", cfg.JWTExpiry)
	}
	if cfg.JWTSecret == "" {
		t.Error("expected non-empty default JWT secret")
	}
	if cfg.DatabaseURL == "" {
		t.Error("expected non-empty default database URL")
	}
}

func TestConfig_EnvOverride_Port(t *testing.T) {
	old, hasOld := os.LookupEnv("PORT")
	os.Setenv("PORT", "3000")
	defer func() {
		if hasOld {
			os.Setenv("PORT", old)
		} else {
			os.Unsetenv("PORT")
		}
	}()

	cfg := config.Load()
	if cfg.Port != "3000" {
		t.Errorf("expected port 3000, got %s", cfg.Port)
	}
}

func TestConfig_EnvOverride_JWTSecret(t *testing.T) {
	old, hasOld := os.LookupEnv("JWT_SECRET")
	os.Setenv("JWT_SECRET", "my-production-secret")
	defer func() {
		if hasOld {
			os.Setenv("JWT_SECRET", old)
		} else {
			os.Unsetenv("JWT_SECRET")
		}
	}()

	cfg := config.Load()
	if cfg.JWTSecret != "my-production-secret" {
		t.Errorf("expected JWT secret 'my-production-secret', got %s", cfg.JWTSecret)
	}
}

func TestConfig_EnvOverride_DatabaseURL(t *testing.T) {
	old, hasOld := os.LookupEnv("DATABASE_URL")
	os.Setenv("DATABASE_URL", "postgres://prod:pass@db:5432/prod")
	defer func() {
		if hasOld {
			os.Setenv("DATABASE_URL", old)
		} else {
			os.Unsetenv("DATABASE_URL")
		}
	}()

	cfg := config.Load()
	if cfg.DatabaseURL != "postgres://prod:pass@db:5432/prod" {
		t.Errorf("expected overridden DB URL, got %s", cfg.DatabaseURL)
	}
}

func TestConfig_EnvOverride_Redis(t *testing.T) {
	oldAddr, hasAddr := os.LookupEnv("REDIS_ADDR")
	oldPwd, hasPwd := os.LookupEnv("REDIS_PASSWORD")
	os.Setenv("REDIS_ADDR", "redis.prod:6380")
	os.Setenv("REDIS_PASSWORD", "redis-secret")
	defer func() {
		if hasAddr {
			os.Setenv("REDIS_ADDR", oldAddr)
		} else {
			os.Unsetenv("REDIS_ADDR")
		}
		if hasPwd {
			os.Setenv("REDIS_PASSWORD", oldPwd)
		} else {
			os.Unsetenv("REDIS_PASSWORD")
		}
	}()

	cfg := config.Load()
	if cfg.RedisAddr != "redis.prod:6380" {
		t.Errorf("expected redis addr redis.prod:6380, got %s", cfg.RedisAddr)
	}
	if cfg.RedisPassword != "redis-secret" {
		t.Errorf("expected redis password, got %s", cfg.RedisPassword)
	}
}

func TestConfig_WechatDefaults(t *testing.T) {
	old1, has1 := os.LookupEnv("WECHAT_APP_ID")
	old2, has2 := os.LookupEnv("WECHAT_SECRET")
	os.Unsetenv("WECHAT_APP_ID")
	os.Unsetenv("WECHAT_SECRET")
	defer func() {
		if has1 {
			os.Setenv("WECHAT_APP_ID", old1)
		}
		if has2 {
			os.Setenv("WECHAT_SECRET", old2)
		}
	}()

	cfg := config.Load()
	if cfg.WechatAppID != "" {
		t.Errorf("expected empty wechat app id, got %s", cfg.WechatAppID)
	}
	if cfg.WechatSecret != "" {
		t.Errorf("expected empty wechat secret, got %s", cfg.WechatSecret)
	}
}

func TestConfig_OSSDefaults(t *testing.T) {
	old1, has1 := os.LookupEnv("OSS_BUCKET")
	old2, has2 := os.LookupEnv("OSS_ENDPOINT")
	os.Unsetenv("OSS_BUCKET")
	os.Unsetenv("OSS_ENDPOINT")
	defer func() {
		if has1 {
			os.Setenv("OSS_BUCKET", old1)
		}
		if has2 {
			os.Setenv("OSS_ENDPOINT", old2)
		}
	}()

	cfg := config.Load()
	if cfg.OSSBucket != "" {
		t.Errorf("expected empty OSS bucket, got %s", cfg.OSSBucket)
	}
	if cfg.OSSEndpoint != "" {
		t.Errorf("expected empty OSS endpoint, got %s", cfg.OSSEndpoint)
	}
}
