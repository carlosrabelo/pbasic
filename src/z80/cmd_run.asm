; cmd_run.asm - RUN command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_RUN - Begins execution of the stored BASIC program
; Input: None
; Output: None
; Clobbers: AF, HL
; -----------------------------------------------------------------------
DO_RUN:
    ld      HL, MEM_PROG_START  ; Point HL to the start of the program memory area
    ld      A, (HL)             ; Load the low byte of the first line's 'next' pointer
    inc     HL                  ; Move to the high byte
    or      (HL)                ; OR low byte with high byte to check if the pointer is 0x0000 (sentinel)
    jp      z, RUN_NO_PROG      ; If both are zero, the program area is empty
    xor     A                   ; Clear A register (A = 0)
    ld      (MEM_GOSUB_SP), A   ; Reset GOSUB stack pointer to 0 before starting execution
    ld      A, 1                ; Set A = 1 (true)
    ld      (MEM_RUN_FLAG), A   ; Enable the execution flag so REPL loop knows a program is running
    ld      HL, MEM_PROG_START  ; Point HL back to the first line's start
    ld      (MEM_LINE_PTR), HL  ; Save this as the currently executing line
    inc     HL                  ; Skip low byte of 'next' pointer
    inc     HL                  ; Skip high byte of 'next' pointer
    inc     HL                  ; Skip low byte of line number
    inc     HL                  ; Skip high byte of line number (HL now points to the first token)
    jp      REPL_DISPATCH       ; Jump to the main dispatch loop to execute this line

; -----------------------------------------------------------------------
; RUN_NO_PROG - Handles the error when trying to run an empty program
; -----------------------------------------------------------------------
RUN_NO_PROG:
    push    HL                  ; Save HL pointer
    ld      HL, MSG_NO_PROGRAM  ; Load address of the "?NO PROGRAM" error string
    call    PRINT_STR           ; Print the string to the TTY
    call    PRINT_CRLF          ; Print a carriage return / line feed
    pop     HL                  ; Restore HL
    jp      REPL_LOOP           ; Return to the interactive prompt
