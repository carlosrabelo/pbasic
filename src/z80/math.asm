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

; -----------------------------------------------------------------------
; DIVMOD16 - Unsigned 16-bit division and modulo (restoring division).
; -----------------------------------------------------------------------
; Input:  HL = dividend, DE = divisor
; Output: HL = quotient, DE = remainder
;         If divisor = 0: HL = 0xFFFF, DE = dividend
; Clobbers: A, B, C
; -----------------------------------------------------------------------
DIVMOD16:
	ld	a, d
	or	e
	jr	z, DIVMOD16_ZERO

	push	de
	pop	bc			; BC = divisor

	ld	de, 0			; DE = remainder = 0
	ld	a, 16			; 16 bits to process

DIVMOD16_LOOP:
	add	hl, hl			; shift dividend left, MSB → carry
	rl	e			; shift carry into remainder
	rl	d

	push	hl			; save shifted dividend
	or	a			; clear carry for sbc
	ld	h, d
	ld	l, e			; HL = copy of trial remainder
	sbc	hl, bc			; HL = trial remainder - divisor
	jr	c, DM_SKIP

	ld	d, h
	ld	e, l			; DE = new remainder
	pop	hl			; HL = shifted dividend
	inc	hl			; set quotient bit
	jr	DM_NEXT

DM_SKIP:
	pop	hl			; HL = shifted dividend (DE = trial remainder)

DM_NEXT:
	dec	a
	jr	nz, DIVMOD16_LOOP
	ret

DIVMOD16_ZERO:
	ex	de, hl			; DE = dividend, HL = divisor (0)
	ld	hl, $FFFF		; HL = 0xFFFF on div-by-zero
	ret

; -----------------------------------------------------------------------
; DIV16 - Unsigned 16-bit divide.
; -----------------------------------------------------------------------
; Input:  HL = dividend, DE = divisor
; Output: HL = quotient, or 0xFFFF if division by zero
; Clobbers: A, B, C, D, E
; -----------------------------------------------------------------------
DIV16:
	call	DIVMOD16
	ret

; -----------------------------------------------------------------------
; MOD16 - Unsigned 16-bit modulo.
; -----------------------------------------------------------------------
; Input:  HL = dividend, DE = divisor
; Output: HL = remainder, or HL = dividend if division by zero
; Clobbers: A, B, C, D, E
; -----------------------------------------------------------------------
MOD16:
	call	DIVMOD16
	ex	de, hl			; HL = remainder
	ret
