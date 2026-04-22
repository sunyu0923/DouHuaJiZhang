package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/douhuajizhang/server/internal/middleware"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

func init() {
	gin.SetMode(gin.TestMode)
}

const testJWTSecret = "test-secret-key-for-unit-tests"

func generateTestToken(userID string, tokenType string, expiresAt time.Time) string {
	claims := middleware.Claims{
		UserID:    userID,
		TokenType: tokenType,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	str, _ := token.SignedString([]byte(testJWTSecret))
	return str
}

// ============ AuthRequired Tests ============

func TestAuthRequired_NoHeader(t *testing.T) {
	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestAuthRequired_EmptyHeader(t *testing.T) {
	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestAuthRequired_InvalidFormat_NoBearerPrefix(t *testing.T) {
	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "InvalidToken")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestAuthRequired_InvalidFormat_BasicAuth(t *testing.T) {
	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Basic dXNlcjpwYXNz")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 for Basic auth, got %d", w.Code)
	}
}

func TestAuthRequired_ExpiredToken(t *testing.T) {
	token := generateTestToken(uuid.New().String(), "access", time.Now().Add(-1*time.Hour))
	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestAuthRequired_RefreshTokenRejected(t *testing.T) {
	token := generateTestToken(uuid.New().String(), "refresh", time.Now().Add(1*time.Hour))
	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 for refresh token, got %d", w.Code)
	}
}

func TestAuthRequired_InvalidUserID(t *testing.T) {
	token := generateTestToken("not-a-uuid", "access", time.Now().Add(1*time.Hour))
	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401 for invalid user ID, got %d", w.Code)
	}
}

func TestAuthRequired_ValidToken(t *testing.T) {
	userID := uuid.New()
	token := generateTestToken(userID.String(), "access", time.Now().Add(1*time.Hour))
	var capturedID uuid.UUID

	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) {
		id, ok := middleware.GetUserID(c)
		if !ok {
			t.Error("expected userID in context")
		}
		capturedID = id
		c.JSON(200, gin.H{"ok": true})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", w.Code)
	}
	if capturedID != userID {
		t.Errorf("expected userID %s, got %s", userID, capturedID)
	}
}

func TestAuthRequired_WrongSecret(t *testing.T) {
	token := generateTestToken(uuid.New().String(), "access", time.Now().Add(1*time.Hour))
	r := gin.New()
	r.Use(middleware.AuthRequired("different-secret"))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestAuthRequired_BearerCaseInsensitive(t *testing.T) {
	userID := uuid.New()
	token := generateTestToken(userID.String(), "access", time.Now().Add(1*time.Hour))

	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "bearer "+token)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected 200 for lowercase 'bearer', got %d", w.Code)
	}
}

