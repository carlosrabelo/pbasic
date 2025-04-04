package evaluator

import (
	"bytes"
	"pbasic/pbasic/internal/token"
	"strings"
	"testing"
)

func TestExecInput(t *testing.T) {
	out := &bytes.Buffer{}
	vars := NewVariableStore()

	// Default prompt "? "
	in := strings.NewReader("42\n")
	interp := NewInterpreter(in, out, nil, vars, 12345)

	tokens := []token.Token{
		{Type: token.INPUT, Literal: "INPUT"},
		{Type: token.IDENT, Literal: "A", VarName: 'A'},
		{Type: token.EOL},
	}
	res := interp.ExecuteStatement(tokens)
	if res != ExecOk {
		t.Errorf("INPUT got %v, want ExecOk", res)
	}
	if out.String() != "? " {
		t.Errorf("INPUT default prompt got %q, want '? '", out.String())
	}
	if val := vars.Get('A'); val != 42 {
		t.Errorf("Variable A got %d, want 42", val)
	}

	// Custom prompt string
	out.Reset()
	in = strings.NewReader("999\n")
	interp.In = in

	tokens = []token.Token{
		{Type: token.INPUT, Literal: "INPUT"},
		{Type: token.STRING, Literal: "ENTER N: "},
		{Type: token.SEMICOLON, Literal: ";"},
		{Type: token.IDENT, Literal: "B", VarName: 'B'},
		{Type: token.EOL},
	}
	res = interp.ExecuteStatement(tokens)
	if res != ExecOk {
		t.Errorf("INPUT with prompt got %v, want ExecOk", res)
	}
	if out.String() != "ENTER N: " {
		t.Errorf("INPUT prompt output got %q, want 'ENTER N: '", out.String())
	}
	if val := vars.Get('B'); val != 999 {
		t.Errorf("Variable B got %d, want 999", val)
	}

	// Missing semicolon in custom prompt
	out.Reset()
	tokens = []token.Token{
		{Type: token.INPUT, Literal: "INPUT"},
		{Type: token.STRING, Literal: "BAD: "},
		{Type: token.IDENT, Literal: "C", VarName: 'C'},
		{Type: token.EOL},
	}
	res = interp.ExecuteStatement(tokens)
	if res != ExecSyntaxError {
		t.Errorf("INPUT missing semicolon got %v, want ExecSyntaxError", res)
	}
}
