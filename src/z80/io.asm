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
	call	PD_DIGIT
	ld	bc, 1000
	call	PD_DIGIT
	ld	bc, 100
	call	PD_DIGIT
	ld	bc, 10
	call	PD_DIGIT

	ld	a, l
	add	a, '0'
	call	OUTCHAR
	ret

; Extract one decimal digit from HL using power of 10 in BC
PD_DIGIT:
	ld	a, '0'
PD_LOOP:
	or	a			; clear carry
	sbc	hl, bc
	jr	c, PD_DONE
	inc	a
	jr	PD_LOOP

PD_DONE:
	add	hl, bc			; restore HL

	push	af
	ld	a, (MEM_SCRATCH)
	or	a
	jr	z, PD_EMIT		; already emitting
	pop	af
	cp	'0'
	ret	z			; skip leading zero
	push	af
	xor	a
	ld	(MEM_SCRATCH), a

PD_EMIT:
	pop	af
	jp	OUTCHAR

; -----------------------------------------------------------------------
; READ_LINE - Read input from TTY into input buffer
; -----------------------------------------------------------------------
; Reads characters from TTY into MEM_INPUT_BUF, strips trailing newline,
; converts lowercase to uppercase, and null-terminates.
;
; Input:  None
; Output: None
; Clobbers: A, B, HL
; -----------------------------------------------------------------------
READ_LINE:
	ld	hl, MEM_INPUT_BUF
	ld	b, 127			; max chars (room for null)

RL_CHAR_LOOP:
	call	INCHAR			; A = character from TTY

	cp	10			; newline?
	jr	z, RL_DONE

	cp	13			; carriage return?
	jr	z, RL_CHAR_LOOP

	ld	(hl), a
	inc	hl
	djnz	RL_CHAR_LOOP

RL_DONE:
	ld	(hl), 0			; null-terminate

	; Post-process: convert lowercase to uppercase
	ld	hl, MEM_INPUT_BUF

RL_UPPER_LOOP:
	ld	a, (hl)
	or	a
	ret	z			; end of string

	cp	'a'			; < 'a'?
	jr	c, RL_NEXT
	cp	'z' + 1			; >= 123?
	jr	nc, RL_NEXT

	sub	32			; convert to uppercase
	ld	(hl), a

RL_NEXT:
	inc	hl
	jr	RL_UPPER_LOOP

; -----------------------------------------------------------------------
; PRINT_OK - Print "OK" message
; -----------------------------------------------------------------------
PRINT_OK:
	ld	hl, MSG_OK
	jp	PRINT_STR
