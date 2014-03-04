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
KW_FREE:        .asciiz "FREE"
KW_RND:         .asciiz "RND"
KW_ABS:         .asciiz "ABS"
