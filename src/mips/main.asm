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

    # Initialize program memory (write sentinel to MEM_PROG_START)
    jal     PROG_INIT
    
    # Initialize all variables (A-Z)
    jal     VAR_INIT
    
    # Enter the main Read-Eval-Print Loop (Interactive prompt)
    jal     REPL
    j       HALT_LOOP
    
HALT_LOOP:
    # Exit syscall (10) for clean termination in MARS/SPIM
    li $v0, 10
    syscall

# -----------------------------------------------------------------------
# REPL - Read-Eval-Print Loop
# -----------------------------------------------------------------------
# Description:
#   Main interactive loop. Prompts the user, reads input, and loops.
#   (Evaluation step to be implemented in Phase 2/3)
# -----------------------------------------------------------------------
REPL:
    la      $t0, MEM_RUN_FLAG
    lw      $t0, 0($t0)         # Load run flag
    bnez    $t0, RUN_NEXT       # If running a program, go straight to execute next line

    # Print prompt "> "
    la      $a0, STR_PROMPT
    jal     PRINT_STR

    # Read user input into MEM_INPUT_BUF
    jal     READ_LINE

    # Convert input text into Tokens
    jal     TOKENIZE

    # Initialize MEM_TOKEN_PTR to point to MEM_TOKEN_BUF
    la      $t0, MEM_TOKEN_BUF
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    # Jump to the dispatch engine
    j       REPL_DISPATCH

REPL_STORE_LINE:
    jal     LINE_STORE
    j       REPL

REPL_LOOP_DONE:
    la      $t0, MEM_RUN_FLAG
    lw      $t0, 0($t0)         # Load run flag
    bnez    $t0, RUN_NEXT       # If running, go execute next line
    j       REPL

REPL_SYNTAX_ERROR:
    la      $a0, MSG_ERROR
    jal     PRINT_STR
    j       REPL
