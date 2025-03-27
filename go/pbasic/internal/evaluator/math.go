package evaluator

// Mul16 computes uint16((uint32(a) * uint32(b)) & 0xFFFF), truncating overflow past 16 bits.
func Mul16(a, b uint16) uint16 {
	return uint16((uint32(a) * uint32(b)) & 0xFFFF)
}
