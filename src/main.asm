# main.asm - PBasic interpreter entry point (MIPS)
# -----------------------------------------------------------------------

.text
.globl main

# -----------------------------------------------------------------------
# START - System initialization routine
# -----------------------------------------------------------------------
main:
    # Print banner message upon startup
    la      $a0, MSG_BANNER
    li      $v0, 4
    syscall

    # In MARS, the hardware stack pointer ($sp) is automatically
    # initialized to 0x7FFFEFFC upon startup.
    # No manual stack initialization is required.

    # Enter the main Read-Eval-Print Loop (Interactive prompt)
    jal     REPL
    j       HALT_LOOP

HALT_LOOP:
    # Exit syscall (10) for clean termination in MARS
    li $v0, 10
    syscall

# -----------------------------------------------------------------------
# REPL - Read-Eval-Print Loop
# -----------------------------------------------------------------------
# Description:
#   Main interactive loop. Prompts the user, reads input, and loops.
#   Tokenization and dispatch will be added in later phases.
# -----------------------------------------------------------------------
REPL:
    # Print prompt "> "
    la      $a0, STR_PROMPT
    jal     PRINT_STR

    # Read user input into MEM_INPUT_BUF
    jal     READ_LINE

    # TODO: Phase 2 - Tokenize input
    # TODO: Phase 6 - Dispatch commands

    # Loop back to prompt
    j       REPL
