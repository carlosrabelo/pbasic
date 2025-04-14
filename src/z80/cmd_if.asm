; cmd_if.asm - IF command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_IF - Evaluates a condition and executes the THEN clause if true
; Input: HL points to the expression before the comparison operator
; Output: None (delegates to the respective command handler if true)
; Clobbers: AF, BC, DE, HL
; -----------------------------------------------------------------------
DO_IF:
    ld      (MEM_TOKEN_PTR), HL ; Save the token pointer to evaluate the condition
    call    EVAL_COND           ; Evaluate the condition, result returned in HL (0=false, non-zero=true)
    ld      A, H                ; Check if HL is zero
    or      L                   ; (H OR L)
    jp      z, REPL_LOOP        ; If condition is false (HL=0), skip the rest of the line (jump to REPL_LOOP)
    ld      HL, (MEM_TOKEN_PTR) ; If true, retrieve the token pointer (now pointing after the condition)
    ld      A, (HL)             ; Load the next token
    cp      0x8D                ; Check if it is 'THEN' (Token 0x8D)
    jp      nz, DI_ERR          ; If not 'THEN', syntax error
    inc     HL                  ; Skip the 'THEN' token
    ld      A, (HL)             ; Load the command token following 'THEN'
    cp      0x80                ; Compare with 0x80 (Lowest command token)
    jp      c, DI_ERR           ; If less than 0x80, it's not a command, syntax error
    inc     HL                  ; Skip the command token, HL now points to the command arguments
    cp      0x83                ; Is it PRINT?
    jp      z, DO_PRINT
    cp      0x80                ; Is it LET?
    jp      z, DO_LET
    cp      0x81                ; Is it GOTO?
    jp      z, DO_GOTO
    cp      0x82                ; Is it GOSUB?
    jp      z, DO_GOSUB
    cp      0x84                ; Is it IF? (IF THEN IF)
    jp      z, DO_IF
    cp      0x85                ; Is it INPUT?
    jp      z, DO_INPUT
    cp      0x86                ; Is it RETURN?
    jp      z, DO_RETURN
    cp      0x87                ; Is it END?
    jp      z, DO_END
    cp      0x8C                ; Is it REM?
    jp      z, DO_REM
    cp      0xA0                ; Is it FREE?
    jp      z, DO_FREE
DI_ERR:
    call    PRINT_ERROR         ; Print syntax error
    jp      REPL_LOOP           ; Return to interactive prompt
