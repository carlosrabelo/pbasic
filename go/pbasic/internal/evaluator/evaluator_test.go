package evaluator

import (
	"pbasic/pbasic/internal/token"
	"testing"
)

func TestEvalFactor(t *testing.T) {
	vars := NewVariableStore()
	vars.Set('A', 123)
	vars.Set('B', -456)

	// Literal number
	tokens := []token.Token{
		{Type: token.NUMBER, Literal: "42", NumberVal: 42},
		{Type: token.EOL, Literal: "\n"},
	}
	ev := NewEvaluator(tokens, vars, nil, nil)
	if val := ev.EvalExpression(); val != 42 {
		t.Errorf("EvalExpression() for literal got %d, want 42", val)
	}

	// Variable
	tokens = []token.Token{
		{Type: token.IDENT, Literal: "A", VarName: 'A'},
		{Type: token.EOL, Literal: "\n"},
	}
	ev = NewEvaluator(tokens, vars, nil, nil)
	if val := ev.EvalExpression(); val != 123 {
		t.Errorf("EvalExpression() for variable A got %d, want 123", val)
	}

	// Unary minus on variable
	tokens = []token.Token{
		{Type: token.MINUS, Literal: "-"},
		{Type: token.IDENT, Literal: "A", VarName: 'A'},
		{Type: token.EOL, Literal: "\n"},
	}
	ev = NewEvaluator(tokens, vars, nil, nil)
	if val := ev.EvalExpression(); val != -123 {
		t.Errorf("EvalExpression() for -A got %d, want -123", val)
	}

	// Parentheses
	tokens = []token.Token{
		{Type: token.LPAREN, Literal: "("},
		{Type: token.NUMBER, Literal: "99", NumberVal: 99},
		{Type: token.RPAREN, Literal: ")"},
		{Type: token.EOL, Literal: "\n"},
	}
	ev = NewEvaluator(tokens, vars, nil, nil)
	if val := ev.EvalExpression(); val != 99 {
		t.Errorf("EvalExpression() for (99) got %d, want 99", val)
	}
}

func TestBuiltinFunctions(t *testing.T) {
	// ABS
	tokens := []token.Token{
		{Type: token.ABS, Literal: "ABS"},
		{Type: token.LPAREN, Literal: "("},
		{Type: token.MINUS, Literal: "-"},
		{Type: token.NUMBER, Literal: "50", NumberVal: 50},
		{Type: token.RPAREN, Literal: ")"},
		{Type: token.EOL, Literal: "\n"},
	}
	ev := NewEvaluator(tokens, nil, nil, nil)
	if val := ev.EvalExpression(); val != 50 {
		t.Errorf("ABS(-50) got %d, want 50", val)
	}

	// FREE
	tokens = []token.Token{
		{Type: token.FREE, Literal: "FREE"},
		{Type: token.EOL, Literal: "\n"},
	}
	ev = NewEvaluator(tokens, nil, nil, nil)
	if val := ev.EvalExpression(); val != 16384 {
		t.Errorf("FREE without program got %d, want 16384", val)
	}

	// RND
	seed := uint16(12345)
	tokens = []token.Token{
		{Type: token.RND, Literal: "RND"},
		{Type: token.LPAREN, Literal: "("},
		{Type: token.NUMBER, Literal: "10", NumberVal: 10},
		{Type: token.RPAREN, Literal: ")"},
		{Type: token.EOL, Literal: "\n"},
	}
	ev = NewEvaluator(tokens, nil, nil, &seed)
	rndVal := ev.EvalExpression()
	if rndVal < 1 || rndVal > 10 {
		t.Errorf("RND(10) got %d, want between 1 and 10", rndVal)
	}
}

func TestEvalTerm(t *testing.T) {
	// 6 * 7
	tokens := []token.Token{
		{Type: token.NUMBER, Literal: "6", NumberVal: 6},
		{Type: token.ASTERISK, Literal: "*"},
		{Type: token.NUMBER, Literal: "7", NumberVal: 7},
		{Type: token.EOL, Literal: "\n"},
	}
	ev := NewEvaluator(tokens, nil, nil, nil)
	if val := ev.EvalExpression(); val != 42 {
		t.Errorf("6 * 7 got %d, want 42", val)
	}

	// 100 / 5
	tokens = []token.Token{
		{Type: token.NUMBER, Literal: "100", NumberVal: 100},
		{Type: token.SLASH, Literal: "/"},
		{Type: token.NUMBER, Literal: "5", NumberVal: 5},
		{Type: token.EOL, Literal: "\n"},
	}
	ev = NewEvaluator(tokens, nil, nil, nil)
	if val := ev.EvalExpression(); val != 20 {
		t.Errorf("100 / 5 got %d, want 20", val)
	}

	// 100 / 0 returns 65535
	tokens = []token.Token{
		{Type: token.NUMBER, Literal: "100", NumberVal: 100},
		{Type: token.SLASH, Literal: "/"},
		{Type: token.NUMBER, Literal: "0", NumberVal: 0},
		{Type: token.EOL, Literal: "\n"},
	}
	ev = NewEvaluator(tokens, nil, nil, nil)
	if val := ev.EvalExpression(); val != 65535 {
		t.Errorf("100 / 0 got %d, want 65535", val)
	}
}

func TestEvalExpression(t *testing.T) {
	// Precedence: 2 + 3 * 4 == 14
	tokens := []token.Token{
		{Type: token.NUMBER, Literal: "2", NumberVal: 2},
		{Type: token.PLUS, Literal: "+"},
		{Type: token.NUMBER, Literal: "3", NumberVal: 3},
		{Type: token.ASTERISK, Literal: "*"},
		{Type: token.NUMBER, Literal: "4", NumberVal: 4},
		{Type: token.EOL, Literal: "\n"},
	}
	ev := NewEvaluator(tokens, nil, nil, nil)
	if val := ev.EvalExpression(); val != 14 {
		t.Errorf("2 + 3 * 4 got %d, want 14", val)
	}

	// Parentheses override precedence: (2 + 3) * 4 == 20
	tokens = []token.Token{
		{Type: token.LPAREN, Literal: "("},
		{Type: token.NUMBER, Literal: "2", NumberVal: 2},
		{Type: token.PLUS, Literal: "+"},
		{Type: token.NUMBER, Literal: "3", NumberVal: 3},
		{Type: token.RPAREN, Literal: ")"},
		{Type: token.ASTERISK, Literal: "*"},
		{Type: token.NUMBER, Literal: "4", NumberVal: 4},
		{Type: token.EOL, Literal: "\n"},
	}
	ev = NewEvaluator(tokens, nil, nil, nil)
	if val := ev.EvalExpression(); val != 20 {
		t.Errorf("(2 + 3) * 4 got %d, want 20", val)
	}

	// Left associativity: 10 - 3 - 2 == 5
	tokens = []token.Token{
		{Type: token.NUMBER, Literal: "10", NumberVal: 10},
		{Type: token.MINUS, Literal: "-"},
		{Type: token.NUMBER, Literal: "3", NumberVal: 3},
		{Type: token.MINUS, Literal: "-"},
		{Type: token.NUMBER, Literal: "2", NumberVal: 2},
		{Type: token.EOL, Literal: "\n"},
	}
	ev = NewEvaluator(tokens, nil, nil, nil)
	if val := ev.EvalExpression(); val != 5 {
		t.Errorf("10 - 3 - 2 got %d, want 5", val)
	}
}
