# commands.asm - Core execution engine and commands for PBasic (MIPS)
# -----------------------------------------------------------------------
# Maps tokens to command execution handlers and handles direct execution.
# -----------------------------------------------------------------------

.data

.align 2
CMD_JUMP_TABLE:
    .word DO_LET              # 0x80: LET
    .word DO_GOTO             # 0x81: GOTO
    .word DO_GOSUB            # 0x82: GOSUB
    .word DO_PRINT            # 0x83: PRINT
    .word DO_IF               # 0x84: IF
    .word DO_INPUT            # 0x85: INPUT
    .word DO_RETURN           # 0x86: RETURN
    .word DO_END              # 0x87: END
    .word DO_LIST             # 0x88: LIST
    .word DO_RUN              # 0x89: RUN
    .word DO_NEW              # 0x8A: NEW
    .word DO_EXIT             # 0x8B: EXIT
    .word DO_REM              # 0x8C: REM

.text

# -----------------------------------------------------------------------
# REPL_DISPATCH - Main instruction dispatch logic.
# Input:  None (uses MEM_TOKEN_PTR)
# Output: None
# Clobbers: $t0, $t1, $t2, $t3, $t4
# -----------------------------------------------------------------------
REPL_DISPATCH:
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)         # $t0 = current token pointer
    lbu     $t1, 0($t0)         # $t1 = current token byte

    # 1) Check if empty line (0x00)
    beqz    $t1, REPL_LOOP_DONE

    # 2) Check if line number (0xC0 = 192)
    addiu   $t2, $zero, 192
    beq     $t1, $t2, REPL_STORE_LINE

    # 3) Check if FREE token (0xA0 = 160)
    addiu   $t2, $zero, 160
    bne     $t1, $t2, RD_NOT_FREE
    # Advance token pointer past FREE
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)
    j       DO_FREE

RD_NOT_FREE:
    # 4) Check if token is < 0x80 (128)
    addiu   $t2, $zero, 128
    slt     $t3, $t1, $t2       # $t3 = 1 if token < 128
    bnez    $t3, REPL_SYNTAX_ERROR

    # 5) Check if token is >= 0x8D (141)
    addiu   $t2, $zero, 141
    slt     $t3, $t1, $t2       # $t3 = 1 if token < 141 (so if 0, then >= 141)
    beqz    $t3, REPL_SYNTAX_ERROR

    # 6) Valid command (0x80 <= token <= 0x8C)
    # Calculate jump table offset: (token - 0x80) * 4
    addiu   $t2, $t1, -128      # $t2 = token - 0x80
    sll     $t2, $t2, 2         # $t2 = offset in bytes
    
    # Advance token pointer past the command token
    addiu   $t0, $t0, 1
    la      $t3, MEM_TOKEN_PTR
    sw      $t0, 0($t3)

    # Load target address from CMD_JUMP_TABLE
    la      $t3, CMD_JUMP_TABLE
    addu    $t3, $t3, $t2
    lw      $t4, 0($t3)         # $t4 = target address

    # Jump to target address
    jr      $t4

# -----------------------------------------------------------------------
# DO_LET - Assigns an evaluated expression to a variable (A-Z)
# Input:  None (uses MEM_TOKEN_PTR)
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_LET:
    addiu   $sp, $sp, -16
    sw      $ra, 12($sp)
    sw      $s0, 8($sp)

    # 1. Read variable token
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)         # Current token pointer
    lbu     $s0, 0($t0)         # $s0 = variable token (0xD0-0xE9)

    # Check variable range (0xD0 = 208, 0xEA = 234)
    addiu   $t1, $zero, 208
    slt     $t2, $s0, $t1
    bnez    $t2, DL_ERR         # If token < 0xD0, error

    addiu   $t1, $zero, 234
    slt     $t2, $s0, $t1
    beqz    $t2, DL_ERR         # If token >= 0xEA, error

    # 2. Advance past variable token and check '='
    addiu   $t0, $t0, 1         # Point to '='
    lbu     $t1, 0($t0)         # Read '=' token
    addiu   $t2, $zero, 61      # '=' is ASCII 61
    bne     $t1, $t2, DL_ERR    # If not '=', error

    # 3. Advance past '=' and set MEM_TOKEN_PTR
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    # 4. Evaluate expression
    jal     EVAL_EXPR           # Result in $v0

    # 5. Set variable
    addu    $a0, $s0, $zero     # Variable token
    addu    $a1, $v0, $zero     # Evaluated value
    jal     VAR_SET

    # 6. Return to REPL loop
    lw      $s0, 8($sp)
    lw      $ra, 12($sp)
    addiu   $sp, $sp, 16
    j       REPL

