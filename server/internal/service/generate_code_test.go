package service

import (
	"testing"
)

// generateCode 是未导出函数，必须在包内测试

func TestGenerateCode_Length(t *testing.T) {
	for i := 0; i < 100; i++ {
		code := generateCode()
		if len(code) != 6 {
			t.Fatalf("expected 6-digit code, got length %d: %s", len(code), code)
		}
	}
}

func TestGenerateCode_NumericOnly(t *testing.T) {
	for i := 0; i < 50; i++ {
		code := generateCode()
		for _, c := range code {
			if c < '0' || c > '9' {
				t.Fatalf("expected numeric-only code, got char '%c' in %s", c, code)
			}
		}
	}
}

func TestGenerateCode_Randomness(t *testing.T) {
	codes := make(map[string]bool)
	for i := 0; i < 20; i++ {
		codes[generateCode()] = true
	}
	if len(codes) < 5 {
		t.Errorf("expected variety in codes but only got %d unique out of 20", len(codes))
	}
}
