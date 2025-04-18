; cmd_print.asm - PRINT command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_PRINT - Evaluates and prints expressions, strings, or formats output
; Input: HL points to the tokens following the PRINT keyword
; Output: None (prints to TTY)
; Clobbers: AF, BC, DE, HL
; -----------------------------------------------------------------------
DO_PRINT:
DP_LOOP:
    ld      A, (HL)             ; Load the current token
    or      A                   ; Check if it's 0x00 (End of line)
    jr      z, DP_CRLF          ; If 0x00, print newline and exit
    cp      0xC1                ; Is it a string literal marker?
    jr      z, DP_STRING        ; If so, handle string printing
    cp      ';'                 ; Is it a semicolon?
    jr      z, DP_SEMI          ; Semicolon means suppress newline/spacing
    cp      ','                 ; Is it a comma?
    jr      z, DP_COMMA         ; Comma means print a tab (8 spaces)
    ld      (MEM_TOKEN_PTR), HL ; If it's none of the above, it's an expression. Save pointer.
    call    EVAL_EXPR           ; Evaluate the expression, result in HL
    ex      DE, HL              ; Move result to DE
    ld      HL, (MEM_TOKEN_PTR) ; Retrieve the updated token pointer
    push    HL                  ; Save it on the stack
    ex      DE, HL              ; Move the evaluated result back to HL
    call    PRINT_NUMBER        ; Print the 16-bit number in HL
    pop     HL                  ; Restore the token pointer into HL
    jr      DP_LOOP             ; Continue parsing the PRINT statement

; -----------------------------------------------------------------------
; DP_STRING - Prints a literal string enclosed in 0xC1 markers
; -----------------------------------------------------------------------
DP_STRING:
    inc     HL                  ; Skip the opening 0xC1 marker
DP_STR_LOOP:
    ld      A, (HL)             ; Read string character
    cp      0xC1                ; Is it the closing 0xC1 marker?
    jr      z, DP_STR_END       ; If so, end of string
    call    OUTCHAR             ; Print the character
    inc     HL                  ; Next character
    jr      DP_STR_LOOP
DP_STR_END:
    inc     HL                  ; Skip the closing 0xC1 marker
    jr      DP_LOOP             ; Continue parsing the PRINT statement

; -----------------------------------------------------------------------
; DP_SEMI - Handles the semicolon formatting character
; -----------------------------------------------------------------------
DP_SEMI:
    inc     HL                  ; Skip the semicolon
    jr      DP_LOOP             ; Continue parsing (no action needed, suppresses implicit CRLF)

; -----------------------------------------------------------------------
; DP_COMMA - Handles the comma formatting character (prints spaces)
; -----------------------------------------------------------------------
DP_COMMA:
    inc     HL                  ; Skip the comma
    push    BC                  ; Save BC
    ld      B, 8                ; Loop counter for 8 spaces (simulating a tab)
DP_TAB:
    ld      A, ' '              ; Space character
    call    OUTCHAR             ; Print space
    dec     B
    jr      nz, DP_TAB          ; Decrement B, repeat if not zero
    pop     BC                  ; Restore BC
    jr      DP_LOOP             ; Continue parsing

; -----------------------------------------------------------------------
; DP_CRLF - Prints a final newline and finishes the PRINT command
; -----------------------------------------------------------------------
DP_CRLF:
    call    PRINT_CRLF          ; Print Carriage Return + Line Feed
    jp      REPL_LOOP           ; Return to interactive prompt
