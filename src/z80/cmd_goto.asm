; cmd_goto.asm - GOTO command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_GOTO - Jumps execution to a specific line number
; Input: HL points to the expression after the GOTO token
; Output: None (jumps to REPL_DISPATCH on success, REPL_LOOP on error)
; Clobbers: AF, BC, HL
; -----------------------------------------------------------------------
DO_GOTO:
    ld      (MEM_TOKEN_PTR), HL ; Save the current token pointer before evaluating expression
    call    EVAL_EXPR           ; Evaluate the expression to get the target line number in HL
    ld      B, H                ; Move high byte of target line to B
    ld      C, L                ; Move low byte of target line to C (BC = target line)
    call    LINE_FIND           ; Search the linked list for the line number in BC
    jr      nz, DG_ERR          ; If zero flag is not set (line not found), jump to error handler
    ld      A, 1                ; Set A = 1 (true)
    ld      (MEM_RUN_FLAG), A   ; Ensure the run flag is set to continue execution
    ld      (MEM_LINE_PTR), HL  ; Update the current line pointer to the found line's node
    inc     HL                  ; Skip low byte of 'next' pointer
    inc     HL                  ; Skip high byte of 'next' pointer
    inc     HL                  ; Skip low byte of line number
    inc     HL                  ; Skip high byte of line number (HL now points to tokens)
    jp      REPL_DISPATCH       ; Jump to dispatch to immediately execute the target line

; -----------------------------------------------------------------------
; DG_ERR - Handles line not found error for GOTO
; -----------------------------------------------------------------------
DG_ERR:
    call    PRINT_ERROR         ; Print syntax/general error
    jp      REPL_LOOP           ; Return to interactive prompt
