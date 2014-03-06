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
#   Main interactive loop. Prompts the user, reads input, tokenizes,
#   and dispatches commands or stores program lines.
# -----------------------------------------------------------------------
REPL:
    # Print prompt "> "
    la      $a0, STR_PROMPT
    jal     PRINT_STR

    # Read user input into MEM_INPUT_BUF
    jal     READ_LINE

    # Tokenize input into MEM_TOKEN_BUF
    jal     TOKENIZE

    # Dispatch command or store program line
    jal     REPL_DISPATCH

    # Loop back to prompt
    j       REPL

# -----------------------------------------------------------------------
# REPL_DISPATCH - Dispatch tokenized input to command handlers
# -----------------------------------------------------------------------
# Description:
#   Reads the first token from MEM_TOKEN_BUF and dispatches to the
#   appropriate command handler. If the first token is a number (0xC0),
#   treats the input as a program line to store.
#
# Input: None (reads MEM_TOKEN_BUF)
# Output: None
# Clobbers: $t0, $t1
# -----------------------------------------------------------------------
REPL_DISPATCH:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    la      $t0, MEM_TOKEN_BUF
    lb      $t1, 0($t0)              # Read first token
    andi    $t1, $t1, 0xFF

    # Empty input?
    beqz    $t1, RD_DONE

    # Number token → program line storage
    li      $t0, 0xC0
    beq     $t1, $t0, RD_LINE_STORE

    # Keyword dispatch
    li      $t0, 0x80                # LET
    beq     $t1, $t0, RD_LET
    li      $t0, 0x81                # GOTO
    beq     $t1, $t0, RD_GOTO
    li      $t0, 0x82                # GOSUB
    beq     $t1, $t0, RD_GOSUB
    li      $t0, 0x83                # PRINT
    beq     $t1, $t0, RD_PRINT
    li      $t0, 0x84                # IF
    beq     $t1, $t0, RD_IF
    li      $t0, 0x85                # INPUT
    beq     $t1, $t0, RD_INPUT
    li      $t0, 0x86                # RETURN
    beq     $t1, $t0, RD_RETURN
    li      $t0, 0x87                # END
    beq     $t1, $t0, RD_END
    li      $t0, 0x88                # LIST
    beq     $t1, $t0, RD_LIST
    li      $t0, 0x89                # RUN
    beq     $t1, $t0, RD_RUN
    li      $t0, 0x8A                # NEW
    beq     $t1, $t0, RD_NEW
    li      $t0, 0x8B                # EXIT
    beq     $t1, $t0, RD_EXIT
    li      $t0, 0x8C                # REM
    beq     $t1, $t0, RD_REM
    li      $t0, 0xA0                # FREE
    beq     $t1, $t0, RD_FREE

    # Unknown command
    la      $a0, MSG_ERROR
    jal     PRINT_STR
    j       RD_DONE

RD_LINE_STORE:
    jal     CMD_LINE_STORE
    j       RD_OK

RD_LET:
    jal     CMD_LET
    j       RD_DONE

RD_GOTO:
    jal     CMD_GOTO
    j       RD_DONE

RD_GOSUB:
    jal     CMD_GOSUB
    j       RD_DONE

RD_PRINT:
    jal     CMD_PRINT
    j       RD_DONE

RD_IF:
    jal     CMD_IF
    j       RD_DONE

RD_INPUT:
    jal     CMD_INPUT
    j       RD_DONE

RD_RETURN:
    jal     CMD_RETURN
    j       RD_DONE

RD_END:
    jal     CMD_END
    j       RD_DONE

RD_LIST:
    jal     CMD_LIST
    j       RD_DONE

RD_RUN:
    jal     CMD_RUN
    j       RD_DONE

RD_NEW:
    jal     CMD_NEW
    j       RD_OK

RD_EXIT:
    jal     CMD_EXIT
    j       RD_DONE

RD_REM:
    j       RD_DONE

RD_FREE:
    jal     CMD_FREE
    j       RD_DONE

