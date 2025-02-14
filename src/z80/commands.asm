; commands.asm - Command dispatch engine for PBasic Z80
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; REPL_DISPATCH - Analyze token buffer and execute commands
; -----------------------------------------------------------------------
; Reads the first byte of MEM_TOKEN_BUF and dispatches:
;   - 0xC0 (TK_NUM): program line  ->  LINE_STORE
;   - 0x88 (TK_LIST): LIST command  ->  CMD_LIST
;   - 0x00 or other: no-op for now
;
; Input:  MEM_TOKEN_BUF (tokenized line), MEM_TOKEN_PTR
; Output: None
; Clobbers: All
; -----------------------------------------------------------------------
REPL_DISPATCH:
	ld	hl, MEM_TOKEN_BUF
	ld	a, (hl)

	or	a
	ret	z			; empty line -> ignore

	cp	TK_NUM
	jr	z, RD_LINE_NUM

	cp	TK_LIST
	jr	z, RD_LIST

	ret				; unrecognized -> ignore

RD_LINE_NUM:
	call	LINE_STORE
	ret

RD_LIST:
	call	CMD_LIST
	ret

; -----------------------------------------------------------------------
; CMD_LIST - List all program lines
; -----------------------------------------------------------------------
; Walks the linked list at MEM_PROG_START and prints each line as:
;   <line_number> <tokens>\r\n
;
; Stack layout during one iteration:
;   [node_tok] [node_ln] [next]
;
; Input:  None
; Output: None
; Clobbers: A, B, C, D, E, H, L
; -----------------------------------------------------------------------
CMD_LIST:
	ld	hl, MEM_PROG_START

CML_LOOP:
	; Read next_ptr (2 bytes at HL) into DE
	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = next_ptr
	dec	hl			; HL = node start

	; End of list?
	ld	a, d
	or	e
	ret	z			; null -> done

	; Save next_ptr (C), node for tokens (B), node for line (A)
	push	de			; (C) next_ptr
	push	hl			; (B) node_tok
	push	hl			; (A) node_ln

	; --- Print line number ---
	pop	hl			; HL = node_ln		[B, C]
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
	pop	hl			; HL = node_tok		[C]
	inc	hl
	inc	hl
	inc	hl
	inc	hl			; HL = token slot
	call	PRINT_TOKENS
	call	PRINT_CRLF

	; --- Advance ---
	pop	hl			; HL = next_ptr		[]
	jr	CML_LOOP