DL_ERR:
    lw      $s0, 8($sp)
    lw      $ra, 12($sp)
    addiu   $sp, $sp, 16
    j       REPL_SYNTAX_ERROR

# -----------------------------------------------------------------------
# DO_PRINT - Evaluates and prints expressions, strings, or formats output
# Input:  None (uses MEM_TOKEN_PTR)
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_PRINT:
    addiu   $sp, $sp, -24
    sw      $ra, 20($sp)
    sw      $s0, 16($sp)
    sw      $s1, 12($sp)

DP_LOOP:
    la      $t0, MEM_TOKEN_PTR
    lw      $s0, 0($t0)         # $s0 = current token pointer
    lbu     $s1, 0($s0)         # $s1 = current token byte

    # Check for EOL (0x00)
    beqz    $s1, DP_CRLF

    # Check for string literal marker (0xC1 = 193)
    addiu   $t1, $zero, 193
    beq     $s1, $t1, DP_STRING

    # Check for semicolon ';' (ASCII 59)
    addiu   $t1, $zero, 59
    beq     $s1, $t1, DP_SEMI

    # Check for comma ',' (ASCII 44)
    addiu   $t1, $zero, 44
    beq     $s1, $t1, DP_COMMA

    # Otherwise, it's an expression
    jal     EVAL_EXPR           # Result in $v0
    
    # Print the evaluated number
    addu    $a0, $v0, $zero
    jal     PRINT_NUMBER
    j       DP_LOOP

DP_STRING:
    # Skip the opening 0xC1 marker
    addiu   $s0, $s0, 1

DP_STR_LOOP:
    lbu     $a0, 0($s0)         # Read character
    addiu   $t1, $zero, 193     # 0xC1 closing marker
    beq     $a0, $t1, DP_STR_END
    beqz    $a0, DP_STR_PRINT   # Treat null as printable (don't abort)

    jal     OUTCHAR             # Print char
    addiu   $s0, $s0, 1         # Move to next char
    j       DP_STR_LOOP

DP_STR_PRINT:
    jal     OUTCHAR             # Print the null byte
    addiu   $s0, $s0, 1
    j       DP_STR_LOOP

DP_STR_END:
    # Skip the closing 0xC1 marker
    addiu   $s0, $s0, 1

    la      $t0, MEM_TOKEN_PTR
    sw      $s0, 0($t0)         # Save advanced pointer
    j       DP_LOOP

DP_SEMI:
    # Skip the semicolon
    addiu   $s0, $s0, 1
    la      $t0, MEM_TOKEN_PTR
    sw      $s0, 0($t0)

    # If the next token is 0x00, we suppress the CRLF and exit
    lbu     $t1, 0($s0)
    beqz    $t1, DP_EXIT_NO_CRLF
    j       DP_LOOP

DP_COMMA:
    # Skip the comma
    addiu   $s0, $s0, 1
    la      $t0, MEM_TOKEN_PTR
    sw      $s0, 0($t0)

    # Print 8 spaces
    addiu   $s1, $zero, 8
DP_TAB_LOOP:
    addiu   $a0, $zero, 32      # Space character
    jal     OUTCHAR
    addiu   $s1, $s1, -1
    bnez    $s1, DP_TAB_LOOP
    j       DP_LOOP

DP_CRLF:
    jal     PRINT_CRLF

DP_EXIT_NO_CRLF:
    lw      $s1, 12($sp)
    lw      $s0, 16($sp)
    lw      $ra, 20($sp)
    addiu   $sp, $sp, 24
    j       REPL

# -----------------------------------------------------------------------
# DO_NEW - Clears program memory and resets all variables
# Input:  None
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_NEW:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    jal     PROG_INIT
    jal     VAR_INIT
    
    # Reset GOSUB stack pointer depth
    la      $t0, MEM_GOSUB_SP
    sw      $zero, 0($t0)

    jal     PRINT_OK

    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL

# -----------------------------------------------------------------------
# DO_REM - Handles comments (REMarks) by ignoring the rest of the line
# Input:  None
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_REM:
    j       REPL

# -----------------------------------------------------------------------
# DO_FREE - Calculates and prints the remaining free memory bytes
# Input:  None
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_FREE:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    la      $t0, MEM_PROG_START
    addiu   $t0, $t0, 1024      # End of program memory buffer
    la      $t1, MEM_PROG_END
    lw      $t1, 0($t1)         # Current program end
    subu    $a0, $t0, $t1       # $a0 = free bytes
    
    jal     PRINT_NUMBER
    jal     PRINT_CRLF

    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL

