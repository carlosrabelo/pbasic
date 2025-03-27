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

func TestVariableGetSet(t *testing.T) {
	v := NewVariableStore()

	// Initial values are 0
	for ch := byte('A'); ch <= byte('Z'); ch++ {
		if val := v.Get(ch); val != 0 {
			t.Errorf("variable %c initially got %d, want 0", ch, val)
		}
	}

	// Set 32-bit values and test case-insensitivity
	v.Set('A', 1000000)
	v.Set('z', -500000)

	if val := v.Get('a'); val != 1000000 {
		t.Errorf("Get('a') got %d, want 1000000", val)
	}
	if val := v.Get('A'); val != 1000000 {
		t.Errorf("Get('A') got %d, want 1000000", val)
	}
	if val := v.Get('Z'); val != -500000 {
		t.Errorf("Get('Z') got %d, want -500000", val)
	}
	if val := v.Get('z'); val != -500000 {
		t.Errorf("Get('z') got %d, want -500000", val)
	}

	// Clear resets
	v.Clear()
	if val := v.Get('A'); val != 0 {
		t.Errorf("after Clear, Get('A') got %d, want 0", val)
	}
	if val := v.Get('Z'); val != 0 {
		t.Errorf("after Clear, Get('Z') got %d, want 0", val)
	}
}
