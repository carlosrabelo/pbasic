; main.asm - PBasic interpreter entry point (Z80)
; -----------------------------------------------------------------------
; Runs from $0000 with initialized RST vectors in rst.asm.

	include	'rst.asm'

; =======================================================================
; Interpreter modules
; =======================================================================

	include	'defs.asm'
	include 'memmgr.asm'
	include 'variables.asm'
	include 'math.asm'
	include 'io.asm'
	include 'strings.asm'
	include 'util.asm'
	include 'tokenize.asm'
	include 'detokenize.asm'
	include 'expr.asm'
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
	call	RUN_NEXT
	jr	REPL
