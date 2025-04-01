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
