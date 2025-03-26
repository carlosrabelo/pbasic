package lexer

import (
	"testing"
)

func TestFormatTokens(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{`PRINT "HELLO"`, `PRINT "HELLO"`},
		{`LET A = 42`, `LET A = 42`},
		{`IF A > 10 THEN GOTO 100`, `IF A > 10 THEN GOTO 100`},
		{`REM TEST COMMENT`, `REM TEST COMMENT`},
	}

	for _, tt := range tests {
		tokens := Tokenize(tt.input)
		got := FormatTokens(tokens)
		if got != tt.want {
			t.Errorf("FormatTokens(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}
