package evaluator

import (
	"testing"
)

func TestVariableStoreContainer(t *testing.T) {
	v := NewVariableStore()
	slots := v.RawSlots()

	for i, val := range slots {
		if val != 0 {
			t.Errorf("slot %d got %d, want 0", i, val)
		}
	}

	slots[0] = 42
	slots[25] = -999

	v.Clear()

	for i, val := range slots {
		if val != 0 {
			t.Errorf("after Clear(), slot %d got %d, want 0", i, val)
		}
	}
}
