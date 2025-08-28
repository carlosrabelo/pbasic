package evaluator

import (
	"pbasic/pbasic/internal/ast"
	"pbasic/pbasic/internal/token"
)

// Evaluator parses and evaluates expressions and conditions from a token slice.
type Evaluator struct {
	tokens   []token.Token
	cursor   int
	vars     *VariableStore
	prog     *ast.ProgramStore
	randSeed *uint16
}

// NewEvaluator constructs an Evaluator instance.
func NewEvaluator(tokens []token.Token, vars *VariableStore, prog *ast.ProgramStore, seed *uint16) *Evaluator {
	return &Evaluator{
		tokens:   tokens,
		cursor:   0,
		vars:     vars,
		prog:     prog,
		randSeed: seed,
	}
}

func (e *Evaluator) isAtEnd() bool {
	return e.cursor >= len(e.tokens) ||
		e.tokens[e.cursor].Type == token.EOL ||
		e.tokens[e.cursor].Type == token.EOF
}

func (e *Evaluator) current() token.Token {
	if e.cursor < len(e.tokens) {
		return e.tokens[e.cursor]
	}
	return token.Token{Type: token.EOF}
}

func (e *Evaluator) advance() token.Token {
	if e.cursor < len(e.tokens) {
		tok := e.tokens[e.cursor]
		e.cursor++
		return tok
	}
	return token.Token{Type: token.EOF}
}

func (e *Evaluator) check(t token.Type) bool {
	return e.current().Type == t
}

func (e *Evaluator) match(t token.Type) bool {
	if e.check(t) {
		e.advance()
		return true
	}
	return false
}

// evalFactor parses and evaluates a factor:
// Number | Variable | FREE | RND '(' Expression ')' | ABS '(' Expression ')' | '(' Expression ')' | '-' Factor | '+' Factor
func (e *Evaluator) evalFactor() int32 {
	if e.match(token.NUMBER) {
		return e.tokens[e.cursor-1].NumberVal
	}

	if e.match(token.IDENT) {
		if e.vars != nil {
			return e.vars.Get(e.tokens[e.cursor-1].VarName)
		}
		return 0
	}

	if e.match(token.LPAREN) {
		val := e.EvalExpression()
		e.match(token.RPAREN)
		return val
	}

	if e.match(token.MINUS) {
		return -e.evalFactor()
	}

	if e.match(token.PLUS) {
		return e.evalFactor()
	}

	e.advance()
	return 0
}

// EvalExpression parses and evaluates an expression.
func (e *Evaluator) EvalExpression() int32 {
	return e.evalFactor()
}
