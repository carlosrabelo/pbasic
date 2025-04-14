; cmd_end.asm - END command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_END - Terminates the execution of the running program
; Input: None
; Output: None
; Clobbers: AF
; -----------------------------------------------------------------------
DO_END:
    xor     A                   ; Clear A register
    ld      (MEM_RUN_FLAG), A   ; Clear the run flag, indicating the program has stopped
    jp      REPL_LOOP           ; Return to the interactive prompt
