; tokenize.asm - Lexical analysis (stub) for PBasic Z80
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; TOKENIZE - Convert ASCII input into internal token buffer
; -----------------------------------------------------------------------
; For Phase 1, this simply copies the input buffer to the token buffer.
; Phase 2 will replace this with actual keyword tokenization.
;
; Input:  MEM_INPUT_BUF (raw text)
; Output: MEM_TOKEN_BUF (tokenized), MEM_TOKEN_PTR set
; Clobbers: A, DE, HL
; -----------------------------------------------------------------------
TOKENIZE:
	ld	hl, MEM_INPUT_BUF
	ld	de, MEM_TOKEN_BUF

T_LOOP:
	ld	a, (hl)
	ld	(de), a
	or	a
	jr	z, T_DONE
	inc	hl
	inc	de
	jr	T_LOOP

T_DONE:
	ld	hl, MEM_TOKEN_BUF
	ld	(MEM_TOKEN_PTR), hl
	ret