func TestAuthRequired_MalformedJWT(t *testing.T) {
	r := gin.New()
	r.Use(middleware.AuthRequired(testJWTSecret))
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("Authorization", "Bearer not.a.valid.jwt.token")
	r.ServeHTTP(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

// ============ GetUserID Tests ============

func TestGetUserID_NotSet(t *testing.T) {
	r := gin.New()
	r.GET("/test", func(c *gin.Context) {
		_, ok := middleware.GetUserID(c)
		if ok {
			t.Error("expected false when userID not set")
		}
		c.JSON(200, gin.H{})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	r.ServeHTTP(w, req)
}

func TestGetUserID_WrongType(t *testing.T) {
	r := gin.New()
	r.GET("/test", func(c *gin.Context) {
		c.Set("userID", "not-a-uuid-type")
		_, ok := middleware.GetUserID(c)
		if ok {
			t.Error("expected false when userID is wrong type")
		}
		c.JSON(200, gin.H{})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	r.ServeHTTP(w, req)
}

func TestGetUserID_ValidUUID(t *testing.T) {
	expected := uuid.New()
	r := gin.New()
	r.GET("/test", func(c *gin.Context) {
		c.Set("userID", expected)
		id, ok := middleware.GetUserID(c)
		if !ok {
			t.Fatal("expected true")
		}
		if id != expected {
			t.Errorf("expected %s, got %s", expected, id)
		}
		c.JSON(200, gin.H{})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	r.ServeHTTP(w, req)
}

// ============ CORS Tests ============

func TestCORS_SetsHeaders(t *testing.T) {
	r := gin.New()
	r.Use(middleware.CORS())
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	r.ServeHTTP(w, req)

	if w.Code != 200 {
		t.Errorf("expected 200, got %d", w.Code)
	}
	if w.Header().Get("Access-Control-Allow-Origin") != "*" {
		t.Error("missing Access-Control-Allow-Origin header")
	}
	if w.Header().Get("Access-Control-Allow-Methods") == "" {
		t.Error("missing Access-Control-Allow-Methods header")
	}
	if w.Header().Get("Access-Control-Allow-Headers") == "" {
		t.Error("missing Access-Control-Allow-Headers header")
	}
	if w.Header().Get("Access-Control-Max-Age") != "86400" {
		t.Errorf("expected max-age 86400, got %s", w.Header().Get("Access-Control-Max-Age"))
	}
}

func TestCORS_OptionsPreflight(t *testing.T) {
	r := gin.New()
	r.Use(middleware.CORS())
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("OPTIONS", "/test", nil)
	r.ServeHTTP(w, req)

	if w.Code != http.StatusNoContent {
		t.Errorf("expected 204 for OPTIONS, got %d", w.Code)
	}
}

func TestCORS_PostRequest(t *testing.T) {
	r := gin.New()
	r.Use(middleware.CORS())
	r.POST("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/test", nil)
	r.ServeHTTP(w, req)

	if w.Header().Get("Access-Control-Allow-Origin") != "*" {
		t.Error("CORS headers should be set on POST requests too")
	}
}

// ============ RequestID Tests ============

func TestRequestID_GeneratesNew(t *testing.T) {
	r := gin.New()
	r.Use(middleware.RequestID())
	r.GET("/test", func(c *gin.Context) {
		rid, exists := c.Get("requestID")
		if !exists || rid == "" {
			t.Error("expected requestID to be set")
		}
		c.JSON(200, gin.H{"ok": true})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	r.ServeHTTP(w, req)

	if w.Header().Get("X-Request-ID") == "" {
		t.Error("expected X-Request-ID response header")
	}
}

func TestRequestID_UsesExisting(t *testing.T) {
	r := gin.New()
	r.Use(middleware.RequestID())
	r.GET("/test", func(c *gin.Context) {
		rid, _ := c.Get("requestID")
		if rid != "my-custom-id" {
			t.Errorf("expected 'my-custom-id', got %v", rid)
		}
		c.JSON(200, gin.H{"ok": true})
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/test", nil)
	req.Header.Set("X-Request-ID", "my-custom-id")
	r.ServeHTTP(w, req)

	if w.Header().Get("X-Request-ID") != "my-custom-id" {
		t.Errorf("expected X-Request-ID 'my-custom-id', got %s", w.Header().Get("X-Request-ID"))
	}
}

func TestRequestID_UniquePerRequest(t *testing.T) {
	r := gin.New()
	r.Use(middleware.RequestID())
	r.GET("/test", func(c *gin.Context) { c.JSON(200, gin.H{"ok": true}) })

	w1 := httptest.NewRecorder()
	req1, _ := http.NewRequest("GET", "/test", nil)
	r.ServeHTTP(w1, req1)

	w2 := httptest.NewRecorder()
	req2, _ := http.NewRequest("GET", "/test", nil)
	r.ServeHTTP(w2, req2)

	id1 := w1.Header().Get("X-Request-ID")
	id2 := w2.Header().Get("X-Request-ID")
	if id1 == id2 {
		t.Error("expected different request IDs for different requests")
	}
}

// ============ Claims Tests ============

func TestClaims_Fields(t *testing.T) {
	claims := middleware.Claims{
		UserID:    uuid.New().String(),
		TokenType: "access",
	}
	if claims.TokenType != "access" {
		t.Errorf("expected token_type access, got %s", claims.TokenType)
	}
}
