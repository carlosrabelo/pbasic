; tokenize.asm - Tokenizer for PBasic (Z80)
; -----------------------------------------------------------------------
; Converts ASCII in MEM_INPUT_BUF to internal tokens in MEM_TOKEN_BUF.
; This allows the interpreter to run faster and use less memory.
;
; Token format per TODO.md:
;   0x00        EOL
;   0x01-0x7F   ASCII literal (punctuation, unquoted strings)
;   0x80-0x8D   Keywords (LET..REM, THEN)
;   0xA0-0xA2   Functions (FREE, RND, ABS)
;   0xB0-0xB2   Two-char operators (<> <= >=)
;   0xC0 + 2B   Number literal (16-bit LE)
;   0xC1 ... 0xC1  String literal
;   0xD0-0xE9   Variables A-Z
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; TOKENIZE - Convert input buffer to tokens
; Input: MEM_INPUT_BUF (uppercase, null-terminated)
; Output: MEM_TOKEN_BUF (tokens, null-terminated)
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
TOKENIZE:
    push    AF                  ; Save registers
    push    BC
    push    DE
    push    HL

    ld      HL, MEM_INPUT_BUF   ; HL points to source ASCII
    ld      DE, MEM_TOKEN_BUF   ; DE points to destination token stream

TOK_LOOP:
    call    SKIP_SPACES         ; Ignore spaces between tokens

    ld      A, (HL)             ; Read current character
    or      A                   ; Is it null (end of string)?
    jr      z, TOK_DONE         ; If so, finish tokenization

    cp      '"'                 ; Is it a quote (start of string literal)?
    jr      z, TOK_STRING       ; If so, handle string tokenization

    cp      '0'                 ; Is it a digit ('0'-'9')?
    jr      c, TOK_NOTNUM       ; If less than '0', it's not a number
    cp      '9' + 1
    jr      nc, TOK_NOTNUM      ; If greater than '9', it's not a number
    jp      TOK_NUMBER          ; It's a number, jump to number parser

TOK_NOTNUM:
    cp      'A'                 ; Is it a letter ('A'-'Z')?
    jr      c, TOK_NOTLETTER    ; If less than 'A', not a letter
    cp      'Z' + 1
    jr      nc, TOK_NOTLETTER   ; If greater than 'Z', not a letter
    jp      TOK_LETTER          ; It's a letter, which means keyword or variable

TOK_NOTLETTER:
    cp      '<'                 ; Is it a less-than sign?
    jr      z, TOK_LT           ; Handle potential '<>' or '<='
    cp      '>'                 ; Is it a greater-than sign?
    jr      z, TOK_GT           ; Handle potential '>='

    ; If it's none of the above (e.g., '+', '-', '*', '/', '=', '(', ')', ';', ','),
    ; it's a single-character ASCII token. Store it literally.
    ld      (DE), A             ; Store ASCII character as token
    inc     HL                  ; Advance input pointer
    inc     DE                  ; Advance output pointer
    jr      TOK_LOOP            ; Loop back

TOK_DONE:
    ld      A, 0                ; Write null terminator to token stream
    ld      (DE), A
    pop     HL                  ; Restore registers
    pop     DE
    pop     BC
    pop     AF
    ret                         ; Return

; -----------------------------------------------------------------------
; --- Number literal: 0xC0 + 2-byte LE ---
; -----------------------------------------------------------------------
TOK_NUMBER:
    ld      A, 0xC0             ; Write number token prefix (0xC0)
    ld      (DE), A
    inc     DE                  ; Advance output pointer
    push    DE                  ; Save output pointer
    call    PARSE_NUMBER        ; Parse ASCII number to DE register
    ld      B, D                ; Move parsed number to BC
    ld      C, E
    pop     DE                  ; Restore output pointer
    ld      A, C                ; Write low byte of number
    ld      (DE), A
    inc     DE                  ; Advance output pointer
    ld      A, B                ; Write high byte of number
    ld      (DE), A
    inc     DE                  ; Advance output pointer
    jp      TOK_LOOP            ; Resume tokenization

