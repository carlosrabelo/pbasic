; cmd_new.asm - NEW command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_NEW - Clears the program memory and resets all variables
; Input: None
; Output: None
; Clobbers: AF
; -----------------------------------------------------------------------
DO_NEW:
    call    PROG_INIT           ; Initialize the program memory area (write the 0x0000 sentinel)
    call    VAR_INIT            ; Zero out all 26 variables (A-Z)
    xor     A                   ; Clear A register (A = 0)
    ld      (MEM_GOSUB_SP), A   ; Reset the GOSUB call stack pointer
    call    PRINT_OK            ; Print the "OK" message indicating success
    jp      REPL_LOOP           ; Return to the interactive prompt
