; cmd_let.asm - LET command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_LET - Assigns an evaluated expression to a variable (A-Z)
; Input: HL points to the variable token after the LET keyword
; Output: None
; Clobbers: AF, DE, HL
; -----------------------------------------------------------------------
DO_LET:
    ld      A, (HL)             ; Load the variable token into A
    cp      0xD0                ; Compare with 0xD0 (Token for 'A')
    jr      c, DL_ERR           ; If less than 0xD0, it's not a valid variable, error
    cp      0xEA                ; Compare with 0xEA (Token after 'Z')
    jr      nc, DL_ERR          ; If greater or equal to 0xEA, it's not a valid variable, error
    ld      (MEM_SCRATCH), A    ; Temporarily save the variable token to memory
    inc     HL                  ; Advance HL to the next token
    ld      A, (HL)             ; Load the next token
    cp      '='                 ; Check if it's the assignment operator '='
    jr      nz, DL_ERR          ; If not '=', it's a syntax error
    inc     HL                  ; Advance HL past the '=' token
    ld      (MEM_TOKEN_PTR), HL ; Save current token pointer
    call    EVAL_EXPR           ; Evaluate the expression on the right side of '=', result in HL
    ld      A, (MEM_SCRATCH)    ; Retrieve the saved variable token (A-Z)
    call    VAR_SET             ; Store the 16-bit value in HL into the variable specified by A
    jp      REPL_LOOP           ; Return to the REPL loop (which will advance to the next line if running)

; -----------------------------------------------------------------------
; DL_ERR - Handles syntax errors in LET statements
; -----------------------------------------------------------------------
DL_ERR:
    call    PRINT_ERROR         ; Print syntax error
    jp      REPL_LOOP           ; Return to interactive prompt
