; commands.asm - Command dispatch engine for PBasic Z80
; -----------------------------------------------------------------------
; Maps command tokens (0x80-0x8C) to handler routines via a jump table.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; REPL_DISPATCH - Analyze token buffer and dispatch commands
; -----------------------------------------------------------------------
; Reads the first byte of MEM_TOKEN_BUF and dispatches:
;   - 0x00         : empty line     -> ignore
;   - 0xC0 (TK_NUM): program line   -> LINE_STORE
;   - 0xA0 (TK_FREE): FREE command  -> DO_FREE
;   - 0x80-0x8C    : command tokens -> CMD_JUMP_TABLE
;   - other        : ignore
;
; Input:  MEM_TOKEN_BUF (tokenized line), MEM_TOKEN_PTR
; Output: None
; Clobbers: All
; -----------------------------------------------------------------------
REPL_DISPATCH:
	ld	hl, (MEM_TOKEN_PTR)
	ld	a, (hl)

	or	a
	ret	z			; empty line -> ignore

	cp	TK_NUM
	jr	z, RD_LINE_NUM

	cp	TK_FREE
	jr	z, RD_FREE

	; Valid command range: 0x80-0x8C
	cp	$80
	jr	c, RD_DONE		; < 0x80 -> ignore
	cp	$8D
	jr	nc, RD_DONE		; >= 0x8D -> ignore

	; Compute jump table offset: (token - 0x80) * 3
	sub	$80			; A = index (0-12)
	ld	e, a
	ld	d, 0			; DE = index
	ld	hl, CMD_JUMP_TABLE
	add	hl, hl			; HL = table + index * 2
	add	hl, de			; HL = table + index * 3

	; Advance MEM_TOKEN_PTR past the command token
	push	hl
	ld	hl, (MEM_TOKEN_PTR)
	inc	hl
	ld	(MEM_TOKEN_PTR), hl
	pop	hl

	jp	(hl)			; dispatch to handler

RD_LINE_NUM:
	call	LINE_STORE
	ret

RD_FREE:
	call	DO_FREE
	ret

RD_DONE:
	ret

; =======================================================================
; Command jump table (13 entries, 3 bytes each)
; Indexed by (token - 0x80) * 3
; =======================================================================
CMD_JUMP_TABLE:
	jp	DO_LET			; 0x80
	jp	DO_GOTO		; 0x81
	jp	DO_GOSUB		; 0x82
	jp	DO_PRINT		; 0x83
	jp	DO_IF			; 0x84
	jp	DO_INPUT		; 0x85
	jp	DO_RETURN		; 0x86
	jp	DO_END			; 0x87
	jp	DO_LIST		; 0x88
	jp	DO_RUN			; 0x89
	jp	DO_NEW			; 0x8A
	jp	DO_EXIT		; 0x8B
	jp	DO_REM			; 0x8C

; =======================================================================
; Command handlers (stubs for unimplemented commands)
; =======================================================================

DO_LET:
	ld	hl, (MEM_TOKEN_PTR)
	ld	a, (hl)			; variable token

	cp	TK_VAR
	jr	c, DL_ERR		; < 0xD0
	cp	$EA
	jr	nc, DL_ERR		; >= 0xEA

	push	af			; save variable token
	inc	hl
	ld	a, (hl)			; should be '='
	cp	'='
	jr	nz, DL_ERR_POP

	inc	hl			; past '='
	ld	(MEM_TOKEN_PTR), hl
	call	EVAL_EXPR		; HL = expression value

	pop	af			; A = variable token
	ex	de, hl			; DE = value
	call	VAR_SET			; A = token, DE = value
	ret

DL_ERR_POP:
	pop	af
DL_ERR:
	ret

DO_GOTO:
	call	EVAL_EXPR		; HL = target line number
	ld	b, h
	ld	c, l			; BC = target line number
	call	LINE_FIND		; HL = node, carry = 1 if found
	jr	nc, DG_ERR

	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = target node (next_ptr)

	ld	(MEM_LINE_PTR), de	; LINE_PTR = target
	ex	de, hl			; HL = target node
	inc	hl
	inc	hl
	inc	hl
	inc	hl			; HL = target + 4 = tokens
	ld	(MEM_TOKEN_PTR), hl

	ld	a, 1
	ld	(MEM_RUN_FLAG), a

	jp	REPL_DISPATCH

DG_ERR:
	xor	a
	ld	(MEM_RUN_FLAG), a
	ld	hl, MSG_ERROR
	call	PRINT_STR
	ret

