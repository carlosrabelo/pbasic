package repl

import (
	"bufio"
	"bytes"
	"strings"
	"testing"
)

func TestClassifyLine(t *testing.T) {
	tests := []struct {
		input      string
		wantType   LineType
		wantLineNo uint16
		wantRest   string
	}{
		{"10 PRINT \"HI\"", LineNumbered, 10, "PRINT \"HI\""},
		{"65535 END", LineNumbered, 65535, "END"},
		{"PRINT 123", LineImmediate, 0, "PRINT 123"},
		{"   ", LineEmpty, 0, ""},
		{"0 INVALID", LineImmediate, 0, "0 INVALID"},
	}

	for _, tt := range tests {
		got := ClassifyLine(tt.input)
		if got.Type != tt.wantType || got.LineNumber != tt.wantLineNo || got.Content != tt.wantRest {
			t.Errorf("ClassifyLine(%q) = {%v, %d, %q}, want {%v, %d, %q}",
				tt.input, got.Type, got.LineNumber, got.Content, tt.wantType, tt.wantLineNo, tt.wantRest)
		}
	}
}

func TestREPLStart(t *testing.T) {
	t.Run("dispatches numbered and immediate lines then exits", func(t *testing.T) {
		input := "10 PRINT 1\nPRINT 2\nEXIT\n"
		var out bytes.Buffer
		reader := bufio.NewReader(strings.NewReader(input))

		r := NewREPL(reader, &out)

		var numberedLines []struct {
			num     uint16
			content string
		}
		var immediateLines []string

		r.SetNumberedHandler(func(num uint16, content string) {
			numberedLines = append(numberedLines, struct {
				num     uint16
				content string
			}{num, content})
		})

		r.SetImmediateHandler(func(content string) bool {
			immediateLines = append(immediateLines, content)
			return true
		})

		r.Start()

		if out.String() != "> > > " {
			t.Errorf("prompt output got %q, want \"> > > \"", out.String())
		}

		if len(numberedLines) != 1 || numberedLines[0].num != 10 || numberedLines[0].content != "PRINT 1" {
			t.Errorf("unexpected numbered lines: %+v", numberedLines)
		}

		if len(immediateLines) != 1 || immediateLines[0] != "PRINT 2" {
			t.Errorf("unexpected immediate lines: %+v", immediateLines)
		}
	})
}
