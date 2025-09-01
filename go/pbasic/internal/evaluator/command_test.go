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

func TestExecLet(t *testing.T) {
	out := &bytes.Buffer{}
	vars := NewVariableStore()
	interp := NewInterpreter(nil, out, nil, vars, 12345)

	// Explicit LET: LET A = 42
	tokens := []token.Token{
		{Type: token.LET, Literal: "LET"},
		{Type: token.IDENT, Literal: "A", VarName: 'A'},
		{Type: token.ASSIGN, Literal: "="},
		{Type: token.NUMBER, NumberVal: 42},
		{Type: token.EOL, Literal: "\n"},
	}
	res := interp.ExecuteStatement(tokens)
	if res != ExecOk {
		t.Errorf("LET statement got %v, want ExecOk", res)
	}
	if val := vars.Get('A'); val != 42 {
		t.Errorf("Variable A got %d, want 42", val)
	}

	// Implicit LET: B = 100 + 50
	tokens = []token.Token{
		{Type: token.IDENT, Literal: "B", VarName: 'B'},
		{Type: token.ASSIGN, Literal: "="},
		{Type: token.NUMBER, NumberVal: 100},
		{Type: token.PLUS, Literal: "+"},
		{Type: token.NUMBER, NumberVal: 50},
		{Type: token.EOL, Literal: "\n"},
	}
	res = interp.ExecuteStatement(tokens)
	if res != ExecOk {
		t.Errorf("Implicit LET got %v, want ExecOk", res)
	}
	if val := vars.Get('B'); val != 150 {
		t.Errorf("Variable B got %d, want 150", val)
	}

	// Syntax error missing '='
	tokens = []token.Token{
		{Type: token.LET, Literal: "LET"},
		{Type: token.IDENT, Literal: "C", VarName: 'C'},
		{Type: token.NUMBER, NumberVal: 10},
		{Type: token.EOL, Literal: "\n"},
	}
	res = interp.ExecuteStatement(tokens)
	if res != ExecSyntaxError {
		t.Errorf("Malformed LET got %v, want ExecSyntaxError", res)
	}
}

func TestExecNew(t *testing.T) {
	out := &bytes.Buffer{}
	vars := NewVariableStore()
	vars.Set('A', 99)
	vars.Set('Z', 88)

	prog := ast.NewProgramStore()
	prog.SetLine(10, []token.Token{{Type: token.PRINT, Literal: "PRINT"}}, "PRINT")

	interp := NewInterpreter(nil, out, prog, vars, 12345)

	tokens := []token.Token{
		{Type: token.NEW, Literal: "NEW"},
		{Type: token.EOL, Literal: "\n"},
	}
	res := interp.ExecuteStatement(tokens)
	if res != ExecOk {
		t.Errorf("NEW returned %v, want ExecOk", res)
	}

	if out.String() != "OK\n" {
		t.Errorf("NEW output got %q, want 'OK\\n'", out.String())
	}
	if !prog.Empty() {
		t.Errorf("expected prog to be empty after NEW")
	}
	if val := vars.Get('A'); val != 0 {
		t.Errorf("expected variable A to be 0 after NEW, got %d", val)
	}
	if val := vars.Get('Z'); val != 0 {
		t.Errorf("expected variable Z to be 0 after NEW, got %d", val)
	}
}
