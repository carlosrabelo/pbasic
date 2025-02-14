; variables.asm - Variable storage routines (Z80)
; -----------------------------------------------------------------------
; Handles 26 16-bit variables A-Z. Stored at MEM_VARS ($D000).
; Tokens for variables: 0xD0=A, 0xD1=B, ..., 0xE9=Z.
; Layout: MEM_VARS + (token - 0xD0) * 2
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; VAR_INIT - Set all 26 variables to 0
; -----------------------------------------------------------------------
; Each variable is a 16-bit word, total 52 bytes.
; -----------------------------------------------------------------------
VAR_INIT:
	ld	hl, MEM_VARS
	ld	b, 52			; 52 bytes to clear
	xor	a
VAR_INIT_LOOP:
	ld	(hl), a
	inc	hl
	djnz	VAR_INIT_LOOP
	ret

; -----------------------------------------------------------------------
; VAR_GET - Read 16-bit variable value
; -----------------------------------------------------------------------
; Input:  A = variable token (0xD0-0xE9)
; Output: HL = variable value (16-bit)
; Clobbers: A, DE
; -----------------------------------------------------------------------
VAR_GET:
	sub	$D0			; A = index (0-25)
	add	a, a			; A = index * 2 (byte offset)
	ld	e, a
	ld	d, 0			; DE = byte offset
	ld	hl, MEM_VARS
	add	hl, de			; HL = &vars[index]
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a			; HL = value (little-endian)
	ret

; -----------------------------------------------------------------------
; VAR_SET - Write 16-bit variable value
; -----------------------------------------------------------------------
; Input:  A = variable token (0xD0-0xE9)
;         DE = 16-bit value to set
; Output: None
; Clobbers: A, HL
; -----------------------------------------------------------------------
VAR_SET:
	sub	$D0			; A = index (0-25)
	add	a, a			; A = index * 2 (byte offset)
	ld	l, a
	ld	h, 0			; HL = byte offset
	push	de			; save value
	ld	de, MEM_VARS
	add	hl, de			; HL = &vars[index]
	pop	de			; DE = value
	ld	(hl), e
	inc	hl
	ld	(hl), d			; store value (little-endian)
	ret