RD_OK:
    la      $a0, MSG_OK
    jal     PRINT_STR

RD_DONE:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    jr      $ra

# -----------------------------------------------------------------------
# CMD_LINE_STORE - Store a program line from tokenized input
# -----------------------------------------------------------------------
# Description:
#   Extracts line number from first token (0xC0 + 16-bit LE), shifts
#   remaining tokens to the front of MEM_TOKEN_BUF, and calls LINE_STORE.
# -----------------------------------------------------------------------
CMD_LINE_STORE:
    la      $t0, MEM_TOKEN_BUF
    # Skip 0xC0 token + 2-byte line number
    addiu   $t0, $t0, 3

    # Read line number (16-bit LE) from after the 0xC0 token
    la      $t1, MEM_TOKEN_BUF
    lb      $t2, 1($t1)
    andi    $t2, $t2, 0xFF
    lb      $t3, 2($t1)
    andi    $t3, $t3, 0xFF
    sll     $t3, $t3, 8
    or      $a0, $t2, $t3           # $a0 = line number

    # Shift remaining tokens to front of MEM_TOKEN_BUF
    la      $t1, MEM_TOKEN_BUF
CLS_SHIFT:
    lb      $t2, 0($t0)
    sb      $t2, 0($t1)
    addiu   $t0, $t0, 1
    addiu   $t1, $t1, 1
    bnez    $t2, CLS_SHIFT

    jal     LINE_STORE
    jr      $ra

# -----------------------------------------------------------------------
# Command stubs (to be implemented in Phase 6-8)
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# CMD_LET - Execute LET command (assign expression to variable)
# -----------------------------------------------------------------------
# Description:
#   Token stream after LET (0x80): variable (0xD0-0xE9), '=' (61), expr.
#   Sets MEM_TOKEN_PTR to the variable token, evaluates the expression
#   after '=', and stores the result via VAR_SET.
# -----------------------------------------------------------------------
CMD_LET:
    addiu   $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $s0, 0($sp)

    # Token 1 = variable (offset 1)
    la      $t0, MEM_TOKEN_BUF
    lb      $s0, 1($t0)              # $s0 = variable token
    andi    $s0, $s0, 0xFF

    # Token 2 = '=' (offset 2), skip it
    # Token 3+ = expression (offset 3)
    la      $t0, MEM_TOKEN_BUF
    addiu   $t0, $t0, 3
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    # Evaluate expression
    jal     EVAL_EXPR

    # Store result in variable
    move    $a0, $s0
    move    $a1, $v0
    jal     VAR_SET

    lw      $s0, 0($sp)
    lw      $ra, 4($sp)
    addiu   $sp, $sp, 8
    jr      $ra

# -----------------------------------------------------------------------
# CMD_PRINT - Execute PRINT command
# -----------------------------------------------------------------------
# Description:
#   Evaluates and prints a comma/semicolon-separated list of expressions
#   and string literals. ',' triggers a tab (column width 14). ';' prints
#   with no separator. Ends with newline unless last separator was ';' or ','.
#
#   Token stream after PRINT (0x83):
#     0xC1 ... 0xC1  = string literal
#     expression      = evaluated and printed as number
#     44 (,)          = tab
#     59 (;)          = no separator
# -----------------------------------------------------------------------
CMD_PRINT:
    addiu   $sp, $sp, -12
    sw      $ra, 8($sp)
    sw      $s0, 4($sp)

    # Set MEM_TOKEN_PTR to token after PRINT (offset 1 in MEM_TOKEN_BUF)
    la      $t0, MEM_TOKEN_BUF
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    li      $s0, 1                   # $s0 = 1 means print newline at end

CP_LOOP:
    # Peek current token
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)
    andi    $t1, $t1, 0xFF

    # End of stream?
    beqz    $t1, CP_END

    # Check for separator tokens
    li      $t2, 44                  # ','
    beq     $t1, $t2, CP_COMMA
    li      $t2, 59                  # ';'
    beq     $t1, $t2, CP_SEMI

    # Check for string literal (0xC1)
    li      $t2, 0xC1
    beq     $t1, $t2, CP_STRING

    # Otherwise evaluate as expression and print number
    jal     EVAL_EXPR
    move    $a0, $v0
    jal     PRINT_NUMBER
    j       CP_LOOP

