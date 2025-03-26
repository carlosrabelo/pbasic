package ast

import (
	"reflect"
	"testing"
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
