; cmd_free.asm - FREE command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_FREE - Calculates and prints the remaining free memory bytes
; Input: None
; Output: None
; Clobbers: AF, DE, HL
; -----------------------------------------------------------------------
DO_FREE:
    ld      DE, (MEM_PROG_END)  ; Load the end of the program memory into DE
    ld      HL, 0xF000          ; Load the top of the program memory area (MEM_VARS) into HL
    xor     A                   ; Clear carry flag
    sbc     HL, DE              ; Subtract DE from HL (HL = 0xF000 - MEM_PROG_END)
    call    PRINT_NUMBER        ; Print the result (free memory in bytes)
    call    PRINT_CRLF          ; Print a newline
    jp      REPL_LOOP           ; Return to interactive prompt
