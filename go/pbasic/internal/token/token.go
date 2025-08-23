package token

// Type represents the type of a lexical token.
type Type string

const (
	ILLEGAL Type = "ILLEGAL"
	EOF     Type = "EOF"
	EOL     Type = "EOL"

	NUMBER Type = "NUMBER"
	STRING Type = "STRING"
	IDENT  Type = "IDENT" // Variable 'A'..'Z'

	// Keywords
	LET    Type = "LET"
	GOTO   Type = "GOTO"
	GOSUB  Type = "GOSUB"
	PRINT  Type = "PRINT"
	IF     Type = "IF"
	INPUT  Type = "INPUT"
	RETURN Type = "RETURN"
	END    Type = "END"
	LIST   Type = "LIST"
	RUN    Type = "RUN"
	NEW    Type = "NEW"
	EXIT   Type = "EXIT"
	REM    Type = "REM"
	THEN   Type = "THEN"

	// Built-in functions
	FREE Type = "FREE"
	RND  Type = "RND"
	ABS  Type = "ABS"

	// Operators
	PLUS     Type = "+"
	MINUS    Type = "-"
	ASTERISK Type = "*"
	SLASH    Type = "/"
	ASSIGN   Type = "="

	EQ  Type = "=="
	NEQ Type = "<>"
	LT  Type = "<"
	GT  Type = ">"
	LE  Type = "<="
	GE  Type = ">="

	// Delimiters
	LPAREN    Type = "("
	RPAREN    Type = ")"
	COMMA     Type = ","
	SEMICOLON Type = ";"
)

// Token models a single token from lexical analysis.
type Token struct {
	Type      Type
	Literal   string
	NumberVal int32
	VarName   byte
}

var keywords = map[string]Type{
	"LET":    LET,
	"GOTO":   GOTO,
	"GOSUB":  GOSUB,
	"PRINT":  PRINT,
	"IF":     IF,
	"INPUT":  INPUT,
	"RETURN": RETURN,
	"END":    END,
	"LIST":   LIST,
	"RUN":    RUN,
	"NEW":    NEW,
	"EXIT":   EXIT,
	"REM":    REM,
	"THEN":   THEN,
	"FREE":   FREE,
	"RND":    RND,
	"ABS":    ABS,
}

// LookupIdent checks if an identifier is a keyword or function.
func LookupIdent(ident string) (Type, bool) {
	tokType, ok := keywords[ident]
	return tokType, ok
}
