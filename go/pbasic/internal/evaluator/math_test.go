package evaluator

import (
	"testing"
)

func TestMul16(t *testing.T) {
	tests := []struct {
		name string
		a, b uint16
		want uint16
	}{
		{"zero times anything", 0, 1234, 0},
		{"simple multiplication", 100, 20, 2000},
		{"exact 16-bit boundary", 256, 256, 0}, // 65536 & 0xFFFF == 0
		{"overflow truncation", 1000, 70, 4464}, // 70000 & 0xFFFF = 4464
		{"max uint16 product", 0xFFFF, 2, 0xFFFE},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := Mul16(tt.a, tt.b)
			if got != tt.want {
				t.Errorf("Mul16(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
			}
		})
	}
}
