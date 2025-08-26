package ast

import (
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
