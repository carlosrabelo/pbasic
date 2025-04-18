; repl.asm - REPL loop and dispatch for PBasic (Z80)
; -----------------------------------------------------------------------
; Implements the Read-Eval-Print Loop (REPL) and the main instruction
; dispatch logic for interactive mode and program execution.
; -----------------------------------------------------------------------

; --- Helpers ---

; -----------------------------------------------------------------------
; PRINT_OK - Print "OK" + CRLF
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
PRINT_OK:
    push    AF                  ; Save AF
    push    HL                  ; Save HL
    ld      HL, MSG_OK          ; Load pointer to "OK" string
    call    PRINT_STR           ; Print it
    call    PRINT_CRLF          ; Print newline
    pop     HL                  ; Restore HL
    pop     AF                  ; Restore AF
    ret                         ; Return

; -----------------------------------------------------------------------
; PRINT_ERROR - Print "?SYNTAX ERROR" + CRLF
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
PRINT_ERROR:
    push    AF                  ; Save AF
    push    HL                  ; Save HL
    ld      HL, MSG_ERROR       ; Load pointer to error string
    call    PRINT_STR           ; Print it
    call    PRINT_CRLF          ; Print newline
    pop     HL                  ; Restore HL
    pop     AF                  ; Restore AF
    ret                         ; Return

; --- REPL (token-based dispatch) ---

; -----------------------------------------------------------------------
; REPL - Main entry point for the interactive prompt
; -----------------------------------------------------------------------
REPL:
    ld      HL, MSG_BANNER      ; Load banner string
    call    PRINT_STR           ; Print banner
    call    PRINT_CRLF          ; Print newline

REPL_LOOP:
    ld      A, (MEM_RUN_FLAG)   ; Check if a program is currently running
    or      A                   ; Is it 0?
    jp      nz, RUN_NEXT        ; If not 0 (running), jump to execute the next line

    ; Interactive mode
    ld      HL, MSG_PROMPT      ; Load "> " prompt string
    call    PRINT_STR           ; Print prompt
    call    READ_LINE           ; Read a line of text from the user into MEM_INPUT_BUF
    call    TO_UPPER_BUF        ; Convert the input to uppercase (excluding strings)
    call    TOKENIZE            ; Convert ASCII text into tokens in MEM_TOKEN_BUF

    ld      HL, MEM_TOKEN_BUF   ; Point HL to the start of the tokenized buffer

REPL_DISPATCH:
    ld      A, (HL)             ; Read the first token
    or      A                   ; Is it 0x00 (empty line)?
    jp      z, REPL_LOOP        ; If empty, just prompt again

    cp      0xC0                ; Is the first token a number literal? (Line Number)
    jp      z, REPL_STORE       ; If so, this is a line insertion/deletion command

    cp      0xA0                ; Is the token FREE?
    jr      nz, RD_NOT_FREE
    inc     HL                  ; Advance HL past the command keyword token
    jp      DO_FREE
RD_NOT_FREE:

    cp      0x80                ; Is the token < 0x80? (e.g. string, math op without print/let)
    jp      c, REPL_SYNTAX_ERROR ; If so, it's not a valid statement keyword. Syntax error!

    cp      0x8D                ; Is the token >= 0x8D?
    jp      nc, REPL_SYNTAX_ERROR ; Unrecognized or invalid start token

    ; --- O(1) Command Dispatch via Jump Table ---
    ; Token is between 0x80 and 0x8C. Calculate offset: (A - 0x80) * 2
    inc     HL                  ; Advance HL past the command keyword token
    push    HL                  ; Save token stream pointer (we need HL for math)

    sub     0x80                ; A = 0 to 12
    add     A, A                ; A = A * 2 (each pointer is 2 bytes)
    ld      C, A
    ld      B, 0                ; BC = offset

    ld      HL, CMD_JUMP_TABLE  ; Base address of jump table
    add     HL, BC              ; HL = table + offset

    ld      E, (HL)             ; Read low byte of target address
    inc     HL
    ld      D, (HL)             ; Read high byte of target address
    ex      DE, HL              ; HL = target address

    ; Z80 elegant indirect jump trick:
    ; The token stream pointer is currently on top of the stack.
    ; We swap it with the target address (HL).
    ; Now HL = token stream pointer, and Stack Top = target address.
    ex      (SP), HL
    ret                         ; 'ret' pops the target address into PC, jumping to the command!


; -----------------------------------------------------------------------
; RUN_NEXT - Execute the next line of a running program
; -----------------------------------------------------------------------
RUN_NEXT:
    ; Check if user has requested to break/cancel execution
    call    CHECK_BREAK         ; Non-blocking keyboard status poll (Returns A=1 if break, 0 otherwise)
    or      A                   ; Test register A
    jr      z, RN_CONTINUE      ; If zero (no break requested), continue executing the next line

    ; Abort execution, clean up run flag, and return to prompt
    xor     A                   ; A = 0
    ld      (MEM_RUN_FLAG), A   ; Set running program state flag to 0 (disabled)
    jp      REPL_LOOP           ; Return back to interactive prompt

RN_CONTINUE:
    ld      HL, (MEM_LINE_PTR)  ; Get pointer to current line node
    ld      E, (HL)             ; Load next-ptr low
    inc     HL
    ld      D, (HL)             ; Load next-ptr high
    ex      DE, HL              ; HL = next-ptr (the line we want to execute now)

    ld      A, (HL)             ; Read low byte of its next-ptr to check for sentinel
    inc     HL
    or      (HL)                ; OR with high byte
    jr      z, RUN_END          ; If next-ptr is 0x0000, we hit the end of the program

    dec     HL                  ; Backtrack HL to start of node
    ld      (MEM_LINE_PTR), HL  ; Update MEM_LINE_PTR to this new line

    ; Advance HL to point to the tokens
    inc     HL                  ; Skip next-ptr (L)
    inc     HL                  ; Skip next-ptr (H)
    inc     HL                  ; Skip line-num (L)
    inc     HL                  ; Skip line-num (H)
                                ; HL now points to the first token of the line

    jp      REPL_DISPATCH       ; Dispatch the token to execute it

; -----------------------------------------------------------------------
; RUN_END - Cleanly terminate program execution
; -----------------------------------------------------------------------
RUN_END:
    xor     A                   ; Clear A (0)
    ld      (MEM_RUN_FLAG), A   ; Clear run flag to switch back to interactive mode
    jp      REPL_LOOP           ; Return to prompt

; -----------------------------------------------------------------------
; REPL_STORE - Handle storing a numbered line into memory
; -----------------------------------------------------------------------
REPL_STORE:
    call    LINE_STORE          ; Call memory manager to insert/delete line
    jp      REPL_LOOP           ; Return to prompt

; -----------------------------------------------------------------------
; REPL_SYNTAX_ERROR - Handle syntax errors
; -----------------------------------------------------------------------
REPL_SYNTAX_ERROR:
    call    PRINT_ERROR         ; Print error
    jp      REPL_LOOP           ; Return to prompt
