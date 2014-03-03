# strings.asm - Message strings for PBasic (MIPS)
# -----------------------------------------------------------------------
# Defines all static text and error messages.
# Keyword dictionaries will be added in Phase 2 (Tokenizer).
# -----------------------------------------------------------------------

.data

# --- Messages ---
# Null-terminated strings printed to the TTY.
MSG_BANNER:     .asciiz "PBasic\n"
MSG_OK:         .asciiz "OK\n"
MSG_ERROR:      .asciiz "?SYNTAX ERROR\n"
MSG_NO_PROGRAM: .asciiz "?NO PROGRAM\n"
