; cmd_rem.asm - REM command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_REM - Handles comments (REMarks)
; Input: None
; Output: None
; Clobbers: None
; -----------------------------------------------------------------------
DO_REM:
    jp      REPL_LOOP           ; Do nothing, just return to the REPL loop to advance to the next line
