# strings.asm - Message strings and keyword data for PBasic (MIPS)
# -----------------------------------------------------------------------
# Defines all static text, error messages, and the keyword dictionaries
# used by the tokenizer and detokenizer.
# -----------------------------------------------------------------------

.data

# --- Messages ---
# Null-terminated strings printed to the TTY.
MSG_BANNER:     .asciiz "PBasic\n"
MSG_OK:         .asciiz "OK\n"
MSG_ERROR:      .asciiz "?SYNTAX ERROR\n"
MSG_NO_PROGRAM: .asciiz "?NO PROGRAM\n"

# --- Keywords for tokenizer (KW_*) ---
KW_LET:         .asciiz "LET"
KW_GOTO:        .asciiz "GOTO"
KW_GOSUB:       .asciiz "GOSUB"
KW_PRINT:       .asciiz "PRINT"
KW_IF:          .asciiz "IF"
KW_INPUT:       .asciiz "INPUT"
KW_RETURN:      .asciiz "RETURN"
KW_END:         .asciiz "END"
KW_LIST:        .asciiz "LIST"
KW_RUN:         .asciiz "RUN"
KW_NEW:         .asciiz "NEW"
KW_EXIT:        .asciiz "EXIT"
KW_REM:         .asciiz "REM"
KW_THEN:        .asciiz "THEN"
KW_FREE:       .asciiz "FREE"
KW_RND:        .asciiz "RND"
KW_ABS:        .asciiz "ABS"

# --- Detokenizer keywords (PKWS_*) ---
PKWS_FREE:     .asciiz "FREE"
PKWS_RND:      .asciiz "RND"
PKWS_ABS:      .asciiz "ABS"
PKWS_NE:       .asciiz "<>"
PKWS_LE:       .asciiz "<="
PKWS_GE:       .asciiz ">="

# --- Detokenizer keyword lookup table (PKW_TABLE) ---
# Maps token values 0x80-0x8D to their string pointers
PKW_TABLE:
    .word   KW_LET      # 0x80
    .word   KW_GOTO     # 0x81
    .word   KW_GOSUB    # 0x82
    .word   KW_PRINT    # 0x83
    .word   KW_IF       # 0x84
    .word   KW_INPUT    # 0x85
    .word   KW_RETURN   # 0x86
    .word   KW_END      # 0x87
    .word   KW_LIST     # 0x88
    .word   KW_RUN      # 0x89
    .word   KW_NEW      # 0x8A
    .word   KW_EXIT     # 0x8B
    .word   KW_REM      # 0x8C
    .word   KW_THEN     # 0x8D
