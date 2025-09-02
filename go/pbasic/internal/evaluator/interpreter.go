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
	In               io.Reader
	Out              io.Writer
	Prog             *ast.ProgramStore
	Vars             *VariableStore
	RandSeed         uint16
	GosubStack       []uint16
	CurrentLineNo    uint16
	BranchTarget     uint16
	BranchTaken      bool
	Halted           bool
	ExitRequested    bool
	IsRunning        bool
	CheckInterrupted func() bool
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

	case token.RUN:
		return interp.RunProgram()

	case token.LIST:
		return interp.execList()

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
	if interp.Prog != nil {
		interp.Prog.Clear()
	}
	if interp.Vars != nil {
		interp.Vars.Clear()
	}
	if interp.Out != nil {
		fmt.Fprintln(interp.Out, "OK")
	}
	return ExecOk
}

func (interp *Interpreter) execFree() ExecResult {
	byteSize := 0
	if interp.Prog != nil {
		byteSize = interp.Prog.ByteSize()
	}
	freeBytes := 0
	if 16384 >= byteSize {
		freeBytes = 16384 - byteSize
	}
	if interp.Out != nil {
		fmt.Fprintln(interp.Out, freeBytes)
	}
	return ExecOk
}

// RunProgram executes all stored program lines in sequential order.
func (interp *Interpreter) RunProgram() ExecResult {
	if interp.Prog == nil || interp.Prog.Empty() {
		if interp.Out != nil {
			fmt.Fprintln(interp.Out, "?NO PROGRAM")
		}
		return ExecOk
	}

	interp.GosubStack = interp.GosubStack[:0]
	interp.Halted = false
	interp.IsRunning = true

	cur := interp.Prog.FirstLine()

	for cur != nil && !interp.Halted && !interp.ExitRequested {
		if interp.CheckInterrupted != nil && interp.CheckInterrupted() {
			interp.Halted = true
			if interp.Out != nil {
				fmt.Fprintln(interp.Out)
			}
			break
		}

		interp.CurrentLineNo = cur.LineNumber
		interp.BranchTaken = false

		res := interp.ExecuteStatement(cur.Tokens)
		if res == ExecSyntaxError {
			interp.IsRunning = false
			return res
		}

		if interp.Halted || interp.ExitRequested {
			break
		}

		if interp.BranchTaken {
			cur = interp.Prog.GetLine(interp.BranchTarget)
		} else {
			cur = interp.Prog.NextLine(interp.CurrentLineNo)
		}
	}

	interp.IsRunning = false
	return ExecOk
}

func (interp *Interpreter) execList() ExecResult {
	if interp.Prog != nil && interp.Out != nil {
		interp.Prog.List(interp.Out)
	}
	return ExecOk
}
