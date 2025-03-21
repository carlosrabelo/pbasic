package repl

import (
	"bytes"
	"testing"
)

func TestConsoleIOHelpers(t *testing.T) {
	t.Run("PrintStr outputs exact string", func(t *testing.T) {
		var buf bytes.Buffer
		PrintStr(&buf, "Hello PBasic")
		if got := buf.String(); got != "Hello PBasic" {
			t.Errorf("PrintStr got %q, want %q", got, "Hello PBasic")
		}
	})

	t.Run("PrintNumber outputs signed 32-bit integers", func(t *testing.T) {
		tests := []struct {
			input int32
			want  string
		}{
			{0, "0"},
			{42, "42"},
			{-100000, "-100000"},
			{1000000, "1000000"},
		}

		for _, tt := range tests {
			var buf bytes.Buffer
			PrintNumber(&buf, tt.input)
			if got := buf.String(); got != tt.want {
				t.Errorf("PrintNumber(%d) got %q, want %q", tt.input, got, tt.want)
			}
		}
	})

	t.Run("PrintCRLF outputs newline", func(t *testing.T) {
		var buf bytes.Buffer
		PrintCRLF(&buf)
		if got := buf.String(); got != "\n" {
			t.Errorf("PrintCRLF got %q, want %q", got, "\n")
		}
	})

	t.Run("PrintOK outputs OK followed by newline", func(t *testing.T) {
		var buf bytes.Buffer
		PrintOK(&buf)
		if got := buf.String(); got != "OK\n" {
			t.Errorf("PrintOK got %q, want %q", got, "OK\n")
		}
	})
}
