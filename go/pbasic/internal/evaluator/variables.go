package evaluator

// VariableStore stores 26 signed 32-bit integer variables ('A' through 'Z').
type VariableStore struct {
	vars [26]int32
}

// NewVariableStore initializes a new VariableStore with all slots set to 0.
func NewVariableStore() *VariableStore {
	return &VariableStore{}
}

// Clear resets all 26 variables to 0.
func (v *VariableStore) Clear() {
	for i := range v.vars {
		v.vars[i] = 0
	}
}

// Get returns the value of variable 'A'..'Z' (case-insensitive).
func (v *VariableStore) Get(name byte) int32 {
	idx := varIndex(name)
	return v.vars[idx]
}

// Set stores the value of variable 'A'..'Z' (case-insensitive).
func (v *VariableStore) Set(name byte, val int32) {
	idx := varIndex(name)
	v.vars[idx] = val
}

func varIndex(name byte) int {
	if name >= 'a' && name <= 'z' {
		name -= 32
	}
	if name >= 'A' && name <= 'Z' {
		return int(name - 'A')
	}
	return 0
}

// RawSlots returns a pointer to the internal array (useful for testing).
func (v *VariableStore) RawSlots() *[26]int32 {
	return &v.vars
}
