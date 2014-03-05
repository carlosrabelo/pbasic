# math.asm - Mathematical engine for PBasic (MIPS)
# -----------------------------------------------------------------------
# Provides 16-bit unsigned arithmetic: multiplication, division, modulo.
# Uses MIPS native mult/div instructions.
# -----------------------------------------------------------------------

.text

# -----------------------------------------------------------------------
# MUL16 - 16-bit unsigned multiplication
# -----------------------------------------------------------------------
# Description:
#   Multiplies two 16-bit unsigned values using MIPS native mult.
#   Result fits in 32 bits (max 65535 * 65535 = 4294836225).
#
# Input: $a0 = multiplicand (16-bit unsigned)
#        $a1 = multiplier (16-bit unsigned)
# Output: $v0 = product (32-bit unsigned, low word)
# Clobbers: $t0
# -----------------------------------------------------------------------
MUL16:
    andi    $a0, $a0, 0xFFFF       # Mask to 16 bits
    andi    $a1, $a1, 0xFFFF       # Mask to 16 bits
    mult    $a0, $a1               # HI:LO = $a0 * $a1
    mflo    $v0                    # $v0 = low word of product
    jr      $ra

# -----------------------------------------------------------------------
# DIV16 - 16-bit unsigned division
# -----------------------------------------------------------------------
# Description:
#   Divides two 16-bit unsigned values using MIPS native div.
#   Returns quotient. Does NOT handle divide-by-zero.
#
# Input: $a0 = dividend (16-bit unsigned)
#        $a1 = divisor (16-bit unsigned)
# Output: $v0 = quotient (32-bit unsigned)
# Clobbers: $t0
# -----------------------------------------------------------------------
DIV16:
    andi    $a0, $a0, 0xFFFF       # Mask to 16 bits
    andi    $a1, $a1, 0xFFFF       # Mask to 16 bits
    div     $a0, $a1               # LO = quotient, HI = remainder
    mflo    $v0                    # $v0 = quotient
    jr      $ra

# -----------------------------------------------------------------------
# MOD16 - 16-bit unsigned modulo
# -----------------------------------------------------------------------
# Description:
#   Computes remainder of two 16-bit unsigned values using MIPS native div.
#   Does NOT handle divide-by-zero.
#
# Input: $a0 = dividend (16-bit unsigned)
#        $a1 = divisor (16-bit unsigned)
# Output: $v0 = remainder (32-bit unsigned)
# Clobbers: $t0
# -----------------------------------------------------------------------
MOD16:
    andi    $a0, $a0, 0xFFFF       # Mask to 16 bits
    andi    $a1, $a1, 0xFFFF       # Mask to 16 bits
    div     $a0, $a1               # LO = quotient, HI = remainder
    mfhi    $v0                    # $v0 = remainder
    jr      $ra