; -----------------------------------------------------------------------
; --- String literal: 0xC1 ... 0xC1 ---
; -----------------------------------------------------------------------
TOK_STRING:
    inc     HL                  ; Skip opening quote in input
    ld      A, 0xC1             ; Write string start token (0xC1)
    ld      (DE), A
    inc     DE                  ; Advance output pointer

TS_LOOP:
    ld      A, (HL)             ; Read character inside string
    or      A                   ; Is it null (end of line)?
    jr      z, TS_END           ; Unclosed string, close it implicitly
    cp      '"'                 ; Is it a closing quote?
    jr      z, TS_CLOSE         ; If so, end string token
    ld      (DE), A             ; Otherwise, store character literally
    inc     HL                  ; Advance input
    inc     DE                  ; Advance output
    jr      TS_LOOP             ; Continue loop

TS_CLOSE:
    inc     HL                  ; Skip closing quote in input

TS_END:
    ld      A, 0xC1             ; Write string end token (0xC1)
    ld      (DE), A
    inc     DE                  ; Advance output pointer
    jp      TOK_LOOP            ; Resume tokenization

; -----------------------------------------------------------------------
; --- Operators ---
; -----------------------------------------------------------------------
TOK_LT:
    inc     HL                  ; Skip '<'
    ld      A, (HL)             ; Look at next character
    cp      '>'                 ; Is it '<>' (not equal)?
    jr      z, TOK_NE
    cp      '='                 ; Is it '<=' (less or equal)?
    jr      z, TOK_LE
    ; It was just '<'
    ld      A, '<'              ; Write '<' as literal token
    ld      (DE), A
    inc     DE
    jp      TOK_LOOP

TOK_NE:
    inc     HL                  ; Skip '>'
    ld      A, 0xB0             ; Write '<>' token (0xB0)
    ld      (DE), A
    inc     DE
    jp      TOK_LOOP

TOK_LE:
    inc     HL                  ; Skip '='
    ld      A, 0xB1             ; Write '<=' token (0xB1)
    ld      (DE), A
    inc     DE
    jp      TOK_LOOP

TOK_GT:
    inc     HL                  ; Skip '>'
    ld      A, (HL)             ; Look at next character
    cp      '='                 ; Is it '>=' (greater or equal)?
    jr      z, TOK_GE
    ; It was just '>'
    ld      A, '>'              ; Write '>' as literal token
    ld      (DE), A
    inc     DE
    jp      TOK_LOOP

TOK_GE:
    inc     HL                  ; Skip '='
    ld      A, 0xB2             ; Write '>=' token (0xB2)
    ld      (DE), A
    inc     DE
    jp      TOK_LOOP

; -----------------------------------------------------------------------
; --- Keywords and variables ---
; -----------------------------------------------------------------------
TOK_LETTER:
    call    TOK_KEYWORD         ; Try to match against all keywords
    jr      nz, TOK_VARIABLE    ; If no match, it must be a single-letter variable
    cp      0x8C                ; Did it match 'REM' (0x8C)?
    jp      z, TOK_DONE         ; If REM, ignore the rest of the line (comments)
    jp      TOK_LOOP            ; Otherwise, continue tokenizing

TOK_VARIABLE:
    ld      A, (HL)             ; Read the variable letter ('A'-'Z')
    sub     'A'                 ; Convert to 0-25
    add     0xD0                ; Add base offset to get token (0xD0-0xE9)
    ld      (DE), A             ; Store variable token
    inc     HL                  ; Advance input pointer
    inc     DE                  ; Advance output pointer
    jp      TOK_LOOP            ; Continue tokenizing

