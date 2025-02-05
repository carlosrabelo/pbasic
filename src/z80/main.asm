; main.asm - PBasic interpreter entry point (Z80)
; -----------------------------------------------------------------------
; Runs from $0000 with initialized RST vectors.

	org	$0000

; =======================================================================
; RST Vector Table
; All unused vectors are initialized with RET to prevent runaway code.
; =======================================================================

	jp	START			; RST 0 - Reset / Entry point
	ds	5			; padding to $0008

	ret				; RST 1
	ds	7			; padding to $0010

	ret				; RST 2
	ds	7			; padding to $0018

	ret				; RST 3
	ds	7			; padding to $0020

	ret				; RST 4
	ds	7			; padding to $0028

	ret				; RST 5
	ds	7			; padding to $0030

	ret				; RST 6
	ds	7			; padding to $0038

	ret				; RST 7 / IM 1 interrupt

; =======================================================================
; Interpreter modules
; =======================================================================

	include 'defs.asm'
	include 'memmgr.asm'
	include 'variables.asm'
	include 'io.asm'
	include 'strings.asm'

; =======================================================================
; START - System initialization
; =======================================================================
START:
	ld	sp, STACK_TOP

	ld	hl, MSG_BANNER
	call	PRINT_STR

	call	PROG_INIT

	call	VAR_INIT

	di
	halt
