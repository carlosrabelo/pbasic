; tokenize.asm - Tokenizer for PBasic Z80
; -----------------------------------------------------------------------
; Converts ASCII in MEM_INPUT_BUF to internal 1-byte tokens in MEM_TOKEN_BUF.

; --- Token values (must match MIPS) ---
TK_LET:		equ	$80
TK_GOTO:	equ	$81
TK_GOSUB:	equ	$82
TK_PRINT:	equ	$83
TK_IF:		equ	$84
TK_INPUT:	equ	$85
TK_RETURN:	equ	$86
TK_END:		equ	$87
TK_LIST:	equ	$88
TK_RUN:		equ	$89
TK_NEW:		equ	$8A
TK_EXIT:	equ	$8B
TK_REM:		equ	$8C
TK_THEN:	equ	$8D
TK_FREE:	equ	$A0
TK_RND:		equ	$A1
TK_ABS:		equ	$A2
TK_NE:		equ	$B0
TK_LE:		equ	$B1
TK_GE:		equ	$B2
TK_NUM:		equ	$C0
TK_STR:		equ	$C1
TK_VAR:		equ	$D0

; --- Keyword strings ---
KW_PRINT:	db	"PRINT", 0
KW_LET:		db	"LET", 0
KW_IF:		db	"IF", 0
KW_GOTO:	db	"GOTO", 0
KW_GOSUB:	db	"GOSUB", 0
KW_INPUT:	db	"INPUT", 0
KW_RETURN:	db	"RETURN", 0
KW_THEN:	db	"THEN", 0
KW_END:		db	"END", 0
KW_REM:		db	"REM", 0
KW_LIST:	db	"LIST", 0
KW_RUN:		db	"RUN", 0
KW_NEW:		db	"NEW", 0
KW_EXIT:	db	"EXIT", 0
KW_FREE:	db	"FREE", 0
KW_RND:		db	"RND", 0
KW_ABS:		db	"ABS", 0

; -----------------------------------------------------------------------
; TOKENIZE - Convert input buffer to tokens
; -----------------------------------------------------------------------
; Input:  MEM_INPUT_BUF (raw ASCII text)
; Output: MEM_TOKEN_BUF (tokenized), MEM_TOKEN_PTR set
; Clobbers: A, B, C, D, E, H, L
; -----------------------------------------------------------------------
TOKENIZE:
	ld	hl, MEM_INPUT_BUF	; source
	ld	de, MEM_TOKEN_BUF	; destination

TOK_SKIP_SPACES:
	ld	a, (hl)
	cp	' '
	jr	nz, TOK_CHECK_CHAR
	inc	hl
	jr	TOK_SKIP_SPACES

TOK_CHECK_CHAR:
	ld	a, (hl)
	or	a
	jp	z, TOK_DONE		; end of input

	cp	'"'
	jp	z, TOK_STRING

	cp	'0'
	jr	c, TOK_NOT_DIGIT	; < '0'
	cp	'9' + 1
	jp	c, TOK_NUMBER		; '0'-'9'

TOK_NOT_DIGIT:
	cp	'A'
	jr	c, TOK_OPERATOR		; < 'A', not a letter
	cp	'Z' + 1
	jp	c, TOK_LETTER		; 'A'-'Z', it's a letter or keyword

TOK_OPERATOR:
	cp	'<'
	jp	z, TOK_LT
	cp	'>'
	jp	z, TOK_GT
	; '+', '-', '*', '/', '=', '(', ')', ';', ',' stored as ASCII
	ld	(de), a
	inc	hl
	inc	de
	jr	TOK_SKIP_SPACES

; -----------------------------------------------------------------------
; TOK_NUMBER - Parse a numeric literal
; -----------------------------------------------------------------------
TOK_NUMBER:
	ld	a, TK_NUM
	ld	(de), a
	inc	de

	push	de			; save token buf ptr
	call	PARSE_NUMBER		; HL = advanced input, DE = value
	ex	de, hl			; HL = value, DE = advanced input
	ex	(sp), hl		; HL = token buf ptr [stack: value]
	ld	a, e
	ld	(hl), a			; store low byte
	inc	hl
	ld	a, d
	ld	(hl), a			; store high byte
	inc	hl
	ex	de, hl			; DE = new token buf ptr
	pop	hl			; HL = advanced input ptr
	jp	TOK_SKIP_SPACES

; -----------------------------------------------------------------------
; TOK_STRING - Parse a string literal
; -----------------------------------------------------------------------
TOK_STRING:
	ld	a, TK_STR
	ld	(de), a
	inc	de
	inc	hl			; skip opening quote

TS_LOOP:
	ld	a, (hl)
	or	a
	jr	z, TS_END		; unclosed string
	cp	'"'
	jr	z, TS_CLOSE

	ld	(de), a			; store char as-is
	inc	hl
	inc	de
	jr	TS_LOOP

TS_CLOSE:
	inc	hl			; skip closing quote

TS_END:
	ld	a, TK_STR
	ld	(de), a
	inc	de
	jr	TOK_SKIP_SPACES