DO_GOSUB:
	ld	a, (MEM_GOSUB_SP)
	cp	16
	jr	z, DGS_ERR		; stack overflow

	ld	hl, (MEM_LINE_PTR)	; current line pointer
	push	hl			; save for later

	ld	a, (MEM_GOSUB_SP)
	ld	d, 0
	ld	e, a			; DE = SP
	ld	hl, MEM_GOSUB_STK
	add	hl, de
	add	hl, de			; HL = STK + SP * 2

	pop	de			; DE = LINE_PTR
	ld	(hl), e
	inc	hl
	ld	(hl), d			; push LINE_PTR

	ld	a, (MEM_GOSUB_SP)
	inc	a
	ld	(MEM_GOSUB_SP), a	; SP++

	call	EVAL_EXPR		; HL = target line number
	ld	b, h
	ld	c, l
	call	LINE_FIND		; HL = node, carry = 1 if found
	jr	nc, DGS_ERR

	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = target node
	ld	(MEM_LINE_PTR), de

	ex	de, hl			; HL = target node
	inc	hl
	inc	hl
	inc	hl
	inc	hl			; HL = target + 4 = tokens
	ld	(MEM_TOKEN_PTR), hl

	ld	a, 1
	ld	(MEM_RUN_FLAG), a
	jp	REPL_DISPATCH

DGS_ERR:
	xor	a
	ld	(MEM_RUN_FLAG), a
	ld	hl, MSG_ERROR
	call	PRINT_STR
	ret

DO_IF:
	call	EVAL_COND		; HL = 1 (true) or 0 (false)
	ld	a, l
	or	a
	jr	z, DI_FALSE		; condition false → skip line

	; Condition true: expect THEN token
	ld	hl, (MEM_TOKEN_PTR)
	ld	a, (hl)
	cp	TK_THEN
	jr	nz, DI_ERR

	inc	hl			; advance past THEN
	ld	(MEM_TOKEN_PTR), hl

	; Dispatch command after THEN
	jp	REPL_DISPATCH

DI_FALSE:
	ret				; skip rest of line

DI_ERR:
	xor	a
	ld	(MEM_RUN_FLAG), a
	ld	hl, MSG_ERROR
	call	PRINT_STR
	ret

DO_INPUT:
	ret

DO_RETURN:
	ld	a, (MEM_GOSUB_SP)
	or	a
	jr	z, DRT_ERR		; stack underflow

	dec	a
	ld	(MEM_GOSUB_SP), a	; SP--

	ld	d, 0
	ld	e, a			; DE = new SP
	ld	hl, MEM_GOSUB_STK
	add	hl, de
	add	hl, de			; HL = STK + SP * 2

	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = saved LINE_PTR
	ld	(MEM_LINE_PTR), de
	ret				; return to REPL → RUN_NEXT

DRT_ERR:
	xor	a
	ld	(MEM_RUN_FLAG), a
	ld	hl, MSG_ERROR
	call	PRINT_STR
	ret

DO_END:
	xor	a
	ld	(MEM_RUN_FLAG), a
	ret

; -----------------------------------------------------------------------
; DO_RUN - Begin execution of the stored BASIC program
; -----------------------------------------------------------------------
; Input:  None
; Output: None
; Clobbers: A, D, E, H, L
; -----------------------------------------------------------------------
DO_RUN:
	ld	hl, (MEM_PROG_START)	; HL = sentinel.next_ptr
	ld	a, h
	or	l
	jr	z, DR_NO_PROG		; empty program

	ld	hl, 0
	ld	(MEM_GOSUB_SP), hl	; reset GOSUB stack

	ld	a, 1
	ld	(MEM_RUN_FLAG), a	; set run flag

	ld	hl, (MEM_PROG_START)	; HL = first node
	ld	(MEM_LINE_PTR), hl	; LINE_PTR = first node
	inc	hl
	inc	hl
	inc	hl
	inc	hl			; HL = first node + 4 = tokens
	ld	(MEM_TOKEN_PTR), hl

	jp	REPL_DISPATCH		; execute first line

DR_NO_PROG:
	ld	hl, MSG_ERROR
	call	PRINT_STR
	ret

; -----------------------------------------------------------------------
; DO_PRINT - Output expressions, string literals, formatting
; -----------------------------------------------------------------------
; Handles: numeric expressions, string literals (TK_STR), ',' (tab), ';'
; Input:  MEM_TOKEN_PTR (past PRINT token)
; Output: None
; Clobbers: A, B, C, D, E, H, L
; -----------------------------------------------------------------------
DO_PRINT:
DP_LOOP:
	ld	hl, (MEM_TOKEN_PTR)
	ld	a, (hl)			; current token

	or	a
	jr	z, DP_CRLF		; EOL -> print CRLF and exit

	cp	TK_STR			; 0xC1 = string literal
	jr	z, DP_STRING

	cp	';'
	jr	z, DP_SEMI

	cp	','
	jr	z, DP_COMMA

	; Otherwise: evaluate expression and print number
	call	EVAL_EXPR		; HL = value
	call	PRINT_NUMBER
	jr	DP_LOOP

