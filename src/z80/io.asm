; io.asm - Base I/O routines for PBasic Z80
; -----------------------------------------------------------------------
; Provides low-level TTY communication via port-mapped I/O at Port 0x00.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; INCHAR - Read a single character from TTY (Port 0x00)
; -----------------------------------------------------------------------
; Blocks until a character is available from the TTY input.
;
; Input:  None
; Output: A = ASCII value of the character read
; -----------------------------------------------------------------------
INCHAR:
	in	a, (0)
	ret

; -----------------------------------------------------------------------
; OUTCHAR - Write a single character to TTY (Port 0x00)
; -----------------------------------------------------------------------
; Sends the character to the TTY output.
;
; Input:  A = ASCII character to print
; Output: None
; -----------------------------------------------------------------------
OUTCHAR:
	out	(0), a
	ret

; -----------------------------------------------------------------------
; PRINT_STR - Print a null-terminated string
; -----------------------------------------------------------------------
; Input:  HL = address of string
; Output: None
; Clobbers: A, HL
; -----------------------------------------------------------------------
PRINT_STR:
	ld	a, (hl)
	or	a
	ret	z
	call	OUTCHAR
	inc	hl
	jr	PRINT_STR

; -----------------------------------------------------------------------
; PRINT_CRLF - Print a CR+LF newline sequence
; -----------------------------------------------------------------------
PRINT_CRLF:
	ld	a, 13
	call	OUTCHAR
	ld	a, 10
	jp	OUTCHAR

; -----------------------------------------------------------------------
; PRINT_NUMBER - Print HL as unsigned decimal
; -----------------------------------------------------------------------
; Input:  HL = 16-bit value to print
; Output: None
; Clobbers: A, BC, flags
; -----------------------------------------------------------------------
PRINT_NUMBER:
	ld	a, h
	or	l
	jr	nz, PN_NZ
	ld	a, '0'
	jp	OUTCHAR

PN_NZ:
	ld	a, 1
	ld	(MEM_SCRATCH), a	; suppress leading zeros flag

	ld	bc, 10000
	call	PN_DIGIT
	ld	bc, 1000
	call	PN_DIGIT
	ld	bc, 100
	call	PN_DIGIT
	ld	bc, 10
	call	PN_DIGIT

	ld	a, l
	add	a, '0'
	call	OUTCHAR
	ret

; Extract one decimal digit from HL using power of 10 in BC
PN_DIGIT:
	ld	a, '0'
PN_LOOP:
	or	a			; clear carry
	sbc	hl, bc
	jr	c, PN_DONE
	inc	a
	jr	PN_LOOP

PN_DONE:
	add	hl, bc			; restore HL

	push	af
	ld	a, (MEM_SCRATCH)
	or	a
	jr	z, PN_EMIT		; already emitting
	pop	af
	cp	'0'
	ret	z			; skip leading zero
	push	af
	xor	a
	ld	(MEM_SCRATCH), a

PN_EMIT:
	pop	af
	jp	OUTCHAR

; -----------------------------------------------------------------------
; PRINT_OK - Print "OK" message
; -----------------------------------------------------------------------
PRINT_OK:
	ld	hl, MSG_OK
	jp	PRINT_STR
