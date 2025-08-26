package ast

import (
	"sort"

	"pbasic/pbasic/internal/token"
)

// LineNode represents a single numbered line in the stored BASIC program.
type LineNode struct {
	LineNumber uint16
	Tokens     []token.Token
	RawText    string
}

// ProgramStore holds and manages all stored program lines.
type ProgramStore struct {
	lines map[uint16]*LineNode
	order []uint16
}

// NewProgramStore constructs an empty ProgramStore.
func NewProgramStore() *ProgramStore {
	return &ProgramStore{
		lines: make(map[uint16]*LineNode),
		order: make([]uint16, 0),
	}
}

// Clear removes all stored lines from memory.
func (p *ProgramStore) Clear() {
	p.lines = make(map[uint16]*LineNode)
	p.order = p.order[:0]
}

// Empty returns true if no lines are stored.
func (p *ProgramStore) Empty() bool {
	return len(p.order) == 0
}

// HasLine returns true if a line with the given number exists.
func (p *ProgramStore) HasLine(lineNo uint16) bool {
	_, exists := p.lines[lineNo]
	return exists
}

// GetLine retrieves the LineNode for the given line number, or nil if not found.
func (p *ProgramStore) GetLine(lineNo uint16) *LineNode {
	return p.lines[lineNo]
}

// SetLine inserts or replaces a line in the program store, maintaining strictly sorted order.
func (p *ProgramStore) SetLine(lineNo uint16, tokens []token.Token, rawText string) {
	node := &LineNode{
		LineNumber: lineNo,
		Tokens:     tokens,
		RawText:    rawText,
	}

	if _, exists := p.lines[lineNo]; exists {
		p.lines[lineNo] = node
		return
	}

	p.lines[lineNo] = node

	// Insert into sorted order slice using binary search
	idx := sort.Search(len(p.order), func(i int) bool {
		return p.order[i] >= lineNo
	})

	p.order = append(p.order, 0)
	copy(p.order[idx+1:], p.order[idx:])
	p.order[idx] = lineNo
}

// ByteSize computes the total memory consumption of the program.
func (p *ProgramStore) ByteSize() int {
	total := 0
	for _, node := range p.lines {
		total += 4 + len(node.RawText) + 1
	}
	return total
}
