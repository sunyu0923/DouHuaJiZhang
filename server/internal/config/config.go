package config

import "os"

type Config struct {
	Port          string
	DatabaseURL   string
	RedisAddr     string
	RedisPassword string
	RedisDB       int
	JWTSecret     string
	JWTExpiry     int // hours
	WechatAppID   string
	WechatSecret  string
	OSSBucket     string
	OSSEndpoint   string
}

func Load() *Config {
	return &Config{
		Port:          getEnv("PORT", "8080"),
		DatabaseURL:   getEnv("DATABASE_URL", "postgres://douhua:douhua@localhost:5432/douhuajizhang?sslmode=disable"),
		RedisAddr:     getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       0,
		JWTSecret:     getEnv("JWT_SECRET", "douhua-secret-change-in-production"),
		JWTExpiry:     72,
		WechatAppID:   getEnv("WECHAT_APP_ID", ""),
		WechatSecret:  getEnv("WECHAT_SECRET", ""),
		OSSBucket:     getEnv("OSS_BUCKET", ""),
		OSSEndpoint:   getEnv("OSS_ENDPOINT", ""),
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
