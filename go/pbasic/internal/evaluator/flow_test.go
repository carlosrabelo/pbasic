package evaluator

import (
	"bytes"
	"pbasic/pbasic/internal/ast"
	"pbasic/pbasic/internal/token"
	"testing"
)

func TestRunProgram(t *testing.T) {
	out := &bytes.Buffer{}
	prog := ast.NewProgramStore()
	vars := NewVariableStore()
	interp := NewInterpreter(nil, out, prog, vars, 12345)

	// RUN on empty program emits ?NO PROGRAM
	out.Reset()
	interp.ExecuteStatement([]token.Token{{Type: token.RUN, Literal: "RUN"}, {Type: token.EOL}})
	if out.String() != "?NO PROGRAM\n" {
		t.Errorf("RUN empty got %q, want '?NO PROGRAM\\n'", out.String())
	}

	// Sequential execution of multiple lines
	prog.SetLine(10, []token.Token{
		{Type: token.PRINT, Literal: "PRINT"},
		{Type: token.STRING, Literal: "FIRST"},
		{Type: token.EOL},
	}, "PRINT \"FIRST\"")

	prog.SetLine(20, []token.Token{
		{Type: token.PRINT, Literal: "PRINT"},
		{Type: token.STRING, Literal: "SECOND"},
		{Type: token.EOL},
	}, "PRINT \"SECOND\"")

	out.Reset()
	interp.RunProgram()
	if out.String() != "FIRST\nSECOND\n" {
		t.Errorf("RunProgram() got %q, want 'FIRST\\nSECOND\\n'", out.String())
	}

	// Interrupt handling during RUN stops loop without error
	called := false
	interp.CheckInterrupted = func() bool {
		if !called {
			called = true
			return true
		}
		return false
	}
	out.Reset()
	interp.RunProgram()
	if !interp.Halted {
		t.Errorf("expected interp.Halted to be true after interrupt")
	}
}
