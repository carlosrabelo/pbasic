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
# EVAL_TERM - Evaluate multiplicative expression (*, /)
# -----------------------------------------------------------------------
# Description:
#   Evaluates a term by calling EVAL_FACTOR, then loops while the next
#   token is '*' (42) or '/' (47), applying the operation to the
#   accumulated result.
#
# Input: None (reads from MEM_TOKEN_PTR)
# Output: $v0 = evaluated value (32-bit signed)
# Clobbers: $t0, $t1, $s0, $s1
# -----------------------------------------------------------------------
EVAL_TERM:
    addiu   $sp, $sp, -16
    sw      $ra, 12($sp)
    sw      $s0, 8($sp)

    jal     EVAL_FACTOR              # $v0 = first factor
    move    $s0, $v0                 # $s0 = accumulator

ET_LOOP:
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)              # Peek next token
    andi    $t1, $t1, 0xFF

    li      $t2, 42                  # '*'
    beq     $t1, $t2, ET_MUL

    li      $t2, 47                  # '/'
    beq     $t1, $t2, ET_DIV

    j       ET_DONE                  # No more * or /

ET_MUL:
    addiu   $t0, $t0, 1             # Skip '*' token
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    jal     EVAL_FACTOR              # $v0 = next factor
    move    $a0, $s0
    move    $a1, $v0
    jal     MUL16                    # $v0 = $a0 * $a1
    move    $s0, $v0
    j       ET_LOOP

ET_DIV:
    addiu   $t0, $t0, 1             # Skip '/' token
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    jal     EVAL_FACTOR              # $v0 = next factor
    move    $a0, $s0
    move    $a1, $v0
    jal     DIV16                    # $v0 = $a0 / $a1
    move    $s0, $v0
    j       ET_LOOP

ET_DONE:
    move    $v0, $s0
    lw      $s0, 8($sp)
    lw      $ra, 12($sp)
    addiu   $sp, $sp, 16
    jr      $ra

# -----------------------------------------------------------------------
# EVAL_EXPR - Evaluate an expression (+, -)
# -----------------------------------------------------------------------
# Description:
#   Evaluates an expression by calling EVAL_TERM, then loops while the
#   next token is '+' (43) or '-' (45), applying the operation.
#
# Input: None (reads from MEM_TOKEN_PTR)
# Output: $v0 = evaluated value (32-bit signed)
# Clobbers: $t0, $t1, $s0
# -----------------------------------------------------------------------
EVAL_EXPR:
    addiu   $sp, $sp, -12
    sw      $ra, 8($sp)
    sw      $s0, 4($sp)

    jal     EVAL_TERM                # $v0 = first term
    move    $s0, $v0                 # $s0 = accumulator

EE_LOOP:
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)              # Peek next token
    andi    $t1, $t1, 0xFF

    li      $t2, 43                  # '+'
    beq     $t1, $t2, EE_ADD

    li      $t2, 45                  # '-'
    beq     $t1, $t2, EE_SUB

    j       EE_DONE                  # No more + or -

EE_ADD:
    addiu   $t0, $t0, 1             # Skip '+' token
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    jal     EVAL_TERM                # $v0 = next term
    addu    $s0, $s0, $v0
    j       EE_LOOP

EE_SUB:
    addiu   $t0, $t0, 1             # Skip '-' token
    la      $t1, MEM_TOKEN_PTR
    sw      $t0, 0($t1)

    jal     EVAL_TERM                # $v0 = next term
    subu    $s0, $s0, $v0
    j       EE_LOOP

EE_DONE:
    move    $v0, $s0
    lw      $s0, 4($sp)
    lw      $ra, 8($sp)
    addiu   $sp, $sp, 12
    jr      $ra

