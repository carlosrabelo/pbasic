; rst.asm - RST vector table for PBasic Z80
; -----------------------------------------------------------------------
; RST vectors provide single-byte call instructions to fixed addresses.
; Each slot is 8 bytes. Execution starts at $0000 after reset.
;
; RST 0 ($C7) - System reset / restart
; RST 1 ($CF) - OUTCHAR: output character in A to TTY
; RST 2 ($D7) - INCHAR: read character from TTY into A (blocking)
; RST 3-7    - Reserved (ret)
; -----------------------------------------------------------------------

	org	$0000

; RST 0 — Reset / Entry point
	jp	START
	ds	5

; RST 1 — OUTCHAR: output character in A to TTY
	out	(0), a
	ret
	ds	5

; RST 2 — INCHAR: read character from TTY into A (blocking)
; Polls STATUS ($01) bit 0 (RX ready), then reads DATA ($00).
RST_INCHAR:
	in	a, (1)
	rra
	jr	nc, RST_INCHAR
	in	a, (0)
	ret

; RST 3 — Reserved
	ret
	ds	7

; RST 4 — Reserved
	ret
	ds	7

; RST 5 — Reserved
	ret
	ds	7

; RST 6 — Reserved
	ret
	ds	7

; RST 7 — Reserved / IM 1 interrupt
	ret
