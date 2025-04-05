package ast

import (
	"bytes"
	"strings"
	"testing"

	"pbasic/pbasic/internal/token"
)

func TestASTStoreContract(t *testing.T) {
	prog := NewProgramStore()

	// Verify sequential line insertion and sorting
	prog.SetLine(50, []token.Token{{Type: token.PRINT, Literal: "PRINT"}, {Type: token.STRING, Literal: "50"}}, "PRINT \"50\"")
	prog.SetLine(10, []token.Token{{Type: token.PRINT, Literal: "PRINT"}, {Type: token.STRING, Literal: "10"}}, "PRINT \"10\"")
	prog.SetLine(30, []token.Token{{Type: token.PRINT, Literal: "PRINT"}, {Type: token.STRING, Literal: "30"}}, "PRINT \"30\"")

	// Verify listing output
	out := &bytes.Buffer{}
	prog.List(out)
	listing := out.String()
	lines := strings.Split(strings.TrimSpace(listing), "\n")
	if len(lines) != 3 {
		t.Fatalf("expected 3 lines in listing, got %d", len(lines))
	}
	if !strings.HasPrefix(lines[0], "10") || !strings.HasPrefix(lines[1], "30") || !strings.HasPrefix(lines[2], "50") {
		t.Errorf("lines not sorted in listing: %q", listing)
	}

	// Verify replacement
	prog.SetLine(30, []token.Token{{Type: token.PRINT, Literal: "PRINT"}, {Type: token.STRING, Literal: "30 NEW"}}, "PRINT \"30 NEW\"")
	out.Reset()
	prog.List(out)
	if !strings.Contains(out.String(), "30 PRINT") {
		t.Errorf("replacement line missing in listing: %q", out.String())
	}

	// Verify deletion
	prog.RemoveLine(30)
	out.Reset()
	prog.List(out)
	if strings.Contains(out.String(), "30") {
		t.Errorf("line 30 still present after deletion: %q", out.String())
	}
}
