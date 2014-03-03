# defs.asm - Memory map and constants for PBasic MIPS
# -----------------------------------------------------------------------
# MIPS architecture utilizes standard MARS/QtSPIM memory segments.
# Variables are stored as 32-bit words for native MIPS performance.

.data
    # --- Data buffers ---
    MEM_INPUT_BUF:  .space 128     # Raw text input buffer (128 bytes)
    MEM_TOKEN_BUF:  .space 160     # Tokenized line buffer (160 bytes)
    
    # --- Variables ---
    MEM_VARS:       .space 104     # Variables A-Z (26 x 4 bytes)
    
    # --- Stack and Pointers ---
    MEM_GOSUB_STK:  .space 64      # GOSUB return address stack (16 levels x 4 bytes)
    MEM_GOSUB_SP:   .word 0        # Current GOSUB stack pointer depth
    MEM_RAND_SEED:  .word 12345    # Random number generator seed
    MEM_TOKEN_PTR:  .word 0        # Pointer to the current token being evaluated
    MEM_LINE_PTR:   .word 0        # Pointer to the start of the currently executing BASIC line
    MEM_RUN_FLAG:   .word 0        # Execution state flag (1 = running, 0 = interactive)
    MEM_PROG_END:   .word 0        # Pointer to the end of the user BASIC program
    MEM_SCRATCH:    .word 0        # Temporary 32-bit storage for routines
    MEM_SCRATCH_LEN:.word 0        # Temporary 32-bit storage for lengths

    # Program memory area starts after static data in heap.
    # Alternatively, we reserve a large static buffer here.
    MEM_PROG_START: .space 1024   # BASIC program area (reduced for test)

    # --- Static Strings ---
    STR_PROMPT:     .asciiz "> "
    STR_CRLF:       .asciiz "\n"

# --- Constants ---
# Constants are loaded directly via li/la instructions.
# GOSUB_DEPTH = 16
# INPUT_BUF_LEN = 128
# TOKEN_BUF_LEN = 160
