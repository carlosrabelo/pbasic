# vars.asm - Variable storage for PBasic (MIPS)
# -----------------------------------------------------------------------
# Manages 26 single-letter variables (A-Z) stored as 32-bit words in
# MEM_VARS (104 bytes = 26 x 4). Variable tokens 0xD0-0xE9 map to
# indices 0-25.
# -----------------------------------------------------------------------

.text

# -----------------------------------------------------------------------
# VAR_INIT - Initialize all variables to zero
# -----------------------------------------------------------------------
# Description:
#   Clears the MEM_VARS area (104 bytes) to zero.
#
# Input: None
# Output: None
# Clobbers: $t0, $t1, $t2
# -----------------------------------------------------------------------
VAR_INIT:
    la      $t0, MEM_VARS
    li      $t1, 0
    la      $t2, MEM_VARS
    addiu   $t2, $t2, 104

VI_LOOP:
    beq     $t0, $t2, VI_DONE
    sw      $zero, 0($t0)
    addiu   $t0, $t0, 4
    j       VI_LOOP

VI_DONE:
    jr      $ra

# -----------------------------------------------------------------------
# VAR_GET - Read a variable value
# -----------------------------------------------------------------------
# Description:
#   Returns the 32-bit value of the variable identified by its token.
#
# Input: $a0 = variable token (0xD0-0xE9 for A-Z)
# Output: $v0 = variable value (32-bit signed)
# Clobbers: $t0, $t1
# -----------------------------------------------------------------------
VAR_GET:
    addiu   $t0, $a0, -0xD0         # index = token - 0xD0 (0-25)
    sll     $t0, $t0, 2              # offset = index * 4
    la      $t1, MEM_VARS
    addu    $t1, $t1, $t0
    lw      $v0, 0($t1)
    jr      $ra

# -----------------------------------------------------------------------
# VAR_SET - Write a variable value
# -----------------------------------------------------------------------
# Description:
#   Stores a 32-bit value into the variable identified by its token.
#
# Input: $a0 = variable token (0xD0-0xE9 for A-Z)
#        $a1 = value to store (32-bit signed)
# Output: None
# Clobbers: $t0, $t1
# -----------------------------------------------------------------------
VAR_SET:
    addiu   $t0, $a0, -0xD0         # index = token - 0xD0 (0-25)
    sll     $t0, $t0, 2              # offset = index * 4
    la      $t1, MEM_VARS
    addu    $t1, $t1, $t0
    sw      $a1, 0($t1)
    jr      $ra