; -----------------------------------------------------------------------
; TOK_LETTER - Handle letter: keyword or variable
; -----------------------------------------------------------------------
TOK_LETTER:
	; Try MATCH_KEYWORD for each known keyword.
	; Order matches MIPS version.

	ld	de, KW_PRINT
	call	MATCH_KEYWORD
	jp	c, TK_PRINT_MATCH

	ld	de, KW_LET
	call	MATCH_KEYWORD
	jp	c, TK_LET_MATCH

	ld	de, KW_IF
	call	MATCH_KEYWORD
	jp	c, TK_IF_MATCH

	ld	de, KW_GOTO
	call	MATCH_KEYWORD
	jp	c, TK_GOTO_MATCH

	ld	de, KW_GOSUB
	call	MATCH_KEYWORD
	jp	c, TK_GOSUB_MATCH

	ld	de, KW_INPUT
	call	MATCH_KEYWORD
	jp	c, TK_INPUT_MATCH

	ld	de, KW_RETURN
	call	MATCH_KEYWORD
	jp	c, TK_RETURN_MATCH

	ld	de, KW_THEN
	call	MATCH_KEYWORD
	jp	c, TK_THEN_MATCH

	ld	de, KW_END
	call	MATCH_KEYWORD
	jp	c, TK_END_MATCH

	ld	de, KW_REM
	call	MATCH_KEYWORD
	jp	c, TK_REM_MATCH

	ld	de, KW_LIST
	call	MATCH_KEYWORD
	jr	c, TK_LIST_MATCH

	ld	de, KW_RUN
	call	MATCH_KEYWORD
	jr	c, TK_RUN_MATCH

	ld	de, KW_NEW
	call	MATCH_KEYWORD
	jr	c, TK_NEW_MATCH

	ld	de, KW_EXIT
	call	MATCH_KEYWORD
	jr	c, TK_EXIT_MATCH

	ld	de, KW_FREE
	call	MATCH_KEYWORD
	jr	c, TK_FREE_MATCH

	ld	de, KW_RND
	call	MATCH_KEYWORD
	jr	c, TK_RND_MATCH

	ld	de, KW_ABS
	call	MATCH_KEYWORD
	jr	c, TK_ABS_MATCH

	; No keyword matched → single-letter variable
	ld	a, (hl)
	sub	'A'
	add	a, TK_VAR		; TK_VAR + letter index
	ld	(de), a
	inc	de
	inc	hl
	jp	TOK_SKIP_SPACES

; --- Keyword match handlers ---
TK_PRINT_MATCH:
	ld	a, TK_PRINT
	jr	TK_KW_STORE
TK_LET_MATCH:
	ld	a, TK_LET
	jr	TK_KW_STORE
TK_IF_MATCH:
	ld	a, TK_IF
	jr	TK_KW_STORE
TK_GOTO_MATCH:
	ld	a, TK_GOTO
	jr	TK_KW_STORE
TK_GOSUB_MATCH:
	ld	a, TK_GOSUB
	jr	TK_KW_STORE
TK_INPUT_MATCH:
	ld	a, TK_INPUT
	jr	TK_KW_STORE
TK_RETURN_MATCH:
	ld	a, TK_RETURN
	jr	TK_KW_STORE
TK_THEN_MATCH:
	ld	a, TK_THEN
	jr	TK_KW_STORE
TK_END_MATCH:
	ld	a, TK_END
	jr	TK_KW_STORE
TK_LIST_MATCH:
	ld	a, TK_LIST
	jr	TK_KW_STORE
TK_RUN_MATCH:
	ld	a, TK_RUN
	jr	TK_KW_STORE
TK_NEW_MATCH:
	ld	a, TK_NEW
	jr	TK_KW_STORE
TK_EXIT_MATCH:
	ld	a, TK_EXIT
	jr	TK_KW_STORE
TK_FREE_MATCH:
	ld	a, TK_FREE
	jr	TK_KW_STORE
TK_RND_MATCH:
	ld	a, TK_RND
	jr	TK_KW_STORE
TK_ABS_MATCH:
	ld	a, TK_ABS

TK_KW_STORE:
	ld	(de), a			; store token
	inc	de
	jp	TOK_SKIP_SPACES

TK_REM_MATCH:
	; REM ignores the rest of the line
	ld	a, TK_REM
	ld	(de), a
	inc	de
	jp	TOK_DONE

; --- Operators: < > ---
TOK_LT:
	inc	hl			; skip '<'
	ld	a, (hl)
	cp	'>'
	jr	z, TOK_NE
	cp	'='
	jr	z, TOK_LE

	; Just '<'
	ld	a, '<'
	ld	(de), a
	inc	de
	jp	TOK_SKIP_SPACES

TOK_NE:
	inc	hl
	ld	a, TK_NE
	ld	(de), a
	inc	de
	jp	TOK_SKIP_SPACES

TOK_LE:
	inc	hl
	ld	a, TK_LE
	ld	(de), a
	inc	de
	jp	TOK_SKIP_SPACES

TOK_GT:
	inc	hl			; skip '>'
	ld	a, (hl)
	cp	'='
	jr	z, TOK_GE

	; Just '>'
	ld	a, '>'
	ld	(de), a
	inc	de
	jp	TOK_SKIP_SPACES

TOK_GE:
	inc	hl
	ld	a, TK_GE
	ld	(de), a
	inc	de
	jp	TOK_SKIP_SPACES

; -----------------------------------------------------------------------
TOK_DONE:
	xor	a
	ld	(de), a			; null terminator

	ld	hl, MEM_TOKEN_BUF
	ld	(MEM_TOKEN_PTR), hl
	ret
