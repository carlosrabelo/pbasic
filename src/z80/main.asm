; main.asm - PBasic interpreter entry point (Z80)
; -----------------------------------------------------------------------
; This is the main compilation unit that includes all other modules.
; It defines the boot sequence and initializes the environment.
;
; RST vectors (0x0000-0x00FF) are defined in rst.asm, which is included
; first to ensure proper memory layout starting at address 0x0000.
; -----------------------------------------------------------------------

    include 'rst.asm'           ; RST vectors and entry point (org 0x0000)

    ; --- Module Inclusions ---
    include 'io.asm'
    include 'variables.asm'
    include 'util.asm'
    include 'strings.asm'
    include 'math.asm'
    include 'expr.asm'
    include 'tokenize.asm'
    include 'memmgr.asm'
    include 'lines.asm'
    include 'detokenize.asm'
    include 'repl.asm'
    include 'commands.asm'
    include 'cmd_print.asm'
    include 'cmd_if.asm'
    include 'cmd_let.asm'
    include 'cmd_input.asm'
    include 'cmd_goto.asm'
    include 'cmd_gosub.asm'
    include 'cmd_return.asm'
    include 'cmd_run.asm'
    include 'cmd_list.asm'
    include 'cmd_new.asm'
    include 'cmd_free.asm'
    include 'cmd_exit.asm'
    include 'cmd_end.asm'
    include 'cmd_rem.asm'
; -----------------------------------------------------------------------
; START - System initialization routine
; -----------------------------------------------------------------------
START:
    ld      SP, MEM_STACK       ; Initialize the Z80 hardware stack pointer
    call    PROG_INIT           ; Initialize program memory (write sentinel to MEM_PROG_START)
    call    VAR_INIT            ; Zero out all variables (A-Z)
    call    REPL                ; Enter the main Read-Eval-Print Loop (Interactive prompt)

; -----------------------------------------------------------------------
; HALT_LOOP - Safe fallback if REPL exits
; -----------------------------------------------------------------------
HALT_LOOP:
    jr      HALT_LOOP           ; Infinite loop to trap CPU
