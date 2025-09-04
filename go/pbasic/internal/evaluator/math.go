package evaluator

// Mul16 computes uint16((uint32(a) * uint32(b)) & 0xFFFF), truncating overflow past 16 bits.
func Mul16(a, b uint16) uint16 {
	return uint16((uint32(a) * uint32(b)) & 0xFFFF)
}

// Div16 performs unsigned 16-bit integer division.
// If b == 0, it safely returns 0xFFFF instead of panicking.
func Div16(a, b uint16) uint16 {
	if b == 0 {
		return 0xFFFF
	}
	return a / b
}

// Mod16 performs unsigned 16-bit modulo arithmetic.
// If b == 0, it safely returns the unchanged dividend a instead of panicking.
func Mod16(a, b uint16) uint16 {
	if b == 0 {
		return a
	}
	return a % b
}

// Add32 performs signed two's-complement 32-bit addition.
func Add32(a, b int32) int32 {
	return a + b
}

// Sub32 performs signed two's-complement 32-bit subtraction.
func Sub32(a, b int32) int32 {
	return a - b
}

// Neg32 computes -a in signed 32-bit representation.
func Neg32(a int32) int32 {
	return -a
}

// NextRND advances the 16-bit PRNG linear congruential generator and returns the new seed.
func NextRND(seed *uint16) uint16 {
	*seed = uint16((uint32(*seed)*25173 + 13849) & 0xFFFF)
	return *seed
}

// Abs32 computes the 32-bit absolute value of a signed integer.
func Abs32(a int32) int32 {
	if a < 0 {
		return -a
	}
	return a
}
