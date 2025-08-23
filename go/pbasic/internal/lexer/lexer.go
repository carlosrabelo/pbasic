package lexer

import (
	"pbasic/pbasic/internal/token"
)

// Lexer converts a source line into a sequence of tokens.
type Lexer struct {
	input        string
	position     int  // current position in input (points to current char)
	readPosition int  // current reading position in input (after current char)
	ch           byte // current char under examination
}

// New creates and initializes a new Lexer instance.
func New(input string) *Lexer {
	l := &Lexer{input: input}
	l.readChar()
	return l
}

func (l *Lexer) readChar() {
	if l.readPosition >= len(l.input) {
		l.ch = 0
	} else {
		l.ch = l.input[l.readPosition]
	}
	l.position = l.readPosition
	l.readPosition++
}

func (l *Lexer) peekChar() byte {
	if l.readPosition >= len(l.input) {
		return 0
	}
	return l.input[l.readPosition]
}

func (l *Lexer) skipWhitespace() {
	for l.ch == ' ' || l.ch == '\t' {
		l.readChar()
	}
}

// NextToken scans and returns the next token from the input.
func (l *Lexer) NextToken() token.Token {
	l.skipWhitespace()

	var tok token.Token

	switch l.ch {
	case 0:
		tok = token.Token{Type: token.EOF, Literal: ""}
	case '\n':
		tok = token.Token{Type: token.EOL, Literal: "\n"}
		l.readChar()
	case '(':
		tok = token.Token{Type: token.LPAREN, Literal: "("}
		l.readChar()
	case ')':
		tok = token.Token{Type: token.RPAREN, Literal: ")"}
		l.readChar()
	case ',':
		tok = token.Token{Type: token.COMMA, Literal: ","}
		l.readChar()
	case ';':
		tok = token.Token{Type: token.SEMICOLON, Literal: ";"}
		l.readChar()
	case '+':
		tok = token.Token{Type: token.PLUS, Literal: "+"}
		l.readChar()
	case '-':
		tok = token.Token{Type: token.MINUS, Literal: "-"}
		l.readChar()
	case '*':
		tok = token.Token{Type: token.ASTERISK, Literal: "*"}
		l.readChar()
	case '/':
		tok = token.Token{Type: token.SLASH, Literal: "/"}
		l.readChar()
	default:
		tok = token.Token{Type: token.ILLEGAL, Literal: string(l.ch)}
		l.readChar()
	}

	return tok
}

// Tokenize tokenizes an entire line into a slice of tokens ending with EOL or EOF.
func Tokenize(input string) []token.Token {
	l := New(input)
	var tokens []token.Token

	for {
		tok := l.NextToken()
		if tok.Type == token.EOF {
			break
		}
		tokens = append(tokens, tok)
		if tok.Type == token.EOL {
			break
		}
	}

	return tokens
}
