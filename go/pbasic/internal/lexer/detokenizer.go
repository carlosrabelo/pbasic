package lexer

import (
	"strconv"
	"strings"

	"pbasic/pbasic/internal/token"
)

// FormatTokens reconstructs a canonical BASIC text representation from tokens.
func FormatTokens(tokens []token.Token) string {
	var sb strings.Builder

	for _, tok := range tokens {
		switch tok.Type {
		case token.LET:
			sb.WriteString("LET ")
		case token.GOTO:
			sb.WriteString("GOTO ")
		case token.GOSUB:
			sb.WriteString("GOSUB ")
		case token.PRINT:
			sb.WriteString("PRINT ")
		case token.IF:
			sb.WriteString("IF ")
		case token.INPUT:
			sb.WriteString("INPUT ")
		case token.RETURN:
			sb.WriteString("RETURN")
		case token.END:
			sb.WriteString("END")
		case token.LIST:
			sb.WriteString("LIST")
		case token.RUN:
			sb.WriteString("RUN")
		case token.NEW:
			sb.WriteString("NEW")
		case token.EXIT:
			sb.WriteString("EXIT")
		case token.REM:
			sb.WriteString("REM ")
			sb.WriteString(tok.Literal)
		case token.THEN:
			sb.WriteString(" THEN ")
		case token.FREE:
			sb.WriteString("FREE")
		case token.RND:
			sb.WriteString("RND")
		case token.ABS:
			sb.WriteString("ABS")
		case token.NUMBER:
			sb.WriteString(strconv.FormatInt(int64(tok.NumberVal), 10))
		case token.STRING:
			sb.WriteString(`"`)
			sb.WriteString(tok.Literal)
			sb.WriteString(`"`)
		case token.IDENT:
			sb.WriteByte(tok.VarName)
		case token.PLUS:
			sb.WriteString(" + ")
		case token.MINUS:
			s := sb.String()
			if len(s) == 0 || s[len(s)-1] == '(' || s[len(s)-1] == ' ' {
				sb.WriteString("-")
			} else {
				sb.WriteString(" - ")
			}
		case token.ASTERISK:
			sb.WriteString(" * ")
		case token.SLASH:
			sb.WriteString(" / ")
		case token.ASSIGN, token.EQ:
			sb.WriteString(" = ")
		case token.NEQ:
			sb.WriteString(" <> ")
		case token.LT:
			sb.WriteString(" < ")
		case token.GT:
			sb.WriteString(" > ")
		case token.LE:
			sb.WriteString(" <= ")
		case token.GE:
			sb.WriteString(" >= ")
		case token.LPAREN:
			sb.WriteString("(")
		case token.RPAREN:
			sb.WriteString(")")
		case token.COMMA:
			sb.WriteString(", ")
		case token.SEMICOLON:
			sb.WriteString("; ")
		case token.EOL, token.EOF, token.ILLEGAL:
			// No output
		}
	}

	return sb.String()
}
