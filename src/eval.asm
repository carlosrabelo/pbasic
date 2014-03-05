# eval.asm - Expression evaluator for PBasic (MIPS)
# -----------------------------------------------------------------------
# Implements a recursive descent parser for arithmetic expressions.
# Token pointer is tracked via MEM_TOKEN_PTR.
# -----------------------------------------------------------------------

.text

# -----------------------------------------------------------------------
# EVAL_FACTOR - Evaluate a factor (number, variable, paren expr, unary)
# -----------------------------------------------------------------------
# Description:
#   Evaluates a single factor from the token stream at MEM_TOKEN_PTR.
#   Handles: numeric literals (0xC0), variables (0xD0-0xE9),
#   parenthesized expressions ((...)), unary minus (-), and
#   built-in functions (ABS).
#
# Input: None (reads from MEM_TOKEN_PTR)
# Output: $v0 = evaluated value (32-bit signed)
#         MEM_TOKEN_PTR advanced past the consumed tokens
# Clobbers: $t0, $t1, $t2, $t3
# -----------------------------------------------------------------------
EVAL_FACTOR:
    addiu   $sp, $sp, -16
    sw      $ra, 12($sp)
    sw      $s0, 8($sp)

    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)              # $t0 = current token pointer

    lb      $t1, 0($t0)              # Read current token
    andi    $t1, $t1, 0xFF

    # --- Unary minus ---
    li      $t2, 45                   # '-'
    beq     $t1, $t2, EF_UNARY_MINUS

    # --- Number literal (0xC0) ---
    li      $t2, 0xC0
    beq     $t1, $t2, EF_NUMBER

    # --- Variable (0xD0-0xE9) ---
    li      $t2, 0xD0
    blt     $t1, $t2, EF_CHECK_PAREN
    li      $t2, 0xE9
    bgt     $t1, $t2, EF_CHECK_PAREN
    j       EF_VARIABLE

EF_CHECK_PAREN:
    # --- Parenthesized expression ---
    li      $t2, 40                   # '('
    beq     $t1, $t2, EF_PAREN

    # --- ABS function (0xA2) ---
    li      $t2, 0xA2
    beq     $t1, $t2, EF_ABS

    # --- Unknown token: return 0 ---
    li      $v0, 0
    j       EF_DONE

EF_UNARY_MINUS:
    addiu   $t0, $t0, 1              # Skip '-' token
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    jal     EVAL_FACTOR              # Recursively evaluate factor
    subu    $v0, $zero, $v0          # Negate result
    j       EF_DONE

EF_NUMBER:
    # Read 16-bit LE value after 0xC0 token
    lb      $t2, 1($t0)
    andi    $t2, $t2, 0xFF
    lb      $t3, 2($t0)
    andi    $t3, $t3, 0xFF
    sll     $t3, $t3, 8
    or      $v0, $t2, $t3            # $v0 = number value

    # Advance token pointer past 0xC0 + 2 bytes
    addiu   $t0, $t0, 3
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    j       EF_DONE

EF_VARIABLE:
    # $t1 = variable token (0xD0-0xE9)
    move    $a0, $t1
    jal     VAR_GET                  # $v0 = variable value

    addiu   $t0, $t0, 1             # Skip variable token
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    j       EF_DONE

EF_PAREN:
    addiu   $t0, $t0, 1             # Skip '(' token
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    jal     EVAL_EXPR               # Evaluate sub-expression
    move    $s0, $v0                # Save result

    # Expect ')' and skip it
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)
    li      $t2, 41                  # ')'
    beq     $t1, $t2, EF_PAREN_SKIP
    j       EF_PAREN_END

EF_PAREN_SKIP:
    addiu   $t0, $t0, 1
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)

EF_PAREN_END:
    move    $v0, $s0
    j       EF_DONE

EF_ABS:
    addiu   $t0, $t0, 1             # Skip ABS token
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)

    # Expect '('
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)
    li      $t2, 40                  # '('
    beq     $t1, $t2, EF_ABS_PAREN

    # No paren: just evaluate next factor
    jal     EVAL_FACTOR
    j       EF_ABS_DO

EF_ABS_PAREN:
    addiu   $t0, $t0, 1
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    jal     EVAL_EXPR

    # Expect ')'
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)
    li      $t2, 41                  # ')'
    beq     $t1, $t2, EF_ABS_CLOSE
    j       EF_ABS_DO

EF_ABS_CLOSE:
    addiu   $t0, $t0, 1
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)

EF_ABS_DO:
    # $v0 has the value, compute abs
    bgez    $v0, EF_DONE             # Already positive
    subu    $v0, $zero, $v0          # Negate
    j       EF_DONE

EF_DONE:
    lw      $s0, 8($sp)
    lw      $ra, 12($sp)
    addiu   $sp, $sp, 16
    jr      $ra

# -----------------------------------------------------------------------
# EVAL_EXPR - Evaluate an expression (stub for recursive calls)
# -----------------------------------------------------------------------
# Description:
#   Stub that evaluates a single term. Will be expanded in Phase 5
#   to handle addition and subtraction.
#
# Input: None (reads from MEM_TOKEN_PTR)
# Output: $v0 = evaluated value
# -----------------------------------------------------------------------
EVAL_EXPR:
    j       EVAL_FACTOR