# -----------------------------------------------------------------------
# DO_LIST - Prints all tokenized BASIC lines
# Input:  None
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_LIST:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)
    jal     CMD_LIST
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL

# -----------------------------------------------------------------------
# DO_EXIT - Gracefully exits the interpreter
# Input:  None
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_EXIT:
    addiu   $v0, $zero, 10      # Exit syscall code
    syscall

# -----------------------------------------------------------------------
# DO_RUN - Begins execution of the stored BASIC program
# Input:  None
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_RUN:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    la      $t0, MEM_PROG_START
    lw      $t1, 0($t0)         # Read next_ptr of first line node
    beqz    $t1, RUN_NO_PROG    # If null, empty program

    # Reset GOSUB stack pointer depth
    la      $t0, MEM_GOSUB_SP
    sw      $zero, 0($t0)

    # Set run flag to 1
    addiu   $t1, $zero, 1
    la      $t0, MEM_RUN_FLAG
    sw      $t1, 0($t0)

    # Set MEM_LINE_PTR to MEM_PROG_START
    la      $t0, MEM_PROG_START
    la      $t1, MEM_LINE_PTR
    sw      $t0, 0($t1)

    # Set MEM_TOKEN_PTR to tokens of first line node (MEM_PROG_START + 6)
    addiu   $t0, $t0, 6
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL_DISPATCH

RUN_NO_PROG:
    la      $a0, MSG_NO_PROGRAM
    jal     PRINT_STR
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL

# -----------------------------------------------------------------------
# RUN_NEXT - Advance execution to the next program line
# Input:  None
# Output: None
# Clobbers: $t0, $t1, $t2
# -----------------------------------------------------------------------
RUN_NEXT:
    # Save the return address register because we are going to use 'jal'
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    # Invoke non-blocking break key check
    jal     CHECK_BREAK         # Returns $v0 = 1 if break key is pressed, 0 otherwise

    # Restore the return address register
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4

    # If $v0 is zero, continue execution normally
    beq     $v0, $zero, RN_CONTINUE

    # Break requested! Turn off the execution state and return to interactive prompt
    la      $t0, MEM_RUN_FLAG
    sw      $zero, 0($t0)       # Clear execution flag
    j       REPL                # Return straight to prompt

RN_CONTINUE:
    la      $t0, MEM_LINE_PTR
    lw      $t0, 0($t0)         # $t0 = current line node address
    lw      $t1, 0($t0)         # $t1 = next node address (next_ptr)

    # Check if next node's next_ptr is null (sentinel node)
    lw      $t2, 0($t1)         # $t2 = next_ptr of next node
    beqz    $t2, RUN_END        # If null, end of program

    # Update MEM_LINE_PTR to next node
    la      $t0, MEM_LINE_PTR
    sw      $t1, 0($t0)

    # Set MEM_TOKEN_PTR to point to the tokens of the new node (node + 6)
    addiu   $t1, $t1, 6
    la      $t0, MEM_TOKEN_PTR
    sw      $t1, 0($t0)

    # Dispatch tokens
    j       REPL_DISPATCH

# -----------------------------------------------------------------------
# RUN_END - Turn off execution mode and return to interactive REPL
# Input:  None
# Output: None
# Clobbers: $t0
# -----------------------------------------------------------------------
RUN_END:
    la      $t0, MEM_RUN_FLAG
    sw      $zero, 0($t0)       # Clear execution flag
    j       REPL                # Return to interactive prompt

# -----------------------------------------------------------------------
# DO_END - Resets run flag to stop program execution
# Input:  None
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_END:
    j       RUN_END

# -----------------------------------------------------------------------
# DO_GOTO - Jumps execution to a specific line number
# Input:  None (uses MEM_TOKEN_PTR)
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_GOTO:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    jal     EVAL_EXPR           # Get target line number in $v0
    
    addu    $a0, $v0, $zero     # Target line number in $a0
    jal     LINE_FIND           # Find line, returns $v0=found(1/0), $v1=node address
    beqz    $v0, DG_ERR         # If not found, syntax error

    # Enable run flag
    addiu   $t0, $zero, 1
    la      $t1, MEM_RUN_FLAG
    sw      $t0, 0($t1)

    # Update MEM_LINE_PTR to the target line node
    la      $t0, MEM_LINE_PTR
    sw      $v1, 0($t0)

    # Set MEM_TOKEN_PTR to point to the tokens of the line node ($v1 + 6)
    addiu   $v1, $v1, 6
    la      $t0, MEM_TOKEN_PTR
    sw      $v1, 0($t0)

    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL_DISPATCH

DG_ERR:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL_SYNTAX_ERROR

