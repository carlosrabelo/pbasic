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