CP_STRING:
    # Skip 0xC1 start marker
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

CPS_LOOP:
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)
    andi    $t1, $t1, 0xFF

    # End marker (0xC1) or null?
    li      $t2, 0xC1
    beq     $t1, $t2, CPS_CLOSE
    beqz    $t1, CP_END

    # Print character and advance
    move    $a0, $t1
    jal     OUTCHAR

    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)
    j       CPS_LOOP

CPS_CLOSE:
    # Skip 0xC1 end marker
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)
    j       CP_LOOP

CP_COMMA:
    # Print tab (ASCII 9)
    li      $a0, 9
    jal     OUTCHAR
    # Skip ',' token
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)
    li      $s0, 0                   # Suppress newline
    j       CP_LOOP

CP_SEMI:
    # Skip ';' token
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)
    li      $s0, 0                   # Suppress newline
    j       CP_LOOP

CP_END:
    bnez    $s0, CP_NEWLINE
    j       CP_DONE

CP_NEWLINE:
    jal     PRINT_CRLF

CP_DONE:
    lw      $s0, 4($sp)
    lw      $ra, 8($sp)
    addiu   $sp, $sp, 12
    jr      $ra

CMD_IF:
    addiu   $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $s0, 0($sp)

    # Set MEM_TOKEN_PTR to token after IF (offset 1)
    la      $t0, MEM_TOKEN_BUF
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    # Evaluate condition (stops at THEN or end)
    jal     EVAL_COND
    move    $s0, $v0                  # $s0 = condition result (-1 or 0)

    # Expect THEN (0x8D) and skip it
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)
    andi    $t1, $t1, 0xFF
    li      $t2, 0x8D
    bne     $t1, $t2, CI_DONE         # No THEN found
    addiu   $t0, $t0, 1
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    # Check condition result
    beqz    $s0, CI_DONE              # False → skip

    # True → check what follows THEN
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)
    andi    $t1, $t1, 0xFF

    # If number token (0xC0) → GOTO that line
    li      $t2, 0xC0
    beq     $t1, $t2, CI_GOTO

    # Otherwise: copy remaining tokens to front of MEM_TOKEN_BUF and dispatch
    la      $t1, MEM_TOKEN_BUF
CI_COPY:
    lb      $t2, 0($t0)
    sb      $t2, 0($t1)
    addiu   $t0, $t0, 1
    addiu   $t1, $t1, 1
    bnez    $t2, CI_COPY

    jal     REPL_DISPATCH
    j       CI_DONE

CI_GOTO:
    # Read line number after 0xC0
    lb      $t2, 1($t0)
    andi    $t2, $t2, 0xFF
    lb      $t3, 2($t0)
    andi    $t3, $t3, 0xFF
    sll     $t3, $t3, 8
    or      $a0, $t2, $t3

    jal     LINE_FIND

    beqz    $v0, CI_DONE
    la      $t0, MEM_LINE_PTR
    sw      $v0, 0($t0)

CI_DONE:
    lw      $s0, 0($sp)
    lw      $ra, 4($sp)
    addiu   $sp, $sp, 8
    jr      $ra

CMD_INPUT:
CMD_GOTO:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    # Read line number token after GOTO (offset 1 = 0xC0, offset 2-3 = LE number)
    la      $t0, MEM_TOKEN_BUF
    lb      $t1, 1($t0)
    andi    $t1, $t1, 0xFF
    li      $t2, 0xC0
    bne     $t1, $t2, CG_DONE         # Not a number token

    lb      $t2, 2($t0)
    andi    $t2, $t2, 0xFF
    lb      $t3, 3($t0)
    andi    $t3, $t3, 0xFF
    sll     $t3, $t3, 8
    or      $a0, $t2, $t3             # $a0 = target line number

    jal     LINE_FIND

    beqz    $v0, CG_DONE              # Line not found
    la      $t0, MEM_LINE_PTR
    sw      $v0, 0($t0)               # Update MEM_LINE_PTR to found line

