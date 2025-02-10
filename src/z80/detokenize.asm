; detokenize.asm - Detokenizer for PBasic Z80
; -----------------------------------------------------------------------
; Converts tokenized buffer back to printable ASCII text.

; --- Keyword strings for detokenization ---
DET_LET:	db	"LET ", 0
DET_GOTO:	db	"GOTO ", 0
DET_GOSUB:	db	"GOSUB ", 0
DET_PRINT:	db	"PRINT ", 0
DET_IF:		db	"IF ", 0
DET_INPUT:	db	"INPUT ", 0
DET_RETURN:	db	"RETURN", 0
DET_END:	db	"END", 0
DET_LIST:	db	"LIST", 0
DET_RUN:	db	"RUN", 0
DET_NEW:	db	"NEW", 0
DET_EXIT:	db	"EXIT", 0
DET_REM:	db	"REM ", 0
DET_THEN:	db	"THEN ", 0
DET_FREE:	db	"FREE", 0
DET_RND:	db	"RND", 0
DET_ABS:	db	"ABS", 0
DET_NE:		db	"<>", 0
DET_LE:		db	"<=", 0
DET_GE:		db	">=", 0

; --- Keyword pointer table (indexed by token - TK_LET) ---
DET_KW_TABLE:
	dw	DET_LET
	dw	DET_GOTO
	dw	DET_GOSUB
	dw	DET_PRINT
	dw	DET_IF
	dw	DET_INPUT
	dw	DET_RETURN
	dw	DET_END
	dw	DET_LIST
	dw	DET_RUN
	dw	DET_NEW
	dw	DET_EXIT
	dw	DET_REM
	dw	DET_THEN

; -----------------------------------------------------------------------
; PRINT_TOKENS - Print token stream at HL as text
; -----------------------------------------------------------------------
; Input:  HL = pointer to token buffer
; Output: None
; Clobbers: A, B, C, D, H, L, (stack)
; -----------------------------------------------------------------------
PRINT_TOKENS:
	ld	a, (hl)
	or	a
	ret	z			; end of stream

	cp	$80
	jr	c, PT_ASCII		; < 0x80 → literal ASCII

	cp	$C0
	jr	c, PT_MAIN_KW		; 0x80-0xBF → keyword or operator

	cp	$D0
	jr	c, PT_NUM_STR		; 0xC0-0xCF → number or string

	; 0xD0-0xFF → variable or invalid
	cp	$EA
	ret	nc			; >= 0xEA, ignore

	; Variable token (0xD0-0xE9)
	sub	$D0
	add	a, 'A'
	call	OUTCHAR
	inc	hl
	jr	PRINT_TOKENS

PT_ASCII:
	call	OUTCHAR
	inc	hl
	jr	PRINT_TOKENS

PT_MAIN_KW:
	cp	$A0
	jr	c, PT_KW_TABLE		; 0x80-0x9F → main keyword

	; 0xA0-0xBF: FREE, RND, ABS, or operators
	cp	$B0
	jr	c, PT_AUX_KW		; 0xA0-0xAF → FREE/RND/ABS

	; 0xB0-0xBF: comparison operators
PT_OP:
	cp	TK_NE
	jr	z, PT_NE
	cp	TK_LE
	jr	z, PT_LE
	cp	TK_GE
	jr	z, PT_GE
	; invalid, skip
	inc	hl
	jr	PRINT_TOKENS

PT_NE:	ld	de, DET_NE	; jr PT_PSTR
PT_LE:	ld	de, DET_LE	; jr PT_PSTR
PT_GE:	ld	de, DET_GE	; jr PT_PSTR

PT_PSTR:
	call	PRINT_STR
	inc	hl
	jr	PRINT_TOKENS

PT_AUX_KW:
	cp	TK_FREE
	jr	z, PT_FREE
	cp	TK_RND
	jr	z, PT_RND
	cp	TK_ABS
	jr	z, PT_ABS
	inc	hl
	jr	PRINT_TOKENS

PT_FREE: ld	de, DET_FREE	; jr PT_PSTR
PT_RND:	 ld	de, DET_RND	; jr PT_PSTR
PT_ABS:	 ld	de, DET_ABS	; jr PT_PSTR

PT_KW_TABLE:
	; Token 0x80-0x8D, index = (token - TK_LET) * 2
	sub	TK_LET
	add	a, a			; *2 for word table
	ld	de, DET_KW_TABLE
	add	a, e
	ld	e, a
	ld	a, 0
	adc	a, d
	ld	d, a			; DE = &DET_KW_TABLE[index]

	ld	a, (de)			; low byte of string addr
	ld	c, a
	inc	de
	ld	a, (de)			; high byte of string addr
	ld	b, a
	ld	d, b
	ld	e, c

	call	PRINT_STR
	inc	hl
	jr	PRINT_TOKENS

; -----------------------------------------------------------------------
PT_NUM_STR:
	cp	TK_NUM
	jr	z, PT_NUM

	; TK_STR (0xC1)
	inc	hl			; skip token byte
	ld	a, '"'
	call	OUTCHAR

PT_STR_LOOP:
	ld	a, (hl)
	or	a
	jr	z, PT_DONE		; end of buffer, abort
	cp	TK_STR
	jr	z, PT_STR_END

	call	OUTCHAR
	inc	hl
	jr	PT_STR_LOOP

PT_STR_END:
	ld	a, '"'
	call	OUTCHAR
	inc	hl
	jp	PRINT_TOKENS

PT_NUM:
	inc	hl			; skip token byte
	ld	a, (hl)
	ld	c, a
	inc	hl
	ld	a, (hl)
	ld	b, a			; BC = 16-bit value
	inc	hl
	push	hl			; save token buf ptr
	ld	l, c
	ld	h, b
	call	PRINT_NUMBER
	pop	hl
	jp	PRINT_TOKENS

PT_DONE:
	ret
