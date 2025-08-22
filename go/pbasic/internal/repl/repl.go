package repl

import (
	"bufio"
	"io"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync/atomic"
	"syscall"
	"unicode"
)

var interrupted int32

// SetupSignalHandling registers an interrupt handler for SIGINT (Ctrl+C).
func SetupSignalHandling() chan os.Signal {
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGINT)
	go func() {
		for range sigChan {
			atomic.StoreInt32(&interrupted, 1)
		}
	}()
	return sigChan
}

// CheckAndResetInterrupted returns true if SIGINT occurred, and resets the flag.
func CheckAndResetInterrupted() bool {
	return atomic.SwapInt32(&interrupted, 0) == 1
}

// SetInterrupted manually sets the interrupted flag.
func SetInterrupted() {
	atomic.StoreInt32(&interrupted, 1)
}

// LineType defines the categorization of an input line.
type LineType int

const (
	LineEmpty LineType = iota
	LineNumbered
	LineImmediate
)

// ParsedLinePrefix contains the parsed metadata of an input line.
type ParsedLinePrefix struct {
	Type       LineType
	LineNumber uint16
	Content    string
}

// ClassifyLine inspects a line to determine whether it is empty, numbered, or immediate.
func ClassifyLine(line string) ParsedLinePrefix {
	trimmed := strings.TrimSpace(line)
	if len(trimmed) == 0 {
		return ParsedLinePrefix{Type: LineEmpty}
	}

	if unicode.IsDigit(rune(trimmed[0])) {
		idx := 0
		for idx < len(trimmed) && unicode.IsDigit(rune(trimmed[idx])) {
			idx++
		}

		num64, err := strconv.ParseUint(trimmed[:idx], 10, 16)
		if err == nil && num64 >= 1 && num64 <= 65535 {
			content := strings.TrimSpace(trimmed[idx:])
			return ParsedLinePrefix{
				Type:       LineNumbered,
				LineNumber: uint16(num64),
				Content:    content,
			}
		}
	}

	return ParsedLinePrefix{
		Type:    LineImmediate,
		Content: trimmed,
	}
}

// REPL encapsulates the interactive command loop.
type REPL struct {
	in          *bufio.Reader
	out         io.Writer
	onNumbered  func(lineNo uint16, content string)
	onImmediate func(content string) bool
}

// NewREPL constructs a new REPL instance.
func NewREPL(in *bufio.Reader, out io.Writer) *REPL {
	return &REPL{
		in:  in,
		out: out,
	}
}

// SetNumberedHandler sets the callback for numbered lines.
func (r *REPL) SetNumberedHandler(fn func(lineNo uint16, content string)) {
	r.onNumbered = fn
}

// SetImmediateHandler sets the callback for immediate statements.
func (r *REPL) SetImmediateHandler(fn func(content string) bool) {
	r.onImmediate = fn
}

// Start executes the REPL prompt loop until EOF or EXIT.
func (r *REPL) Start() {
	for {
		CheckAndResetInterrupted()
		PrintStr(r.out, "> ")
		line, err := ReadLine(r.in)
		if err != nil {
			if CheckAndResetInterrupted() {
				PrintCRLF(r.out)
				continue
			}
			if err == io.EOF {
				PrintCRLF(r.out)
				break
			}
			PrintCRLF(r.out)
			break
		}

		trimmed := strings.TrimSpace(line)
		if len(trimmed) == 0 {
			continue
		}

		if trimmed == "EXIT" {
			break
		}

		parsed := ClassifyLine(trimmed)
		switch parsed.Type {
		case LineNumbered:
			if r.onNumbered != nil {
				r.onNumbered(parsed.LineNumber, parsed.Content)
			}
		case LineImmediate:
			if r.onImmediate != nil {
				shouldContinue := r.onImmediate(parsed.Content)
				if !shouldContinue {
					return
				}
			}
		}
	}
}
