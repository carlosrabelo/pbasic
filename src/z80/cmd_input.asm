; cmd_input.asm - INPUT command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_INPUT - Reads user input into a variable, optionally printing a string
; Input: HL points to the token after INPUT (string literal or variable)
; Output: None
; Clobbers: AF, BC, DE, HL
; -----------------------------------------------------------------------
DO_INPUT:
    ld      A, (HL)             ; Check first token
    cp      0xC1                ; Is it a string literal marker (0xC1)?
    jr      nz, DIN_PROMPT      ; If not, skip string printing and just show default prompt
    inc     HL                  ; Skip the 0xC1 marker
DIN_STR_LOOP:
    ld      A, (HL)             ; Load character from string
    cp      0xC1                ; Is it the closing string literal marker?
    jr      z, DIN_STR_END      ; If so, end of string
    call    OUTCHAR             ; Print the character
    inc     HL                  ; Next character
    jr      DIN_STR_LOOP
DIN_STR_END:
    inc     HL                  ; Skip the closing 0xC1 marker
    ld      A, (HL)             ; Load the next token
    cp      ';'                 ; Must be a semicolon separating string from variable
    jr      nz, DIN_ERR         ; If not, syntax error
    inc     HL                  ; Skip the semicolon
    jr      DIN_VAR             ; Proceed to variable parsing
DIN_PROMPT:
    ld      A, '?'              ; Default prompt: "?"
    call    OUTCHAR
    ld      A, ' '              ; Followed by space
    call    OUTCHAR
DIN_VAR:
    ld      A, (HL)             ; Read the variable token
    cp      0xD0                ; Is it >= 'A'?
    jr      c, DIN_ERR          ; Error if not
    cp      0xEA                ; Is it <= 'Z'?
    jr      nc, DIN_ERR         ; Error if not
    ld      (MEM_SCRATCH), A    ; Temporarily save the target variable token
    call    READ_LINE           ; Read a line of text from the user into MEM_INPUT_BUF
    ld      A, (HL)             ; Check the first character of the input buffer (HL points to it)
    cp      '-'                 ; Is it a negative sign?
    jr      nz, DIN_PARSE       ; If not, jump to standard parsing
    inc     HL                  ; Skip the negative sign
    call    PARSE_NUMBER        ; Parse the numeric value into DE
    ex      DE, HL              ; Move parsed value from DE to HL
    ld      A, H                ; Begin Two's Complement to negate the number
    cpl                         ; Invert high byte
    ld      H, A
    ld      A, L
    cpl                         ; Invert low byte
    ld      L, A
    inc     HL                  ; Add 1 (HL = -DE)
    jr      DIN_STORE           ; Jump to store the negative number
DIN_PARSE:
    call    PARSE_NUMBER        ; Parse the numeric value into DE
    ex      DE, HL              ; Move parsed value from DE to HL for storage
DIN_STORE:
    ld      A, (MEM_SCRATCH)    ; Retrieve the target variable token
    call    VAR_SET             ; Store the 16-bit value in HL into the variable
    jp      REPL_LOOP           ; Return to interactive prompt
DIN_ERR:
    call    PRINT_ERROR         ; Print syntax error
    jp      REPL_LOOP           ; Return to interactive prompt
