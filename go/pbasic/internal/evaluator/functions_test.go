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

func TestPRNGAndRND(t *testing.T) {
	seed := uint16(12345)
	firstVal := NextRND(&seed)
	expectedVal := uint16((uint32(12345)*25173 + 13849) & 0xFFFF)
	if firstVal != expectedVal {
		t.Errorf("NextRND got %d, want %d", firstVal, expectedVal)
	}

	// RND(0) returns raw 16-bit word
	seed = 12345
	tokens := []token.Token{
		{Type: token.RND, Literal: "RND"},
		{Type: token.LPAREN, Literal: "("},
		{Type: token.NUMBER, NumberVal: 0},
		{Type: token.RPAREN, Literal: ")"},
		{Type: token.EOL},
	}
	ev := NewEvaluator(tokens, nil, nil, &seed)
	res := ev.EvalExpression()
	if uint16(res) != expectedVal {
		t.Errorf("RND(0) got %d, want %d", res, expectedVal)
	}

	// RND(6) returns 1..6
	for i := 0; i < 50; i++ {
		tokens = []token.Token{
			{Type: token.RND, Literal: "RND"},
			{Type: token.LPAREN, Literal: "("},
			{Type: token.NUMBER, NumberVal: 6},
			{Type: token.RPAREN, Literal: ")"},
			{Type: token.EOL},
		}
		ev = NewEvaluator(tokens, nil, nil, &seed)
		dice := ev.EvalExpression()
		if dice < 1 || dice > 6 {
			t.Errorf("RND(6) returned out-of-range value %d", dice)
		}
	}
}

func TestABSFunction(t *testing.T) {
	if got := Abs32(-15); got != 15 {
		t.Errorf("Abs32(-15) got %d, want 15", got)
	}
	if got := Abs32(15); got != 15 {
		t.Errorf("Abs32(15) got %d, want 15", got)
	}
	if got := Abs32(0); got != 0 {
		t.Errorf("Abs32(0) got %d, want 0", got)
	}

	tests := []struct {
		arg  int32
		want int32
	}{
		{-15, 15},
		{15, 15},
		{0, 0},
		{-1000000, 1000000},
	}

	for _, tt := range tests {
		tokens := []token.Token{
			{Type: token.ABS, Literal: "ABS"},
			{Type: token.LPAREN, Literal: "("},
			{Type: token.NUMBER, NumberVal: tt.arg},
			{Type: token.RPAREN, Literal: ")"},
			{Type: token.EOL},
		}
		ev := NewEvaluator(tokens, nil, nil, nil)
		if got := ev.EvalExpression(); got != tt.want {
			t.Errorf("ABS(%d) got %d, want %d", tt.arg, got, tt.want)
		}
	}
}