# -----------------------------------------------------------------------
# DO_GOSUB - Pushes current line onto stack and jumps to a target
# Input:  None (uses MEM_TOKEN_PTR)
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_GOSUB:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    # Check GOSUB stack pointer depth (max depth 16)
    la      $t0, MEM_GOSUB_SP
    lw      $t1, 0($t0)         # $t1 = GOSUB stack pointer depth
    addiu   $t2, $zero, 16      # Max depth is 16
    beq     $t1, $t2, GOSUB_ERR # If full, stack overflow error

    # Push MEM_LINE_PTR to MEM_GOSUB_STK[MEM_GOSUB_SP]
    sll     $t2, $t1, 2         # Offset
    la      $t3, MEM_GOSUB_STK
    addu    $t3, $t3, $t2       # Stack slot address
    la      $t4, MEM_LINE_PTR
    lw      $t4, 0($t4)         # Current line pointer
    sw      $t4, 0($t3)         # Store on stack

    # Increment GOSUB stack pointer depth
    addiu   $t1, $t1, 1
    sw      $t1, 0($t0)

    # Evaluate target line number
    jal     EVAL_EXPR           # Target line number in $v0

    # Search for target line
    addu    $a0, $v0, $zero
    jal     LINE_FIND           # Find line, returns $v0=found(1/0), $v1=node address
    beqz    $v0, GOSUB_ERR      # If not found, error

    # Enable run flag
    addiu   $t0, $zero, 1
    la      $t1, MEM_RUN_FLAG
    sw      $t0, 0($t1)

    # Update MEM_LINE_PTR to target line node
    la      $t0, MEM_LINE_PTR
    sw      $v1, 0($t0)

    # Update MEM_TOKEN_PTR to target line's first token ($v1 + 6)
    addiu   $v1, $v1, 6
    la      $t0, MEM_TOKEN_PTR
    sw      $v1, 0($t0)

    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL_DISPATCH

GOSUB_ERR:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL_SYNTAX_ERROR

# -----------------------------------------------------------------------
# DO_RETURN - Pops a line pointer from the stack and resumes execution
# Input:  None
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_RETURN:
    la      $t0, MEM_GOSUB_SP
    lw      $t1, 0($t0)         # $t1 = GOSUB stack pointer depth
    beqz    $t1, RETURN_ERR     # If zero, stack underflow error

    # Decrement GOSUB stack pointer depth
    addiu   $t1, $t1, -1
    sw      $t1, 0($t0)         # Save updated depth

    # Pop line pointer from MEM_GOSUB_STK[MEM_GOSUB_SP]
    sll     $t2, $t1, 2         # Offset in bytes
    la      $t3, MEM_GOSUB_STK
    addu    $t3, $t3, $t2       # Slot address
    lw      $t4, 0($t3)         # Load saved line pointer

    # Restore current line pointer
    la      $t0, MEM_LINE_PTR
    sw      $t4, 0($t0)

    # Go back to REPL loop which will advance to the next line (via RUN_NEXT)
    j       REPL

RETURN_ERR:
    j       REPL_SYNTAX_ERROR

# -----------------------------------------------------------------------
# DO_IF - Evaluates condition and executes THEN clause if true
# Input:  None (uses MEM_TOKEN_PTR)
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_IF:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    jal     EVAL_COND           # Evaluate condition, result in $v0
    
    # If condition is false ($v0 == 0), skip the rest of the line
    beqz    $v0, DI_FALSE

    # Condition is true! Check 'THEN' token (0x8D = 141)
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)         # Current token pointer
    lbu     $t1, 0($t0)         # $t1 = next token byte
    addiu   $t2, $zero, 141     # 'THEN' token
    bne     $t1, $t2, DI_ERR

    # Advance past 'THEN' token
    addiu   $t0, $t0, 1
    
    # Read the command token
    lbu     $t1, 0($t0)         # $t1 = command token

    # Check if FREE token (0xA0 = 160)
    addiu   $t2, $zero, 160
    bne     $t1, $t2, DI_NOT_FREE
    
    # Advance past FREE token
    addiu   $t0, $t0, 1
    la      $t3, MEM_TOKEN_PTR
    sw      $t0, 0($t3)
    
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       DO_FREE

