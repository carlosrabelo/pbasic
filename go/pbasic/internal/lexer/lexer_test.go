package lexer

import (
	"testing"

	"pbasic/pbasic/internal/token"
)

func TestLexerScanningPunctuation(t *testing.T) {
	input := " ( ) , ; + - * / \n"
	tokens := Tokenize(input)

	expected := []token.Type{
		token.LPAREN,
		token.RPAREN,
		token.COMMA,
		token.SEMICOLON,
		token.PLUS,
		token.MINUS,
		token.ASTERISK,
		token.SLASH,
		token.EOL,
	}

	if len(tokens) != len(expected) {
		t.Fatalf("token count mismatch: got %d, want %d", len(tokens), len(expected))
	}

	for i, exp := range expected {
		if tokens[i].Type != exp {
			t.Errorf("token %d got type %v, want %v", i, tokens[i].Type, exp)
		}
	}
}

func TestLexerKeywordsAndVariables(t *testing.T) {
	input := "LET A PRINT B GOTO C GOSUB D RETURN IF THEN END LIST RUN NEW EXIT FREE RND ABS"
	tokens := Tokenize(input)

	expected := []struct {
		tokType token.Type
		literal string
		varName byte
	}{
		{token.LET, "LET", 0},
		{token.IDENT, "A", 'A'},
		{token.PRINT, "PRINT", 0},
		{token.IDENT, "B", 'B'},
		{token.GOTO, "GOTO", 0},
		{token.IDENT, "C", 'C'},
		{token.GOSUB, "GOSUB", 0},
		{token.IDENT, "D", 'D'},
		{token.RETURN, "RETURN", 0},
		{token.IF, "IF", 0},
		{token.THEN, "THEN", 0},
		{token.END, "END", 0},
		{token.LIST, "LIST", 0},
		{token.RUN, "RUN", 0},
		{token.NEW, "NEW", 0},
		{token.EXIT, "EXIT", 0},
		{token.FREE, "FREE", 0},
		{token.RND, "RND", 0},
		{token.ABS, "ABS", 0},
	}

	if len(tokens) != len(expected) {
		t.Fatalf("token count mismatch: got %d, want %d", len(tokens), len(expected))
	}

	for i, exp := range expected {
		if tokens[i].Type != exp.tokType || tokens[i].Literal != exp.literal || tokens[i].VarName != exp.varName {
			t.Errorf("token %d got {%v, %q, %c}, want {%v, %q, %c}",
				i, tokens[i].Type, tokens[i].Literal, tokens[i].VarName, exp.tokType, exp.literal, exp.varName)
		}
	}

	t.Run("REM consumes rest of line as comment", func(t *testing.T) {
		remInput := "REM THIS IS A COMMENT! + - * /"
		remTokens := Tokenize(remInput)

		if len(remTokens) != 1 {
			t.Fatalf("expected 1 REM token, got %d", len(remTokens))
		}
		if remTokens[0].Type != token.REM || remTokens[0].Literal != "THIS IS A COMMENT! + - * /" {
			t.Errorf("unexpected REM token: %+v", remTokens[0])
		}
	})
}
