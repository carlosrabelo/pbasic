package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"pbasic/pbasic/internal/ast"
	"pbasic/pbasic/internal/evaluator"
	"pbasic/pbasic/internal/lexer"
	"pbasic/pbasic/internal/repl"
)

func main() {
	repl.SetupSignalHandling()

	prog := ast.NewProgramStore()
	vars := evaluator.NewVariableStore()
	interp := evaluator.NewInterpreter(os.Stdin, os.Stdout, prog, vars, 12345)
	interp.CheckInterrupted = repl.CheckAndResetInterrupted

	if len(os.Args) >= 2 {
		path := os.Args[1]
		file, err := os.Open(path)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Cannot open file: %s\n", path)
			os.Exit(1)
		}
		defer file.Close()

		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			rawLine := scanner.Text()
			rawLine = strings.TrimRight(rawLine, "\r")
			folded := repl.FoldCase(rawLine)
			classified := repl.ClassifyLine(folded)
			if classified.Type == repl.LineNumbered {
				prog.SetLine(classified.LineNumber, lexer.Tokenize(classified.Content), classified.Content)
			} else if classified.Type == repl.LineImmediate {
				interp.ExecuteStatement(lexer.Tokenize(classified.Content))
			}
		}

		interp.RunProgram()
		os.Exit(0)
	}

	fmt.Println("PBasic")
	r := repl.NewREPL(bufio.NewReader(os.Stdin), os.Stdout)

	r.SetNumberedHandler(func(lineNo uint16, content string) {
		trimmed := strings.TrimSpace(content)
		if len(trimmed) == 0 {
			prog.RemoveLine(lineNo)
		} else {
			prog.SetLine(lineNo, lexer.Tokenize(content), content)
		}
	})

	r.SetImmediateHandler(func(content string) bool {
		tokens := lexer.Tokenize(content)
		interp.ExecuteStatement(tokens)
		return !interp.ExitRequested
	})

	r.Start()
}