DI_NOT_FREE:
    # Check if command token is valid (0x80 <= token <= 0x8C)
    addiu   $t2, $zero, 128     # 0x80
    slt     $t3, $t1, $t2
    bnez    $t3, DI_ERR         # If token < 0x80, error

    addiu   $t2, $zero, 141     # 0x8D
    slt     $t3, $t1, $t2
    beqz    $t3, DI_ERR         # If token >= 0x8D, error

    # Valid command token. Advance past it
    addiu   $t0, $t0, 1
    la      $t3, MEM_TOKEN_PTR
    sw      $t0, 0($t3)

    # Dispatch via jump table
    addiu   $t2, $t1, -128      # $t2 = token - 0x80
    sll     $t2, $t2, 2         # $t2 = offset in bytes
    la      $t3, CMD_JUMP_TABLE
    addu    $t3, $t3, $t2
    lw      $t4, 0($t3)         # Target address

    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    jr      $t4

DI_FALSE:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL

DI_ERR:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    j       REPL_SYNTAX_ERROR

# -----------------------------------------------------------------------
# DO_INPUT - Reads user input into a variable, optionally printing a string
# Input:  None (uses MEM_TOKEN_PTR)
# Output: None
# Clobbers: None
# -----------------------------------------------------------------------
DO_INPUT:
    addiu   $sp, $sp, -24
    sw      $ra, 20($sp)
    sw      $s0, 16($sp)
    sw      $s1, 12($sp)
    sw      $s2, 8($sp)

    la      $t0, MEM_TOKEN_PTR
    lw      $s0, 0($t0)         # $s0 = current token pointer
    lbu     $s1, 0($s0)         # $s1 = first token byte after INPUT

    # 1. Check if first token is string literal marker (0xC1 = 193)
    addiu   $t1, $zero, 193
    bne     $s1, $t1, DIN_PROMPT

    # Prompt with custom string literal
    addiu   $s0, $s0, 1         # Skip opening 0xC1

DIN_STR_LOOP:
    lbu     $a0, 0($s0)         # Read char from string
    addiu   $t1, $zero, 193     # 0xC1 closing marker
    beq     $a0, $t1, DIN_STR_END
    beqz    $a0, DIN_ERR         # Safety exit if null byte reached

    jal     OUTCHAR             # Print char
    addiu   $s0, $s0, 1
    j       DIN_STR_LOOP

DIN_STR_END:
    addiu   $s0, $s0, 1         # Skip closing 0xC1
    lbu     $t1, 0($s0)         # Read next token
    addiu   $t2, $zero, 59      # ';' separator (ASCII 59)
    bne     $t1, $t2, DIN_ERR
    
    addiu   $s0, $s0, 1         # Skip ';' separator
    j       DIN_VAR

DIN_PROMPT:
    addiu   $a0, $zero, 63      # '?' ASCII is 63
    jal     OUTCHAR
    addiu   $a0, $zero, 32      # ' ' (space)
    jal     OUTCHAR

DIN_VAR:
    # Read target variable token
    lbu     $s2, 0($s0)         # $s2 = variable token (0xD0-0xE9)

    # Check variable range (0xD0 = 208, 0xEA = 234)
    addiu   $t1, $zero, 208
    slt     $t2, $s2, $t1
    bnez    $t2, DIN_ERR

    addiu   $t1, $zero, 234
    slt     $t2, $s2, $t1
    beqz    $t2, DIN_ERR

    # Advance token pointer past variable
    addiu   $s0, $s0, 1
    la      $t0, MEM_TOKEN_PTR
    sw      $s0, 0($t0)

    # Read user input into MEM_INPUT_BUF
    jal     READ_LINE

    # Parse input from MEM_INPUT_BUF
    la      $t0, MEM_INPUT_BUF
    lbu     $t1, 0($t0)         # Read first char of input buffer
    addiu   $t2, $zero, 45      # '-' ASCII is 45
    bne     $t1, $t2, DIN_PARSE

    # Negative number: skip '-' and parse
    addiu   $a0, $t0, 1
    jal     PARSE_NUMBER        # $v0 = parsed value
    
    # Negate $v0
    nor     $v0, $v0, $zero
    addiu   $v0, $v0, 1
    andi    $v0, $v0, 0xFFFF
    j       DIN_STORE

DIN_PARSE:
    la      $a0, MEM_INPUT_BUF
    jal     PARSE_NUMBER        # $v0 = parsed value

DIN_STORE:
    addu    $a0, $s2, $zero     # Variable token in $a0
    addu    $a1, $v0, $zero     # Value in $a1
    jal     VAR_SET

    lw      $s2, 8($sp)
    lw      $s1, 12($sp)
    lw      $s0, 16($sp)
    lw      $ra, 20($sp)
    addiu   $sp, $sp, 24
    j       REPL

DIN_ERR:
    lw      $s2, 8($sp)
    lw      $s1, 12($sp)
    lw      $s0, 16($sp)
    lw      $ra, 20($sp)
    addiu   $sp, $sp, 24
    j       REPL_SYNTAX_ERROR
