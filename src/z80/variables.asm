; variables.asm - Variable storage routines (Z80)
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