DP_STRING:
	inc	hl			; skip opening TK_STR
DP_STR_LOOP:
	ld	a, (hl)
	cp	TK_STR			; closing marker?
	jr	z, DP_STR_END
	or	a
	jr	z, DP_STR_ABORT	; safety: null byte

	call	OUTCHAR
	inc	hl
	jr	DP_STR_LOOP

DP_STR_END:
	inc	hl			; skip closing TK_STR
DP_STR_ABORT:
	ld	(MEM_TOKEN_PTR), hl
	jr	DP_LOOP

DP_SEMI:
	inc	hl			; skip ';'
	ld	(MEM_TOKEN_PTR), hl
	ld	a, (hl)
	or	a
	ret	z			; EOL after ';' -> suppress CRLF
	jr	DP_LOOP

DP_COMMA:
	inc	hl			; skip ','
	ld	(MEM_TOKEN_PTR), hl
	ld	b, 8
DP_TAB_LOOP:
	ld	a, ' '
	call	OUTCHAR
	djnz	DP_TAB_LOOP
	jr	DP_LOOP

DP_CRLF:
	call	PRINT_CRLF
	ret

DO_LIST:
	call	CMD_LIST
	ret

DO_NEW:
	call	PROG_INIT
	call	VAR_INIT
	ld	hl, 0
	ld	(MEM_GOSUB_SP), hl
	ld	hl, MSG_OK
	call	PRINT_STR
	ret

DO_EXIT:
	di
	halt

DO_REM:
	ret

; -----------------------------------------------------------------------
; DO_FREE - Calculate and print remaining free memory
; -----------------------------------------------------------------------
DO_FREE:
	ld	hl, (MEM_PROG_END)
	ld	de, MEM_PROG_START + MEM_PROG_SIZE
	or	a
	sbc	hl, de
	ld	a, h
	cpl
	ld	h, a
	ld	a, l
	cpl
	ld	l, a
	inc	hl			; HL = -(MEM_PROG_END - buffer_end) = free bytes
	call	PRINT_NUMBER
	call	PRINT_CRLF
	ret

; -----------------------------------------------------------------------
; CMD_LIST - List all program lines
; -----------------------------------------------------------------------
; Walks the linked list at MEM_PROG_START and prints each line as:
;   <line_number> <tokens>\r\n
;
; Input:  None
; Output: None
; Clobbers: A, B, C, D, E, H, L
; -----------------------------------------------------------------------
CMD_LIST:
	ld	hl, MEM_PROG_START

CML_LOOP:
	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = next_ptr
	dec	hl			; HL = node start

	ld	a, d
	or	e
	ret	z			; null -> done

	push	de			; next_ptr
	push	hl			; node_tok
	push	hl			; node_ln

	; --- Print line number ---
	pop	hl			; HL = node_ln
	inc	hl
	inc	hl			; HL = line_num slot
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a			; HL = line number
	call	PRINT_NUMBER

	ld	a, ' '
	call	OUTCHAR

	; --- Print tokens ---
	pop	hl			; HL = node_tok
	inc	hl
	inc	hl
	inc	hl
	inc	hl			; HL = token slot
	call	PRINT_TOKENS
	call	PRINT_CRLF

	; --- Advance ---
	pop	hl			; HL = next_ptr
	jr	CML_LOOP

; -----------------------------------------------------------------------
; RUN_NEXT - Advance execution to the next program line
; -----------------------------------------------------------------------
; Reads MEM_LINE_PTR, follows next_ptr to the next node, updates
; LINE_PTR and TOKEN_PTR, and dispatches the next line's tokens.
;
; Input:  MEM_LINE_PTR (current node)
; Output: None (jp REPL_DISPATCH or RUN_END)
; Clobbers: A, D, E, H, L
; -----------------------------------------------------------------------
RUN_NEXT:
	ld	hl, (MEM_LINE_PTR)	; HL = current node
	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = current.next_ptr
	ld	a, d
	or	e
	jr	z, RUN_END		; next == null → end of program

	ld	(MEM_LINE_PTR), de	; LINE_PTR = next node
	ex	de, hl			; HL = next node
	inc	hl
	inc	hl
	inc	hl
	inc	hl			; HL = next node + 4 = tokens
	ld	(MEM_TOKEN_PTR), hl

	jp	REPL_DISPATCH

; -----------------------------------------------------------------------
; RUN_END - End program execution, return to interactive REPL
; -----------------------------------------------------------------------
RUN_END:
	xor	a
	ld	(MEM_RUN_FLAG), a
	ret
