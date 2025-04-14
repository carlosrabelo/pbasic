; util.asm - Utility routines for PBasic (Z80)
; -----------------------------------------------------------------------
; Contains common string manipulation and parsing routines used across
; various parts of the interpreter.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; TO_UPPER_BUF - Convert input buffer to uppercase in-place
; Ignores characters inside string literals (between double quotes).
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
TO_UPPER_BUF:
    push    AF                  ; Save AF
    push    HL                  ; Save HL
    ld      HL, MEM_INPUT_BUF   ; Point to the start of the input buffer
TUB_LOOP:
    ld      A, (HL)             ; Load a character
    or      A                   ; Is it the null terminator?
    jr      z, TUB_DONE         ; If so, end of buffer
    cp      '"'                 ; Is it a double quote?
    jr      nz, TUB_CHECK       ; If not, proceed to check if it's lowercase
TUB_QUOTE:
    inc     HL                  ; Skip the opening quote
    ld      A, (HL)             ; Read the next character
    or      A                   ; Is it the null terminator?
    jr      z, TUB_DONE         ; If string wasn't closed properly, stop at null
    cp      '"'                 ; Is it the closing quote?
    jr      nz, TUB_QUOTE       ; If not, keep reading (don't convert string literal)
    inc     HL                  ; Skip the closing quote
    jr      TUB_LOOP            ; Resume normal parsing
TUB_CHECK:
    cp      'a'                 ; Is it less than 'a'?
    jr      c, TUB_NEXT         ; If so, it's not lowercase
    cp      'z' + 1             ; Is it greater than 'z'?
    jr      nc, TUB_NEXT        ; If so, it's not lowercase
    sub     32                  ; Convert lowercase to uppercase (ASCII math)
    ld      (HL), A             ; Store the uppercase character back
TUB_NEXT:
    inc     HL                  ; Move to the next character
    jr      TUB_LOOP            ; Loop back
TUB_DONE:
    pop     HL                  ; Restore HL
    pop     AF                  ; Restore AF
    ret                         ; Return

; -----------------------------------------------------------------------
; SKIP_SPACES - Skip spaces at (HL)
; Input/Output: HL = position (advanced past spaces)
; Preserves: AF, BC, DE
; -----------------------------------------------------------------------
SKIP_SPACES:
    push    AF                  ; Save AF
SS_LOOP:
    ld      A, (HL)             ; Load current character
    cp      ' '                 ; Is it a space?
    jr      nz, SS_DONE         ; If not, stop skipping
    inc     HL                  ; Advance pointer
    jr      SS_LOOP             ; Loop back
SS_DONE:
    pop     AF                  ; Restore AF
    ret                         ; Return

; -----------------------------------------------------------------------
; MATCH_KEYWORD - Check if input at HL matches keyword
; Input: HL = input text, DE = keyword (null-terminated uppercase)
; Output: Z if match, HL advanced past keyword; NZ if no match, HL unchanged
; Preserves: BC, DE
; -----------------------------------------------------------------------
MATCH_KEYWORD:
    push    BC                  ; Save BC
    push    DE                  ; Save keyword pointer
    push    HL                  ; Save original text pointer

MK_LOOP:
    ld      A, (DE)             ; Read character from the keyword
    or      A                   ; Reached the end of the keyword?
    jr      z, MK_END_CHECK     ; If so, check word boundary in input text
    cp      (HL)                ; Compare with character in input text
    jr      nz, MK_FAIL         ; If they differ, the match fails
    inc     HL                  ; Advance input pointer
    inc     DE                  ; Advance keyword pointer
    jr      MK_LOOP             ; Continue matching

MK_END_CHECK:
    ld      A, (HL)             ; Keyword matched! Now check the next char in input
    or      A                   ; Is it end of string?
    jr      z, MK_SUCCESS       ; Valid boundary
    cp      'A'                 ; Is it less than 'A'? (e.g., space, punctuation)
    jr      c, MK_SUCCESS       ; Valid boundary
    cp      'Z' + 1             ; Is it greater than 'Z'?
    jr      nc, MK_SUCCESS      ; Valid boundary
    jr      MK_FAIL             ; If it's another letter, it's a partial match (e.g., PRINTER vs PRINT). Fail.

MK_FAIL:
    pop     HL                  ; Restore original text pointer (no advance)
    pop     DE                  ; Restore keyword pointer
    pop     BC                  ; Restore BC
    or      0xFF                ; Clear Zero flag (NZ = Failure)
    ret                         ; Return

MK_SUCCESS:
    pop     DE                  ; Discard saved original text pointer (HL stays advanced)
    pop     DE                  ; Restore keyword pointer
    pop     BC                  ; Restore BC
    xor     A                   ; Set Zero flag (Z = Success)
    ret                         ; Return

; -----------------------------------------------------------------------
; PARSE_NUMBER - Parse decimal number at (HL)
; Input: HL = position in buffer
; Output: DE = parsed number, HL advanced past digits (if Z)
;         DE = 0, NZ if no digit at (HL)
; Preserves: BC
; -----------------------------------------------------------------------
PARSE_NUMBER:
    push    BC                  ; Save BC
    ld      A, (HL)             ; Look at the first character
    cp      '0'                 ; Is it less than '0'?
    jr      c, PN_FAIL          ; If so, not a number, fail
    cp      '9' + 1             ; Is it greater than '9'?
    jr      nc, PN_FAIL         ; If so, not a number, fail
    ld      DE, 0               ; Initialize accumulator (DE) to 0

PN_LOOP:
    ld      A, (HL)             ; Load current character
    cp      '0'                 ; Is it less than '0'?
    jr      c, PN_DONE          ; If so, we've finished parsing digits
    cp      '9' + 1             ; Is it greater than '9'?
    jr      nc, PN_DONE         ; If so, we've finished parsing digits
    sub     '0'                 ; Convert ASCII digit to integer value
    ld      C, A                ; Store the digit in C
    ld      B, 0                ; BC now holds the new digit

    ; Multiply DE by 10 (DE = DE * 10)
    ; Optimized: result = DE * 2 + DE * 8 = DE * 10
    push    HL                  ; Save text pointer
    ld      H, D                ; Move accumulator DE into HL for math
    ld      L, E
    add     HL, HL              ; HL = DE * 2
    push    HL                  ; Save DE * 2
    add     HL, HL              ; HL = DE * 4
    add     HL, HL              ; HL = DE * 8
    pop     DE                  ; DE = DE * 2
    add     HL, DE              ; HL = (DE * 8) + (DE * 2) = DE * 10
    add     HL, BC              ; HL = (DE * 10) + digit
    ld      E, L                ; Move result back to DE
    ld      D, H
    pop     HL                  ; Restore text pointer

    inc     HL                  ; Advance to next character
    jr      PN_LOOP             ; Loop back

PN_DONE:
    xor     A                   ; Set Zero flag (Success)
    pop     BC                  ; Restore BC
    ret                         ; Return

PN_FAIL:
    ld      DE, 0               ; Return 0 on failure
    or      0xFF                ; Clear Zero flag (Failure)
    pop     BC                  ; Restore BC
    ret                         ; Return
