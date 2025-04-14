; detokenize.asm - Token-to-text conversion for PBasic (Z80)
; -----------------------------------------------------------------------
; Converts internal token streams back to human-readable text.
; Used primarily by the LIST command to reconstruct the source code.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; PRINT_TOKENS - Print token stream at HL as text. Advances HL past 0x00.
; Preserves: AF, BC, DE
; -----------------------------------------------------------------------
PRINT_TOKENS:
    push    AF                  ; Save AF
    push    BC                  ; Save BC
    push    DE                  ; Save DE

PTO_LOOP:
    ld      A, (HL)             ; Read the current token
    or      A                   ; Is it 0x00?
    jr      z, PTO_DONE         ; If so, end of token stream
    inc     HL                  ; Advance to next byte

    bit     7, A                ; Check bit 7 (is it >= 0x80?)
    jr      z, PTO_ASCII        ; If bit 7 is 0, it's a literal ASCII character

    cp      0xC0                ; Is it a number literal token?
    jr      z, PTO_NUM          ; If so, handle number

    cp      0xC1                ; Is it a string literal token?
    jr      z, PTO_STR          ; If so, handle string

    cp      0xD0                ; Is it < 0xD0? (meaning it's a keyword or operator)
    jr      c, PTO_KW           ; If so, handle keyword
    cp      0xEA                ; Is it >= 0xEA? (invalid token range)
    jr      nc, PTO_LOOP        ; If invalid, just skip it and loop

    ; If we got here, it's a variable token (0xD0-0xE9)
    sub     0xD0                ; Subtract base to get 0-25
    add     A, 'A'              ; Add ASCII 'A' to get 'A'-'Z'
    call    OUTCHAR             ; Print the variable letter
    jr      PTO_LOOP            ; Loop for next token

PTO_ASCII:
    call    OUTCHAR             ; Print the ASCII character
    jr      PTO_LOOP            ; Loop for next token

PTO_KW:
    push    HL                  ; Save token pointer
    call    PRINT_KEYWORD       ; Print the keyword string corresponding to the token in A
    pop     HL                  ; Restore token pointer
    jr      PTO_LOOP            ; Loop for next token

PTO_NUM:
    ld      E, (HL)             ; Load low byte of number
    inc     HL
    ld      D, (HL)             ; Load high byte of number
    inc     HL
    push    HL                  ; Save token pointer
    ld      H, D                ; Move number into HL for printing
    ld      L, E
    call    PRINT_NUMBER        ; Print the number
    pop     HL                  ; Restore token pointer
    jr      PTO_LOOP            ; Loop for next token

PTO_STR:
    ld      A, '"'              ; Print opening quote
    call    OUTCHAR
PTO_SL:
    ld      A, (HL)             ; Read character from string body
    inc     HL
    cp      0xC1                ; Is it the closing string marker?
    jr      z, PTO_SE           ; If so, end of string
    or      A                   ; Is it 0x00? (malformed string)
    jr      z, PTO_DONE         ; If so, abort securely
    call    OUTCHAR             ; Print the character
    jr      PTO_SL              ; Loop inside string
PTO_SE:
    ld      A, '"'              ; Print closing quote
    call    OUTCHAR
    jr      PTO_LOOP            ; Loop for next token

PTO_DONE:
    pop     DE                  ; Restore registers
    pop     BC
    pop     AF
    ret                         ; Return

; -----------------------------------------------------------------------
; PRINT_KEYWORD - Print text for keyword token in A.
; Compares token against all known keywords and prints the mapped string.
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
PRINT_KEYWORD:
    push    AF                  ; Save AF
    push    BC                  ; Save BC
    push    DE                  ; Save DE
    push    HL                  ; Save HL

    ; Check if token is in the 0x80 - 0x8D range
    cp      0x80
    jr      c, PKW_CHECK_A      ; If < 0x80, check A0 range
    cp      0x8E
    jr      nc, PKW_CHECK_A     ; If >= 0x8E, check A0 range

    ; --- O(1) Lookup Table for 0x80-0x8D ---
    sub     0x80                ; A = 0 to 13
    add     A, A                ; A = A * 2 (each pointer is 2 bytes)
    ld      C, A
    ld      B, 0                ; BC = offset

    ld      HL, PKW_TABLE       ; Base address of lookup table
    add     HL, BC              ; HL = table + offset

    ld      E, (HL)             ; Read low byte of string pointer
    inc     HL
    ld      D, (HL)             ; Read high byte of string pointer
    ex      DE, HL              ; HL = string pointer

    call    PRINT_STR           ; Print the selected keyword string
    jr      PKW_DONE

PKW_CHECK_A:
    cp      0xA0
    jr      z, PKW_E            ; FREE
    cp      0xA1
    jr      z, PKW_F            ; RND
    cp      0xA2
    jr      z, PKW_G            ; ABS

    cp      0xB0
    jr      z, PKW_H            ; <>
    cp      0xB1
    jr      z, PKW_I            ; <=
    cp      0xB2
    jr      z, PKW_J            ; >=

    jr      PKW_DONE            ; If unknown, do nothing

PKW_E:
    ld      HL, PKWS_FREE
    jr      PKW_PS
PKW_F:
    ld      HL, PKWS_RND
    jr      PKW_PS
PKW_G:
    ld      HL, PKWS_ABS
    jr      PKW_PS
PKW_H:
    ld      HL, PKWS_NE
    jr      PKW_PS
PKW_I:
    ld      HL, PKWS_LE
    jr      PKW_PS
PKW_J:
    ld      HL, PKWS_GE
    jr      PKW_PS

PKW_PS:
    call    PRINT_STR           ; Print the selected keyword string

PKW_DONE:
    pop     HL                  ; Restore registers
    pop     DE
    pop     BC
    pop     AF
    ret                         ; Return

; -----------------------------------------------------------------------
; PKW_TABLE - O(1) Lookup table for keyword strings (Tokens 0x80-0x8D)
; -----------------------------------------------------------------------
PKW_TABLE:
    dw      PKWS_LET            ; 0x80
    dw      PKWS_GOTO           ; 0x81
    dw      PKWS_GOSUB          ; 0x82
    dw      PKWS_PRINT          ; 0x83
    dw      PKWS_IF             ; 0x84
    dw      PKWS_INPUT          ; 0x85
    dw      PKWS_RETURN         ; 0x86
    dw      PKWS_END            ; 0x87
    dw      PKWS_LIST           ; 0x88
    dw      PKWS_RUN            ; 0x89
    dw      PKWS_NEW            ; 0x8A
    dw      PKWS_EXIT           ; 0x8B
    dw      PKWS_REM            ; 0x8C
    dw      PKWS_THEN           ; 0x8D