CG_DONE:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    jr      $ra
CMD_GOSUB:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    # Check stack depth (max 16)
    la      $t0, MEM_GOSUB_SP
    lw      $t0, 0($t0)
    li      $t1, 16
    bge     $t0, $t1, CGS_OVERFLOW

    # Push return address (next line after current) onto GOSUB stack
    la      $t1, MEM_LINE_PTR
    lw      $t1, 0($t1)              # $t1 = current line

    # Advance to next line
    move    $t2, $t1
    addiu   $t2, $t2, 2              # Skip line number header
CGS_SKIP:
    lb      $t3, 0($t2)
    addiu   $t2, $t2, 1
    bnez    $t3, CGS_SKIP            # Skip past tokens + null
    # $t2 = next line (return address)

    # Store $t2 at GOSUB_STK[SP]
    la      $t3, MEM_GOSUB_STK
    sll     $t0, $t0, 2              # offset = SP * 4
    addu    $t3, $t3, $t0
    sw      $t2, 0($t3)

    # SP++
    la      $t0, MEM_GOSUB_SP
    lw      $t1, 0($t0)
    addiu   $t1, $t1, 1
    sw      $t1, 0($t0)

    # Now jump like GOTO: read target line number
    la      $t0, MEM_TOKEN_BUF
    lb      $t1, 1($t0)
    andi    $t1, $t1, 0xFF
    li      $t2, 0xC0
    bne     $t1, $t2, CGS_DONE

    lb      $t2, 2($t0)
    andi    $t2, $t2, 0xFF
    lb      $t3, 3($t0)
    andi    $t3, $t3, 0xFF
    sll     $t3, $t3, 8
    or      $a0, $t2, $t3

    jal     LINE_FIND

    beqz    $v0, CGS_DONE
    la      $t0, MEM_LINE_PTR
    sw      $v0, 0($t0)

    j       CGS_DONE

CGS_OVERFLOW:
    la      $a0, MSG_ERROR
    jal     PRINT_STR
    li      $t0, 0
    la      $t1, MEM_RUN_FLAG
    sw      $t0, 0($t1)

CGS_DONE:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    jr      $ra

CMD_RETURN:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    # Check stack not empty
    la      $t0, MEM_GOSUB_SP
    lw      $t0, 0($t0)
    blez    $t0, CRT_UNDERFLOW

    # SP--
    addiu   $t0, $t0, -1
    la      $t1, MEM_GOSUB_SP
    sw      $t0, 0($t1)

    # Pop return address from GOSUB_STK[SP]
    la      $t1, MEM_GOSUB_STK
    sll     $t0, $t0, 2
    addu    $t1, $t1, $t0
    lw      $t2, 0($t1)              # $t2 = return line pointer

    # Set MEM_LINE_PTR to return address
    la      $t0, MEM_LINE_PTR
    sw      $t2, 0($t0)

    j       CRT_DONE

CRT_UNDERFLOW:
    la      $a0, MSG_ERROR
    jal     PRINT_STR
    li      $t0, 0
    la      $t1, MEM_RUN_FLAG
    sw      $t0, 0($t1)

CRT_DONE:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    jr      $ra
CMD_END:
    li      $t0, 0
    la      $t1, MEM_RUN_FLAG
    sw      $t0, 0($t1)               # Clear RUN_FLAG to stop execution
    jr      $ra

