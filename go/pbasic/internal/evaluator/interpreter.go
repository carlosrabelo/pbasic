package evaluator

import (
	"fmt"
	"io"
	"pbasic/pbasic/internal/ast"
	"pbasic/pbasic/internal/token"
)

// ExecResult represents the outcome of statement execution.
type ExecResult int

const (
	ExecOk ExecResult = iota
	ExecStop
	ExecSyntaxError
)

// Interpreter coordinates statement execution, program storage, variables, and I/O.
type Interpreter struct {
	In            io.Reader
	Out           io.Writer
	Prog          *ast.ProgramStore
	Vars          *VariableStore
	RandSeed      uint16
	GosubStack    []uint16
	CurrentLineNo uint16
	BranchTarget  uint16
	BranchTaken   bool
	Halted        bool
	ExitRequested bool
	IsRunning     bool
}

// NewInterpreter creates a new Interpreter instance.
func NewInterpreter(in io.Reader, out io.Writer, prog *ast.ProgramStore, vars *VariableStore, seed uint16) *Interpreter {
	if seed == 0 {
		seed = 12345
	}
	return &Interpreter{
		In:         in,
		Out:        out,
		Prog:       prog,
		Vars:       vars,
		RandSeed:   seed,
		GosubStack: make([]uint16, 0, 16),
	}
}

func (interp *Interpreter) syntaxError() {
	if interp.Out != nil {
		fmt.Fprintln(interp.Out, "?SYNTAX ERROR")
	}
}

// ExecuteStatement executes a sequence of tokens representing a BASIC statement.
func (interp *Interpreter) ExecuteStatement(tokens []token.Token) ExecResult {
	if len(tokens) == 0 {
		return ExecOk
	}

	cursor := 0
	first := tokens[cursor]

	switch first.Type {
	case token.EOL, token.EOF:
		return ExecOk

	case token.REM:
		return ExecOk

	case token.PRINT:
		cursor++
		return interp.execPrint(tokens, &cursor)

	case token.LET:
		cursor++
		return interp.execLet(tokens, &cursor)

	case token.IDENT:
		return interp.execLet(tokens, &cursor)

	case token.NEW:
		return interp.execNew()

	case token.FREE:
		return interp.execFree()

	default:
		interp.syntaxError()
		return ExecSyntaxError
	}
}

func (interp *Interpreter) execPrint(tokens []token.Token, cursor *int) ExecResult {
	trailingSemicolon := false

	for *cursor < len(tokens) {
		tok := tokens[*cursor]
		if tok.Type == token.EOL || tok.Type == token.EOF {
			break
		}

		if tok.Type == token.STRING {
			if interp.Out != nil {
				fmt.Fprint(interp.Out, tok.Literal)
			}
			*cursor++
			trailingSemicolon = false
		} else if tok.Type == token.COMMA {
			if interp.Out != nil {
				fmt.Fprint(interp.Out, "        ")
			}
			*cursor++
			trailingSemicolon = false
		} else if tok.Type == token.SEMICOLON {
			*cursor++
			trailingSemicolon = true
		} else {
			eval := NewEvaluator(tokens, interp.Vars, interp.Prog, &interp.RandSeed)
			eval.SetCursor(*cursor)
			val := eval.EvalExpression()
			*cursor = eval.GetCursor()
			if interp.Out != nil {
				fmt.Fprint(interp.Out, val)
			}
			trailingSemicolon = false
		}
	}

	if !trailingSemicolon && interp.Out != nil {
		fmt.Fprintln(interp.Out)
	}

	return ExecOk
}

func (interp *Interpreter) execLet(tokens []token.Token, cursor *int) ExecResult {
	if *cursor >= len(tokens) || tokens[*cursor].Type != token.IDENT {
		interp.syntaxError()
		return ExecSyntaxError
	}

	varName := tokens[*cursor].VarName
	*cursor++

	if *cursor >= len(tokens) || (tokens[*cursor].Type != token.ASSIGN && tokens[*cursor].Type != token.EQ) {
		interp.syntaxError()
		return ExecSyntaxError
	}
	*cursor++

	eval := NewEvaluator(tokens, interp.Vars, interp.Prog, &interp.RandSeed)
	eval.SetCursor(*cursor)
	val := eval.EvalExpression()
	*cursor = eval.GetCursor()

	if interp.Vars != nil {
		interp.Vars.Set(varName, val)
	}
	return ExecOk
}

func (interp *Interpreter) execNew() ExecResult {
	return ExecOk
}

func (interp *Interpreter) execFree() ExecResult {
	return ExecOk
}
