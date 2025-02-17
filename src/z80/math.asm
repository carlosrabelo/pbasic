; math.asm - Core mathematical primitives (Z80)
; -----------------------------------------------------------------------
; Implements 16-bit integer multiplication, division, and modulo.
; Pure functions independent of the parser.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; MUL16 - Unsigned 16-bit multiply (shift-and-add).
; -----------------------------------------------------------------------
; Input:  HL = op1, DE = op2
; Output: HL = (op1 * op2) & 0xFFFF
; Clobbers: A, B, C, D, E
; -----------------------------------------------------------------------
MUL16:
	ld	b, h
	ld	c, l			; BC = op1 (multiplicand)
	ld	hl, 0			; HL = accumulator = 0
	ld	a, 16			; 16 bits to process

MUL16_LOOP:
	srl	d			; shift multiplier right into carry
	rr	e			; bit 0 → carry
	jr	nc, MUL16_SKIP
	add	hl, bc			; if bit was 1, add multiplicand

MUL16_SKIP:
	sla	c			; shift multiplicand left
	rl	b
	dec	a
	jr	nz, MUL16_LOOP
	ret
