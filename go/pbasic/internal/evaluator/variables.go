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

// RawSlots returns a pointer to the internal array (useful for testing).
func (v *VariableStore) RawSlots() *[26]int32 {
	return &v.vars
}
