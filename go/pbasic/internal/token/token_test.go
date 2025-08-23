package token

import "testing"

func TestTokenDefinitions(t *testing.T) {
	tok := Token{
		Type:      IDENT,
		Literal:   "A",
		NumberVal: 0,
		VarName:   'A',
	}

	if tok.Type != IDENT || tok.VarName != 'A' {
		t.Errorf("unexpected token data: %+v", tok)
	}

	t.Run("LookupIdent matches keywords and functions", func(t *testing.T) {
		kwTests := []struct {
			ident    string
			wantType Type
			wantOk   bool
		}{
			{"LET", LET, true},
			{"PRINT", PRINT, true},
			{"IF", IF, true},
			{"THEN", THEN, true},
			{"FREE", FREE, true},
			{"RND", RND, true},
			{"ABS", ABS, true},
			{"UNKNOWN", "", false},
		}

		for _, tt := range kwTests {
			gotType, ok := LookupIdent(tt.ident)
			if ok != tt.wantOk || gotType != tt.wantType {
				t.Errorf("LookupIdent(%q) = {%v, %v}, want {%v, %v}",
					tt.ident, gotType, ok, tt.wantType, tt.wantOk)
			}
		}
	})
}
