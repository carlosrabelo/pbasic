package lexer

import (
	"strconv"
	"unicode"

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
	case '=':
		if l.peekChar() == '=' {
			ch := l.ch
			l.readChar()
			tok = token.Token{Type: token.EQ, Literal: string(ch) + string(l.ch)}
		} else {
			tok = token.Token{Type: token.ASSIGN, Literal: "="}
		}
		l.readChar()
	case '<':
		if l.peekChar() == '>' {
			ch := l.ch
			l.readChar()
			tok = token.Token{Type: token.NEQ, Literal: string(ch) + string(l.ch)}
		} else if l.peekChar() == '=' {
			ch := l.ch
			l.readChar()
			tok = token.Token{Type: token.LE, Literal: string(ch) + string(l.ch)}
		} else {
			tok = token.Token{Type: token.LT, Literal: "<"}
		}
		l.readChar()
	case '>':
		if l.peekChar() == '=' {
			ch := l.ch
			l.readChar()
			tok = token.Token{Type: token.GE, Literal: string(ch) + string(l.ch)}
		} else {
			tok = token.Token{Type: token.GT, Literal: ">"}
		}
		l.readChar()
	case '"':
		str := l.readString()
		tok = token.Token{Type: token.STRING, Literal: str}
	default:
		if unicode.IsDigit(rune(l.ch)) {
			numStr, val := l.readNumber()
			return token.Token{Type: token.NUMBER, Literal: numStr, NumberVal: val}
		}
		if isLetter(l.ch) {
			ident := l.readIdentifier()
			if tokType, ok := token.LookupIdent(ident); ok {
				if tokType == token.REM {
					l.skipWhitespace()
					comment := l.readRestOfLine()
					return token.Token{Type: token.REM, Literal: comment}
				}
				return token.Token{Type: tokType, Literal: ident}
			}
			if len(ident) == 1 && ident[0] >= 'A' && ident[0] <= 'Z' {
				return token.Token{
					Type:    token.IDENT,
					Literal: ident,
					VarName: ident[0],
				}
			}
			return token.Token{Type: token.ILLEGAL, Literal: ident}
		}
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

func (l *Lexer) readIdentifier() string {
	start := l.position
	for isLetter(l.ch) {
		l.readChar()
	}
	return l.input[start:l.position]
}

func (l *Lexer) readRestOfLine() string {
	start := l.position
	for l.ch != 0 && l.ch != '\n' && l.ch != '\r' {
		l.readChar()
	}
	return l.input[start:l.position]
}

func isLetter(ch byte) bool {
	return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
}

func (l *Lexer) readString() string {
	l.readChar() // skip opening quote
	start := l.position
	for l.ch != '"' && l.ch != 0 && l.ch != '\n' && l.ch != '\r' {
		l.readChar()
	}
	str := l.input[start:l.position]
	if l.ch == '"' {
		l.readChar() // consume closing quote
	}
	return str
}

func (l *Lexer) readNumber() (string, int32) {
	start := l.position
	for unicode.IsDigit(rune(l.ch)) {
		l.readChar()
	}
	numStr := l.input[start:l.position]
	val64, _ := strconv.ParseInt(numStr, 10, 32)
	return numStr, int32(val64)
}
