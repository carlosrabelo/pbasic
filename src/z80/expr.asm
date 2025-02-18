; expr.asm - Expression evaluator for PBasic Z80
; -----------------------------------------------------------------------
; Recursive descent parser with standard precedence:
;   expr   = term (('+' | '-') term)*
;   term   = factor (('*' | '/') factor)*
;   factor = number | variable | '(' expr ')' | '-' factor
;
; Uses MEM_TOKEN_PTR as the token stream position.
; All arithmetic is 16-bit.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; EVAL_FACTOR - Evaluate a factor (number, variable, parens, unary minus)
; -----------------------------------------------------------------------
; Input:  MEM_TOKEN_PTR (token stream position)
; Output: HL = evaluated value (16-bit)
; Clobbers: A, DE
; -----------------------------------------------------------------------
EVAL_FACTOR:
	ld	hl, (MEM_TOKEN_PTR)
	ld	a, (hl)			; A = current token

	; --- Number literal (TK_NUM = 0xC0) ---
	cp	TK_NUM
	jr	nz, EF_NOT_NUM

	inc	hl
	ld	e, (hl)			; lo byte
	inc	hl
	ld	d, (hl)			; hi byte
	inc	hl			; past 0xC0 lo hi
	ld	(MEM_TOKEN_PTR), hl
	ex	de, hl			; HL = value
	ret

EF_NOT_NUM:
	; --- Variable token (0xD0-0xE9) ---
	cp	TK_VAR			; < 0xD0?
	jr	c, EF_NOT_VAR
	cp	$EA			; >= 0xEA?
	jr	nc, EF_NOT_VAR

	inc	hl			; advance past variable token
	ld	(MEM_TOKEN_PTR), hl	; (does not affect A)
	call	VAR_GET			; HL = variable value
	ret

EF_NOT_VAR:
	; --- Parenthesized expression '(' ---
	cp	'('
	jr	nz, EF_NOT_PAREN

	inc	hl			; past '('
	ld	(MEM_TOKEN_PTR), hl
	call	EVAL_EXPR		; HL = sub-expression
	ld	hl, (MEM_TOKEN_PTR)	; reload ptr (now at ')')
	inc	hl			; past ')'
	ld	(MEM_TOKEN_PTR), hl
	ret

EF_NOT_PAREN:
	; --- Unary minus '-' ---
	cp	'-'
	jr	nz, EF_ERR

	inc	hl			; past '-'
	ld	(MEM_TOKEN_PTR), hl
	call	EVAL_FACTOR		; HL = factor to negate

	ld	a, l
	cpl
	ld	l, a
	ld	a, h
	cpl
	ld	h, a			; HL = ~HL
	inc	hl			; HL = -HL (two's complement)
	ret

EF_ERR:
	ld	hl, 0			; syntax error: return 0
	ret

; -----------------------------------------------------------------------
; EVAL_TERM - Evaluate a term (handles * and /)
; -----------------------------------------------------------------------
; Input:  MEM_TOKEN_PTR (token stream position)
; Output: HL = evaluated value (16-bit)
; Clobbers: A, B, C, D, E
; -----------------------------------------------------------------------
EVAL_TERM:
	call	EVAL_FACTOR		; HL = first factor

ET_LOOP:
	push	hl			; save accumulator
	ld	hl, (MEM_TOKEN_PTR)
	ld	a, (hl)			; current token

	cp	'*'
	jr	z, ET_MUL

	cp	'/'
	jr	z, ET_DIV

	pop	hl			; HL = accumulated value
	ret

ET_MUL:
	inc	hl			; advance past '*'
	ld	(MEM_TOKEN_PTR), hl
	call	EVAL_FACTOR		; HL = next factor
	pop	de			; DE = old accumulator
	call	MUL16			; HL = accumulator * factor
	jr	ET_LOOP

ET_DIV:
	inc	hl			; advance past '/'
	ld	(MEM_TOKEN_PTR), hl
	call	EVAL_FACTOR		; HL = next factor
	pop	de			; DE = old accumulator
	ex	de, hl			; HL = accumulator, DE = divisor
	call	DIV16			; HL = quotient
	jr	ET_LOOP

; -----------------------------------------------------------------------
; EVAL_EXPR - Evaluate an expression (handles + and -)
; -----------------------------------------------------------------------
; Input:  MEM_TOKEN_PTR (token stream position)
; Output: HL = evaluated value (16-bit)
; Clobbers: A, B, C, D, E
; -----------------------------------------------------------------------
EVAL_EXPR:
	call	EVAL_TERM		; HL = first term

EE_LOOP:
	push	hl			; save accumulator
	ld	hl, (MEM_TOKEN_PTR)
	ld	a, (hl)			; current token

	cp	'+'
	jr	z, EE_ADD

	cp	'-'
	jr	z, EE_SUB

	pop	hl			; HL = accumulated value
	ret

EE_ADD:
	inc	hl			; advance past '+'
	ld	(MEM_TOKEN_PTR), hl
	call	EVAL_TERM		; HL = next term
	pop	de			; DE = old accumulator
	add	hl, de			; HL = accumulator + term
	jr	EE_LOOP

EE_SUB:
	inc	hl			; advance past '-'
	ld	(MEM_TOKEN_PTR), hl
	call	EVAL_TERM		; HL = next term
	ex	de, hl			; DE = term, HL = freed
	pop	hl			; HL = old accumulator
	or	a			; clear carry
	sbc	hl, de			; HL = accumulator - term
	jr	EE_LOOP
