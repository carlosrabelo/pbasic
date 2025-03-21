package repl

import (
	"fmt"
	"io"
	"strconv"
)

// PrintStr emits a string to the specified writer.
func PrintStr(w io.Writer, s string) {
	_, _ = io.WriteString(w, s)
}

// PrintNumber emits a signed 32-bit integer in decimal format without extra spaces.
func PrintNumber(w io.Writer, val int32) {
	_, _ = io.WriteString(w, strconv.FormatInt(int64(val), 10))
}

// PrintCRLF emits a standard newline to the writer.
func PrintCRLF(w io.Writer) {
	_, _ = io.WriteString(w, "\n")
}

// PrintOK emits OK followed by newline to the writer.
func PrintOK(w io.Writer) {
	_, _ = fmt.Fprintln(w, "OK")
}
