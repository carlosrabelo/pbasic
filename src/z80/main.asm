; main.asm - PBasic interpreter entry point (Z80)
; -----------------------------------------------------------------------

	org	$8000

	include 'defs.asm'
	include 'memmgr.asm'
	include 'variables.asm'

; -----------------------------------------------------------------------
; START - System initialization
; -----------------------------------------------------------------------
start:
	ld	sp, STACK_TOP

	call	PROG_INIT

	call	VAR_INIT

	di
	halt
