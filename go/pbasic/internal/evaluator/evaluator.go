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

	if e.match(token.FREE) {
		if e.prog != nil {
			return int32(16384 - e.prog.ByteSize())
		}
		return 16384
	}

	if e.match(token.RND) {
		e.match(token.LPAREN)
		x := e.EvalExpression()
		e.match(token.RPAREN)
		if e.randSeed != nil {
			*e.randSeed = uint16((uint32(*e.randSeed)*25173 + 13849) & 0xFFFF)
			if x <= 0 {
				return int32(*e.randSeed)
			}
			return int32((*e.randSeed % uint16(x)) + 1)
		}
		return 0
	}

	if e.match(token.ABS) {
		e.match(token.LPAREN)
		val := e.EvalExpression()
		e.match(token.RPAREN)
		if val < 0 {
			return -val
		}
		return val
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

// evalTerm parses and evaluates multiplicative terms (* and /).
func (e *Evaluator) evalTerm() int32 {
	left := e.evalFactor()

	for e.check(token.ASTERISK) || e.check(token.SLASH) {
		op := e.advance().Type
		right := e.evalFactor()

		uleft := uint16(left & 0xFFFF)
		uright := uint16(right & 0xFFFF)

		if op == token.ASTERISK {
			left = int32(Mul16(uleft, uright))
		} else {
			left = int32(Div16(uleft, uright))
		}
	}

	return left
}

// EvalExpression parses and evaluates an expression using + and - with 32-bit math.
func (e *Evaluator) EvalExpression() int32 {
	left := e.evalTerm()

	for e.check(token.PLUS) || e.check(token.MINUS) {
		op := e.advance().Type
		right := e.evalTerm()

		if op == token.PLUS {
			left += right
		} else {
			left -= right
		}
	}

	return left
}
