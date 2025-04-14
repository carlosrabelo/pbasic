; cmd_gosub.asm - GOSUB command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_GOSUB - Pushes the current line onto the stack and jumps to a target
; Input: HL points to the expression after the GOSUB token
; Output: None (jumps to REPL_DISPATCH on success, REPL_LOOP on error)
; Clobbers: AF, BC, DE, HL
; -----------------------------------------------------------------------
DO_GOSUB:
    ld      (MEM_TOKEN_PTR), HL ; Save the token pointer before evaluating expression
    ld      A, (MEM_GOSUB_SP)   ; Load the current stack pointer depth
    cp      GOSUB_DEPTH         ; Check if we reached the max depth (16)
    jr      z, GOSUB_ERR        ; If stack is full, jump to error (overflow)

    add     A, A                ; Multiply stack pointer by 2 (2 bytes per pointer)
    ld      E, A                ; Store offset in E
    ld      D, 0                ; Clear D (DE = offset)
    ld      HL, MEM_GOSUB_STK   ; Load base address of the GOSUB stack
    add     HL, DE              ; Add offset to base address (HL = stack slot address)

    ld      DE, (MEM_LINE_PTR)  ; Load the current line pointer into DE
    ld      (HL), E             ; Store low byte of the line pointer onto the stack
    inc     HL                  ; Move to next byte
    ld      (HL), D             ; Store high byte of the line pointer onto the stack

    ld      A, (MEM_GOSUB_SP)   ; Reload stack pointer
    inc     A                   ; Increment stack pointer (push)
    ld      (MEM_GOSUB_SP), A   ; Save updated stack pointer

    call    EVAL_EXPR           ; Evaluate target line number expression, result in HL
    ld      B, H                ; Move high byte to B
    ld      C, L                ; Move low byte to C (BC = target line number)
    call    LINE_FIND           ; Search for the target line
    jr      nz, GOSUB_ERR       ; If not found (Zero flag not set), error

    ld      A, 1                ; Set A = 1 (true)
    ld      (MEM_RUN_FLAG), A   ; Ensure run flag is set
    ld      (MEM_LINE_PTR), HL  ; Update the current line pointer to the subroutine target
    inc     HL                  ; Skip low byte of 'next' pointer
    inc     HL                  ; Skip high byte of 'next' pointer
    inc     HL                  ; Skip low byte of line number
    inc     HL                  ; Skip high byte of line number (HL now points to tokens)
    jp      REPL_DISPATCH       ; Dispatch execution to the subroutine

; -----------------------------------------------------------------------
; GOSUB_ERR - Handles stack overflow or line not found errors
; -----------------------------------------------------------------------
GOSUB_ERR:
    call    PRINT_ERROR         ; Print syntax/general error
    jp      REPL_LOOP           ; Return to interactive prompt
