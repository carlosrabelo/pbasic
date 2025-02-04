; memmgr.asm - Program memory management (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; PROG_INIT - Initialize program memory with sentinel
; -----------------------------------------------------------------------
; Writes a 16-bit zero sentinel to MEM_PROG_START and sets MEM_PROG_END
; to point past it, marking an empty linked list.
; -----------------------------------------------------------------------
PROG_INIT:
	ld	hl, MEM_PROG_START
	xor	a
	ld	(hl), a			; sentinel low byte = 0
	inc	hl
	ld	(hl), a			; sentinel high byte = 0
	inc	hl
	ld	(MEM_PROG_END), hl	; save end pointer
	ret
