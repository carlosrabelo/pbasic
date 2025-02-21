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
	; --- RND function (0xA1) ---
	cp	TK_RND
	jr	nz, EF_NOT_RND

	inc	hl			; advance past RND token
	ld	(MEM_TOKEN_PTR), hl

	call	EVAL_FACTOR		; HL = argument (handles parens or 0)

	ld	a, h
	or	l
	jr	z, EF_RND_ZERO		; arg == 0: return raw random

	push	hl			; save arg
	call	RAND16			; HL = random value
	pop	de			; DE = arg
	ex	de, hl			; HL = arg, DE = random
	call	MOD16			; HL = random % arg
	inc	hl			; HL = (random % arg) + 1
	ret

EF_RND_ZERO:
	call	RAND16			; HL = raw random
	ret

EF_NOT_RND:
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

; -----------------------------------------------------------------------
; EVAL_COND - Evaluate a condition (expr relop expr)
; -----------------------------------------------------------------------
; Input:  MEM_TOKEN_PTR (token stream position)
; Output: HL = 1 if true, 0 if false
; Clobbers: A, B, C, D, E
; -----------------------------------------------------------------------
EVAL_COND:
	call	EVAL_EXPR		; HL = left side
	push	hl			; save left

	ld	hl, (MEM_TOKEN_PTR)
	ld	a, (hl)			; A = operator token
	push	af			; save operator
	inc	hl			; advance past operator
	ld	(MEM_TOKEN_PTR), hl

	call	EVAL_EXPR		; HL = right side
	pop	af			; A = operator
	ex	de, hl			; DE = right side
	pop	hl			; HL = left side

	cp	'='
	jr	z, EC_EQ

	cp	TK_NE
	jr	z, EC_NE

	cp	'<'
	jr	z, EC_LT

	cp	'>'
	jr	z, EC_GT

	cp	TK_LE
	jr	z, EC_LE

	cp	TK_GE
	jr	z, EC_GE

	jr	EC_FALSE		; unknown operator

EC_EQ:
	or	a
	sbc	hl, de
	jr	z, EC_TRUE
	jr	EC_FALSE

EC_NE:
	or	a
	sbc	hl, de
	jr	nz, EC_TRUE
	jr	EC_FALSE

EC_LT:
	call	CMP_SIGNED_LT		; HL < DE?
	jr	c, EC_TRUE
	jr	EC_FALSE

EC_GT:
	ex	de, hl
	call	CMP_SIGNED_LT		; DE < HL?
	jr	c, EC_TRUE
	jr	EC_FALSE

EC_LE:
	ex	de, hl
	call	CMP_SIGNED_LT		; DE < HL? (strict)
	jr	c, EC_FALSE
	jr	EC_TRUE

EC_GE:
	call	CMP_SIGNED_LT		; HL < DE? (strict)
	jr	c, EC_FALSE
	jr	EC_TRUE

EC_TRUE:
	ld	hl, 1
	ret

EC_FALSE:
	ld	hl, 0
	ret

; -----------------------------------------------------------------------
; CMP_SIGNED_LT - Signed 16-bit less-than comparison
; -----------------------------------------------------------------------
; Input:  HL, DE = values to compare
; Output: carry set if HL < DE (signed), carry clear if HL >= DE
; Clobbers: A
; -----------------------------------------------------------------------
CMP_SIGNED_LT:
	ld	a, h
	xor	d			; check if signs differ
	bit	7, a
	jr	nz, CSLT_DIFF

	push	hl
	or	a
	sbc	hl, de			; same signs: unsigned = signed
	pop	hl
	ret				; carry preserved across pop

CSLT_DIFF:
	bit	7, h			; HL negative?
	jr	nz, CSLT_TRUE		; HL neg, DE pos → HL < DE
	or	a			; HL pos, DE neg → HL >= DE
	ret

CSLT_TRUE:
	scf				; HL < DE
	ret
