; strings.asm - Message strings and keyword data for PBasic (Z80)
; -----------------------------------------------------------------------
; Defines all static text, error messages, and the keyword dictionaries
; used by the tokenizer and detokenizer.
; -----------------------------------------------------------------------

; --- Messages ---
; Null-terminated strings printed to the TTY.
MSG_BANNER:
    defb    "PBasic", 0

MSG_PROMPT:
    defb    "> ", 0

MSG_OK:
    defb    "OK", 0

MSG_ERROR:
    defb    "?SYNTAX ERROR", 0

MSG_NO_PROGRAM:
    defb    "?NO PROGRAM", 0

; --- Keywords for tokenizer (KW_*) ---
; Token: 0x83     0x80     0x84     0x81     0x82     0x85
KW_PRINT: defb "PRINT", 0
KW_LET: defb "LET", 0
KW_IF: defb "IF", 0
KW_GOTO: defb "GOTO", 0
KW_GOSUB: defb "GOSUB", 0
KW_INPUT: defb "INPUT", 0
; Token: 0x86     0x8D     0x87     0x8C     0x88     0x89
KW_RETURN: defb "RETURN", 0
KW_THEN: defb "THEN", 0
KW_END: defb "END", 0
KW_REM: defb "REM", 0
KW_LIST: defb "LIST", 0
KW_RUN: defb "RUN", 0
; Token: 0x8A     0x8B     0xA0     0xA1     0xA2
KW_NEW: defb "NEW", 0
KW_EXIT: defb "EXIT", 0
KW_FREE: defb "FREE", 0
KW_RND: defb "RND", 0
KW_ABS: defb "ABS", 0

; --- Keyword lookup table (optimized for O(1) lookup) ---
; Format: [pointer to keyword string (2 bytes), token value (1 byte), terminator (0xFF)]
; Ordered by length to minimize comparisons
KW_TABLE:
    ; 2-letter keywords
    defw    KW_IF
    defb    0x84
    defb    0xFF
    
    ; 3-letter keywords (ordered by frequency)
    defw    KW_LET
    defb    0x80
    defb    0xFF
    
    defw    KW_END
    defb    0x87
    defb    0xFF
    
    defw    KW_NEW
    defb    0x8A
    defb    0xFF
    
    ; 4-letter keywords
    defw    KW_GOTO
    defb    0x81
    defb    0xFF
    
    defw    KW_RUN
    defb    0x89
    defb    0xFF
    
    defw    KW_FREE
    defb    0xA0
    defb    0xFF
    
    defw    KW_RND
    defb    0xA1
    defb    0xFF
    
    defw    KW_ABS
    defb    0xA2
    defb    0xFF
    
    defw    KW_EXIT
    defb    0x8B
    defb    0xFF
    
    defw    KW_LIST
    defb    0x88
    defb    0xFF
    
    ; 5-letter keywords
    defw    KW_THEN
    defb    0x8D
    defb    0xFF
    
    defw    KW_REM
    defb    0x8C
    defb    0xFF
    
    ; 6-letter keywords
    defw    KW_INPUT
    defb    0x85
    defb    0xFF
    
    defw    KW_RETURN
    defb    0x86
    defb    0xFF
    
    defw    KW_GOSUB
    defb    0x82
    defb    0xFF
    
    ; 5-letter keyword (PRINT)
    defw    KW_PRINT
    defb    0x83
    defb    0xFF
    
    ; End marker
    defb    0

; --- Keyword display strings (PKWS_*) ---
; Used by PRINT_KEYWORD in detokenize.asm
; Token 0x80
PKWS_LET: defb "LET ", 0
; Token 0x81
PKWS_GOTO: defb "GOTO ", 0
; Token 0x82
PKWS_GOSUB: defb "GOSUB ", 0
; Token 0x83
PKWS_PRINT: defb "PRINT ", 0
; Token 0x84
PKWS_IF: defb "IF ", 0
; Token 0x85
PKWS_INPUT: defb "INPUT ", 0
; Token 0x86
PKWS_RETURN: defb "RETURN", 0
; Token 0x87
PKWS_END: defb "END", 0
; Token 0x88
PKWS_LIST: defb "LIST", 0
; Token 0x89
PKWS_RUN: defb "RUN", 0
; Token 0x8A
PKWS_NEW: defb "NEW", 0
; Token 0x8B
PKWS_EXIT: defb "EXIT", 0
; Token 0x8C
PKWS_REM: defb "REM", 0
; Token 0x8D
PKWS_THEN: defb "THEN ", 0
; Token 0xA0
PKWS_FREE: defb "FREE", 0
; Token 0xA1
PKWS_RND: defb "RND", 0
; Token 0xA2
PKWS_ABS: defb "ABS", 0
; Token 0xB0
PKWS_NE: defb "<>", 0
; Token 0xB1
PKWS_LE: defb "<=", 0
; Token 0xB2
PKWS_GE: defb ">=", 0