# -----------------------------------------------------------------------
# EVAL_COND - Evaluate a boolean comparison condition
# -----------------------------------------------------------------------
# Description:
#   Evaluates a condition by evaluating left expression, then checking
#   for a comparison operator, then evaluating the right expression.
#   Returns -1 (true) or 0 (false) following BASIC convention.
#   If no comparison operator is found, returns the expression value.
#
#   Operators: = (61), < (60), > (62), <> (0xB0), <= (0xB1), >= (0xB2)
#
# Input: None (reads from MEM_TOKEN_PTR)
# Output: $v0 = -1 (true) or 0 (false)
# Clobbers: $t0, $t1, $t2, $s0, $s1, $s2
# -----------------------------------------------------------------------
EVAL_COND:
    addiu   $sp, $sp, -20
    sw      $ra, 16($sp)
    sw      $s0, 12($sp)
    sw      $s1, 8($sp)
    sw      $s2, 4($sp)

    # Evaluate left-hand expression
    jal     EVAL_EXPR
    move    $s0, $v0                 # $s0 = left value

    # Peek at next token
    la      $t0, MEM_TOKEN_PTR
    lw      $t0, 0($t0)
    lb      $t1, 0($t0)
    andi    $t1, $t1, 0xFF

    # Check for comparison operators
    li      $t2, 61                  # '='
    beq     $t1, $t2, EC_EQ
    li      $t2, 60                  # '<'
    beq     $t1, $t2, EC_LT
    li      $t2, 62                  # '>'
    beq     $t1, $t2, EC_GT
    li      $t2, 0xB0                # '<>'
    beq     $t1, $t2, EC_NE
    li      $t2, 0xB1                # '<='
    beq     $t1, $t2, EC_LE
    li      $t2, 0xB2                # '>='
    beq     $t1, $t2, EC_GE

    # No comparison operator: return expression value as-is
    j       EC_DONE

    # --- Common: skip operator token, evaluate right expr ---
EC_EQ:
    addiu   $t0, $t0, 1
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    jal     EVAL_EXPR
    xor     $t0, $s0, $v0            # equal if XOR == 0
    sltiu   $v0, $t0, 1              # $v0 = (XOR == 0) ? 1 : 0
    j       EC_TRUE_CHECK

EC_NE:
    addiu   $t0, $t0, 1
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    jal     EVAL_EXPR
    xor     $t0, $s0, $v0
    sltu    $v0, $zero, $t0          # $v0 = (XOR != 0) ? 1 : 0
    j       EC_TRUE_CHECK

EC_LT:
    addiu   $t0, $t0, 1
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    jal     EVAL_EXPR
    slt     $v0, $s0, $v0            # $v0 = (left < right) ? 1 : 0
    j       EC_TRUE_CHECK

EC_GT:
    addiu   $t0, $t0, 1
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    jal     EVAL_EXPR
    slt     $v0, $v0, $s0            # $v0 = (right < left) ? 1 : 0
    j       EC_TRUE_CHECK

EC_LE:
    addiu   $t0, $t0, 1
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    jal     EVAL_EXPR
    slt     $t0, $v0, $s0            # $t0 = (right < left)
    xori    $v0, $t0, 1              # $v0 = !(right < left) = left <= right
    j       EC_TRUE_CHECK

EC_GE:
    addiu   $t0, $t0, 1
    la      $t2, MEM_TOKEN_PTR
    sw      $t0, 0($t2)
    jal     EVAL_EXPR
    slt     $t0, $s0, $v0            # $t0 = (left < right)
    xori    $v0, $t0, 1              # $v0 = !(left < right) = left >= right
    j       EC_TRUE_CHECK

EC_TRUE_CHECK:
    # Convert 1 → -1 (BASIC true), keep 0 as-is
    beqz    $v0, EC_DONE
    li      $v0, -1

EC_DONE:
    lw      $s2, 4($sp)
    lw      $s1, 8($sp)
    lw      $s0, 12($sp)
    lw      $ra, 16($sp)
    addiu   $sp, $sp, 20
    jr      $ra
