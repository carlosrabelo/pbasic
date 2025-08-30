package evaluator

import (
	"bytes"
	"pbasic/pbasic/internal/ast"
	"pbasic/pbasic/internal/token"
	"strings"
	"testing"
)

func TestCommandDispatcherSkeleton(t *testing.T) {
	out := &bytes.Buffer{}
	prog := ast.NewProgramStore()
	vars := NewVariableStore()
	interp := NewInterpreter(nil, out, prog, vars, 12345)

	// Empty tokens
	if res := interp.ExecuteStatement([]token.Token{}); res != ExecOk {
		t.Errorf("empty tokens got %v, want ExecOk", res)
	}

	// EOL
	if res := interp.ExecuteStatement([]token.Token{{Type: token.EOL}}); res != ExecOk {
		t.Errorf("EOL got %v, want ExecOk", res)
	}

	// REM
	if res := interp.ExecuteStatement([]token.Token{{Type: token.REM, Literal: "this is a comment"}}); res != ExecOk {
		t.Errorf("REM got %v, want ExecOk", res)
	}

	// Unrecognized / syntax error
	out.Reset()
	if res := interp.ExecuteStatement([]token.Token{{Type: token.ILLEGAL, Literal: "@"}}); res != ExecSyntaxError {
		t.Errorf("ILLEGAL got %v, want ExecSyntaxError", res)
	}
	if !strings.Contains(out.String(), "?SYNTAX ERROR") {
		t.Errorf("output got %q, want '?SYNTAX ERROR'", out.String())
	}
}

func TestExecPrint(t *testing.T) {
	out := &bytes.Buffer{}
	vars := NewVariableStore()
	vars.Set('A', 42)
	interp := NewInterpreter(nil, out, nil, vars, 12345)

	// String literal
	out.Reset()
	tokens := []token.Token{
		{Type: token.PRINT, Literal: "PRINT"},
		{Type: token.STRING, Literal: "HELLO, WORLD!"},
		{Type: token.EOL, Literal: "\n"},
	}
	interp.ExecuteStatement(tokens)
	if out.String() != "HELLO, WORLD!\n" {
		t.Errorf("PRINT string got %q, want %q", out.String(), "HELLO, WORLD!\n")
	}

	// Comma spacing (8 spaces)
	out.Reset()
	tokens = []token.Token{
		{Type: token.PRINT, Literal: "PRINT"},
		{Type: token.NUMBER, NumberVal: 1},
		{Type: token.COMMA, Literal: ","},
		{Type: token.NUMBER, NumberVal: 2},
		{Type: token.EOL, Literal: "\n"},
	}
	interp.ExecuteStatement(tokens)
	if out.String() != "1        2\n" {
		t.Errorf("PRINT comma got %q, want %q", out.String(), "1        2\n")
	}

	// Semicolon newline suppression
	out.Reset()
	tokens = []token.Token{
		{Type: token.PRINT, Literal: "PRINT"},
		{Type: token.STRING, Literal: "HI "},
		{Type: token.SEMICOLON, Literal: ";"},
		{Type: token.EOL, Literal: "\n"},
	}
	interp.ExecuteStatement(tokens)
	if out.String() != "HI " {
		t.Errorf("PRINT semicolon got %q, want %q", out.String(), "HI ")
	}

	// Followed by another print
	tokens = []token.Token{
		{Type: token.PRINT, Literal: "PRINT"},
		{Type: token.STRING, Literal: "THERE"},
		{Type: token.EOL, Literal: "\n"},
	}
	interp.ExecuteStatement(tokens)
	if out.String() != "HI THERE\n" {
		t.Errorf("PRINT sequence got %q, want %q", out.String(), "HI THERE\n")
	}

	// Variable printing
	out.Reset()
	tokens = []token.Token{
		{Type: token.PRINT, Literal: "PRINT"},
		{Type: token.IDENT, Literal: "A", VarName: 'A'},
		{Type: token.EOL, Literal: "\n"},
	}
	interp.ExecuteStatement(tokens)
	if out.String() != "42\n" {
		t.Errorf("PRINT A got %q, want %q", out.String(), "42\n")
	}
}
