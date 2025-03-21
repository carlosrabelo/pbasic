package repl

import (
	"bufio"
	"io"
	"strings"
	"unicode"
)

// FoldCase converts lowercase ASCII characters to uppercase outside double quotes ("...").
func FoldCase(s string) string {
	var sb strings.Builder
	sb.Grow(len(s))
	inQuotes := false

	for _, r := range s {
		if r == '"' {
			inQuotes = !inQuotes
			sb.WriteRune(r)
		} else if !inQuotes && unicode.IsLower(r) {
			sb.WriteRune(unicode.ToUpper(r))
		} else {
			sb.WriteRune(r)
		}
	}

	return sb.String()
}

// ReadLine reads a single line from the buffered reader, strips CRLF, and applies FoldCase.
// Returns io.EOF when no more input is available.
func ReadLine(r *bufio.Reader) (string, error) {
	line, err := r.ReadString('\n')
	if err != nil && len(line) == 0 {
		return "", err
	}

	// Normalize trailing CRLF or LF
	if strings.HasSuffix(line, "\r\n") {
		line = line[:len(line)-2]
	} else if strings.HasSuffix(line, "\n") {
		line = line[:len(line)-1]
	} else if strings.HasSuffix(line, "\r") {
		line = line[:len(line)-1]
	}

	folded := FoldCase(line)

	if err == io.EOF && len(line) > 0 {
		return folded, nil
	}

	return folded, err
}
