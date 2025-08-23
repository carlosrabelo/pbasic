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
