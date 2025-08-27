package ast

import (
	"bytes"
	"reflect"
	"testing"

	"pbasic/pbasic/internal/lexer"
)

func TestProgramStoreStructures(t *testing.T) {
	prog := NewProgramStore()

	if !prog.Empty() {
		t.Errorf("new program store should be empty")
	}

	if prog.HasLine(10) {
		t.Errorf("empty store should not have line 10")
	}

	if prog.GetLine(10) != nil {
		t.Errorf("GetLine on empty store should return nil")
	}

	if prog.ByteSize() != 0 {
		t.Errorf("empty store byte size should be 0, got %d", prog.ByteSize())
	}
}

func TestSetLineInsertionAndReplacement(t *testing.T) {
	prog := NewProgramStore()

	// Insert lines out of order: 30, 10, 20
	prog.SetLine(30, nil, "PRINT 30")
	prog.SetLine(10, nil, "PRINT 10")
	prog.SetLine(20, nil, "PRINT 20")

	expectedOrder := []uint16{10, 20, 30}
	if !reflect.DeepEqual(prog.order, expectedOrder) {
		t.Errorf("line order got %v, want %v", prog.order, expectedOrder)
	}

	// Replacement of line 20
	prog.SetLine(20, nil, "PRINT 20 REPLACED")
	if !reflect.DeepEqual(prog.order, expectedOrder) {
		t.Errorf("line order after replace got %v, want %v", prog.order, expectedOrder)
	}
	if node := prog.GetLine(20); node == nil || node.RawText != "PRINT 20 REPLACED" {
		t.Errorf("unexpected node after replacement: %+v", node)
	}
}

func TestRemoveLine(t *testing.T) {
	prog := NewProgramStore()

	prog.SetLine(10, nil, "PRINT 10")
	prog.SetLine(20, nil, "PRINT 20")
	prog.SetLine(30, nil, "PRINT 30")

	if !prog.RemoveLine(20) {
		t.Errorf("expected RemoveLine(20) to return true")
	}

	if prog.HasLine(20) {
		t.Errorf("expected line 20 to be deleted")
	}

	expectedOrder := []uint16{10, 30}
	if !reflect.DeepEqual(prog.order, expectedOrder) {
		t.Errorf("line order after remove got %v, want %v", prog.order, expectedOrder)
	}

	if prog.RemoveLine(999) {
		t.Errorf("expected RemoveLine on non-existent line to return false")
	}
}

func TestProgramIteration(t *testing.T) {
	prog := NewProgramStore()

	if first := prog.FirstLine(); first != nil {
		t.Errorf("FirstLine on empty store should be nil, got %+v", first)
	}

	prog.SetLine(10, nil, "LINE 10")
	prog.SetLine(20, nil, "LINE 20")
	prog.SetLine(30, nil, "LINE 30")

	first := prog.FirstLine()
	if first == nil || first.LineNumber != 10 {
		t.Fatalf("FirstLine got %+v, want line 10", first)
	}

	next1 := prog.NextLine(10)
	if next1 == nil || next1.LineNumber != 20 {
		t.Fatalf("NextLine(10) got %+v, want line 20", next1)
	}

	next2 := prog.NextLine(20)
	if next2 == nil || next2.LineNumber != 30 {
		t.Fatalf("NextLine(20) got %+v, want line 30", next2)
	}

	next3 := prog.NextLine(30)
	if next3 != nil {
		t.Fatalf("NextLine(30) on last line got %+v, want nil", next3)
	}
}

func TestProgramList(t *testing.T) {
	prog := NewProgramStore()

	prog.SetLine(20, lexer.Tokenize("PRINT \"WORLD\""), "PRINT \"WORLD\"")
	prog.SetLine(10, lexer.Tokenize("PRINT \"HELLO\""), "PRINT \"HELLO\"")

	var buf bytes.Buffer
	prog.List(&buf)

	expected := "10 PRINT \"HELLO\"\n20 PRINT \"WORLD\"\n"
	if buf.String() != expected {
		t.Errorf("List output got %q, want %q", buf.String(), expected)
	}
}
