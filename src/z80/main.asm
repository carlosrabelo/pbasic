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
	include 'math.asm'
	include 'io.asm'
	include 'strings.asm'
	include 'util.asm'
	include 'tokenize.asm'
	include 'detokenize.asm'
	include 'commands.asm'

; =======================================================================
; START - System initialization
; =======================================================================
START:
	ld	sp, STACK_TOP

	ld	hl, MSG_BANNER
	call	PRINT_STR

	call	PROG_INIT

	call	VAR_INIT

	call	REPL

	di
	halt

; =======================================================================
; REPL - Read-Eval-Print Loop
; =======================================================================
; Main interactive loop. Prompts the user, reads input, and dispatches.
; -----------------------------------------------------------------------
REPL:
	ld	a, (MEM_RUN_FLAG)
	or	a
	jr	nz, REPL_RUN_NEXT	; running a program → execute next line

	ld	hl, STR_PROMPT
	call	PRINT_STR

	call	READ_LINE

	call	TOKENIZE

	call	REPL_DISPATCH

	jr	REPL

REPL_RUN_NEXT:
	; stub: will execute next program line
	jr	REPL
