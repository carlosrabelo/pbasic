; cmd_return.asm - RETURN command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_RETURN - Pops a line pointer from the stack and resumes execution
; Input: None
; Output: None (jumps to REPL_LOOP to fetch the next line)
; Clobbers: AF, DE, HL
; -----------------------------------------------------------------------
DO_RETURN:
    ld      A, (MEM_GOSUB_SP)   ; Load the current stack pointer depth
    or      A                   ; Check if it is zero
    jr      z, RETURN_ERR       ; If stack is empty, jump to error (underflow)

    dec     A                   ; Decrement stack pointer (pop)
    ld      (MEM_GOSUB_SP), A   ; Save updated stack pointer

    add     A, A                ; Multiply stack pointer by 2 (2 bytes per pointer)
    ld      E, A                ; Store offset in E
    ld      D, 0                ; Clear D (DE = offset)
    ld      HL, MEM_GOSUB_STK   ; Load base address of the GOSUB stack
    add     HL, DE              ; Add offset to base address (HL = stack slot address)

    ld      E, (HL)             ; Load low byte of the saved line pointer from stack
    inc     HL                  ; Move to next byte
    ld      D, (HL)             ; Load high byte of the saved line pointer from stack

    ld      (MEM_LINE_PTR), DE  ; Restore the line pointer
    jp      REPL_LOOP           ; Return to REPL_LOOP. It will naturally advance to the 'next' line.

; -----------------------------------------------------------------------
; RETURN_ERR - Handles stack underflow errors
; -----------------------------------------------------------------------
RETURN_ERR:
    call    PRINT_ERROR         ; Print syntax/general error
    jp      REPL_LOOP           ; Return to interactive prompt
