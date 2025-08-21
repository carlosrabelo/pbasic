package repl

import (
	"bufio"
	"io"
	"strings"
	"testing"
)

func TestFoldCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{`print "hello world"`, `PRINT "hello world"`},
		{`let a = 10`, `LET A = 10`},
		{`"keep lower" and UPPER`, `"keep lower" AND UPPER`},
		{`print "hi ";: print "there"`, `PRINT "hi ";: PRINT "there"`},
		{`10 goto 20`, `10 GOTO 20`},
	}

	for _, tt := range tests {
		if got := FoldCase(tt.input); got != tt.want {
			t.Errorf("FoldCase(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestReadLine(t *testing.T) {
	t.Run("normalizes CRLF and applies fold_case", func(t *testing.T) {
		input := "print \"hello\"\r\nlet b = 2\n"
		reader := bufio.NewReader(strings.NewReader(input))

		l1, err := ReadLine(reader)
		if err != nil {
			t.Fatalf("unexpected error reading line 1: %v", err)
		}
		if l1 != `PRINT "hello"` {
			t.Errorf("line 1 got %q, want %q", l1, `PRINT "hello"`)
		}

		l2, err := ReadLine(reader)
		if err != nil {
			t.Fatalf("unexpected error reading line 2: %v", err)
		}
		if l2 != `LET B = 2` {
			t.Errorf("line 2 got %q, want %q", l2, `LET B = 2`)
		}

		_, err = ReadLine(reader)
		if err != io.EOF {
			t.Fatalf("expected EOF on third read, got %v", err)
		}
	})

	t.Run("handles line without trailing newline", func(t *testing.T) {
		input := `print "no newline"`
		reader := bufio.NewReader(strings.NewReader(input))

		l1, err := ReadLine(reader)
		if err != nil {
			t.Fatalf("unexpected error reading line: %v", err)
		}
		if l1 != `PRINT "no newline"` {
			t.Errorf("got %q, want %q", l1, `PRINT "no newline"`)
		}
	})
}