; -----------------------------------------------------------------------
; --- Keyword matching (optimized with lookup table) ---
; Returns Z + token in A on match (token emitted to DE, HL advanced)
; Returns NZ on no match (HL and DE unchanged)
; Input: HL = input pointer, DE = output pointer
; -----------------------------------------------------------------------
TOK_KEYWORD:
    push    DE                  ; Save DE (output pointer)
    ld      DE, KW_PRINT
    call    MATCH_KEYWORD
    jr      nz, TK_N1
    pop     DE
    ld      A, 0x83
    ld      (DE), A
    inc     DE
    ret

TK_N1:
    ld      DE, KW_LET
    call    MATCH_KEYWORD
    jr      nz, TK_N2
    pop     DE
    ld      A, 0x80
    ld      (DE), A
    inc     DE
    ret

TK_N2:
    ld      DE, KW_IF
    call    MATCH_KEYWORD
    jr      nz, TK_N3
    pop     DE
    ld      A, 0x84
    ld      (DE), A
    inc     DE
    ret

TK_N3:
    ld      DE, KW_GOTO
    call    MATCH_KEYWORD
    jr      nz, TK_N4
    pop     DE
    ld      A, 0x81
    ld      (DE), A
    inc     DE
    ret

TK_N4:
    ld      DE, KW_GOSUB
    call    MATCH_KEYWORD
    jr      nz, TK_N5
    pop     DE
    ld      A, 0x82
    ld      (DE), A
    inc     DE
    ret

TK_N5:
    ld      DE, KW_INPUT
    call    MATCH_KEYWORD
    jr      nz, TK_N6
    pop     DE
    ld      A, 0x85
    ld      (DE), A
    inc     DE
    ret

TK_N6:
    ld      DE, KW_RETURN
    call    MATCH_KEYWORD
    jr      nz, TK_N7
    pop     DE
    ld      A, 0x86
    ld      (DE), A
    inc     DE
    ret

TK_N7:
    ld      DE, KW_THEN
    call    MATCH_KEYWORD
    jr      nz, TK_N8
    pop     DE
    ld      A, 0x8D
    ld      (DE), A
    inc     DE
    ret

TK_N8:
    ld      DE, KW_END
    call    MATCH_KEYWORD
    jr      nz, TK_N9
    pop     DE
    ld      A, 0x87
    ld      (DE), A
    inc     DE
    ret

TK_N9:
    ld      DE, KW_REM
    call    MATCH_KEYWORD
    jr      nz, TK_N10
    pop     DE
    ld      A, 0x8C
    ld      (DE), A
    inc     DE
    ret

TK_N10:
    ld      DE, KW_LIST
    call    MATCH_KEYWORD
    jr      nz, TK_N11
    pop     DE
    ld      A, 0x88
    ld      (DE), A
    inc     DE
    ret

TK_N11:
    ld      DE, KW_RUN
    call    MATCH_KEYWORD
    jr      nz, TK_N12
    pop     DE
    ld      A, 0x89
    ld      (DE), A
    inc     DE
    ret

TK_N12:
    ld      DE, KW_NEW
    call    MATCH_KEYWORD
    jr      nz, TK_N13
    pop     DE
    ld      A, 0x8A
    ld      (DE), A
    inc     DE
    ret

TK_N13:
    ld      DE, KW_EXIT
    call    MATCH_KEYWORD
    jr      nz, TK_N14
    pop     DE
    ld      A, 0x8B
    ld      (DE), A
    inc     DE
    ret

TK_N14:
    ld      DE, KW_FREE
    call    MATCH_KEYWORD
    jr      nz, TK_N15
    pop     DE
    ld      A, 0xA0
    ld      (DE), A
    inc     DE
    ret

TK_N15:
    ld      DE, KW_RND
    call    MATCH_KEYWORD
    jr      nz, TK_N16
    pop     DE
    ld      A, 0xA1
    ld      (DE), A
    inc     DE
    ret

TK_N16:
    ld      DE, KW_ABS
    call    MATCH_KEYWORD
    jr      nz, TK_KW_FAIL
    pop     DE
    ld      A, 0xA2
    ld      (DE), A
    inc     DE
    ret

TK_KW_FAIL:
    pop     DE
    or      0xFF
    ret