# -----------------------------------------------------------------------
# CMD_RUN - Execute the program from the first line
# -----------------------------------------------------------------------
# Description:
#   Traverses the program linked list from MEM_PROG_START, copying each
#   line's tokens into MEM_TOKEN_BUF and dispatching via REPL_DISPATCH.
#   Sets MEM_RUN_FLAG = 1. Stops at sentinel or when MEM_RUN_FLAG is
#   cleared (by END, EXIT, or error).
#   After dispatch, checks MEM_LINE_PTR for GOTO/GOSUB jumps: if the
#   pointer changed during execution, continues from the new position.
# -----------------------------------------------------------------------
CMD_RUN:
    addiu   $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $s0, 0($sp)

    la      $t0, MEM_PROG_START
    lb      $t1, 0($t0)
    andi    $t1, $t1, 0xFF
    bnez    $t1, CR_HAS_PROGRAM

    la      $a0, MSG_NO_PROGRAM
    jal     PRINT_STR
    j       CR_DONE

CR_HAS_PROGRAM:
    li      $t0, 1
    la      $t1, MEM_RUN_FLAG
    sw      $t0, 0($t1)               # MEM_RUN_FLAG = 1

    la      $s0, MEM_PROG_START       # $s0 = current line pointer

CR_LOOP:
    # Check RUN_FLAG
    la      $t0, MEM_RUN_FLAG
    lw      $t0, 0($t0)
    beqz    $t0, CR_DONE

    # Read line number (16-bit LE) — check for sentinel
    lb      $t0, 0($s0)
    andi    $t0, $t0, 0xFF
    lb      $t1, 1($s0)
    andi    $t1, $t1, 0xFF
    sll     $t1, $t1, 8
    or      $t2, $t0, $t1
    beqz    $t2, CR_DONE              # Sentinel reached

    # Set MEM_LINE_PTR to current line
    la      $t0, MEM_LINE_PTR
    sw      $s0, 0($t0)

    # Copy tokens (after 2-byte header) into MEM_TOKEN_BUF
    la      $t0, MEM_TOKEN_BUF
    addiu   $t1, $s0, 2               # Source = line tokens
CR_COPY:
    lb      $t2, 0($t1)
    sb      $t2, 0($t0)
    beqz    $t2, CR_COPY_DONE
    addiu   $t0, $t0, 1
    addiu   $t1, $t1, 1
    j       CR_COPY

CR_COPY_DONE:
    # Dispatch the command
    jal     REPL_DISPATCH

    # Check RUN_FLAG again (END/EXIT may have cleared it)
    la      $t0, MEM_RUN_FLAG
    lw      $t0, 0($t0)
    beqz    $t0, CR_DONE

    # Check if MEM_LINE_PTR was changed (GOTO/GOSUB jumped)
    la      $t0, MEM_LINE_PTR
    lw      $t0, 0($t0)
    bne     $t0, $s0, CR_JUMPED

    # Advance to next line
    addiu   $t0, $s0, 2               # Skip line number
CR_ADVANCE:
    lb      $t1, 0($t0)
    addiu   $t0, $t0, 1
    bnez    $t1, CR_ADVANCE           # Skip past tokens + null

    move    $s0, $t0                   # $s0 = next line
    j       CR_LOOP

CR_JUMPED:
    move    $s0, $t0                   # Continue from jumped-to line
    j       CR_LOOP

CR_DONE:
    li      $t0, 0
    la      $t1, MEM_RUN_FLAG
    sw      $t0, 0($t1)               # MEM_RUN_FLAG = 0

    lw      $s0, 0($sp)
    lw      $ra, 4($sp)
    addiu   $sp, $sp, 8
    jr      $ra

CMD_FREE:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)

    # Available = (MEM_PROG_START + 1024) - MEM_PROG_END
    la      $t0, MEM_PROG_START
    addiu   $t0, $t0, 1024          # $t0 = end of program area
    la      $t1, MEM_PROG_END
    lw      $t1, 0($t1)             # $t1 = current program end
    subu    $a0, $t0, $t1           # $a0 = free bytes
    jal     PRINT_NUMBER
    jal     PRINT_CRLF

    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    jr      $ra

CMD_NEW:
    addiu   $sp, $sp, -4
    sw      $ra, 0($sp)
    jal     PROG_INIT
    jal     VAR_INIT
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    jr      $ra

CMD_EXIT:
    li      $v0, 10
    syscall
