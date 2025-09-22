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
		{"exact 16-bit boundary", 256, 256, 0},  // 65536 & 0xFFFF == 0
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

func TestDiv16(t *testing.T) {
	tests := []struct {
		name string
		a, b uint16
		want uint16
	}{
		{"exact division", 100, 5, 20},
		{"integer truncation", 10, 3, 3},
		{"division by zero", 100, 0, 0xFFFF},
		{"zero divided by anything", 0, 42, 0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := Div16(tt.a, tt.b)
			if got != tt.want {
				t.Errorf("Div16(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
			}
		})
	}
}

func TestMod16(t *testing.T) {
	tests := []struct {
		name string
		a, b uint16
		want uint16
	}{
		{"exact remainder", 10, 3, 1},
		{"no remainder", 100, 5, 0},
		{"modulo by zero preserves dividend", 100, 0, 100},
		{"modulo by zero with zero", 0, 0, 0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := Mod16(tt.a, tt.b)
			if got != tt.want {
				t.Errorf("Mod16(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
			}
		})
	}
}

func Test32BitArithmetic(t *testing.T) {
	if got := Add32(1000000, 2000000); got != 3000000 {
		t.Errorf("Add32 got %d, want 3000000", got)
	}
	if got := Sub32(1000000, 2000000); got != -1000000 {
		t.Errorf("Sub32 got %d, want -1000000", got)
	}
	if got := Neg32(42); got != -42 {
		t.Errorf("Neg32(42) got %d, want -42", got)
	}
	if got := Neg32(-42); got != 42 {
		t.Errorf("Neg32(-42) got %d, want 42", got)
	}
}
