# progmem.asm - Program memory management for PBasic (MIPS)
# -----------------------------------------------------------------------
# Manages the BASIC program stored as a linked list in MEM_PROG_START.
# Each line is stored as: [2 bytes: line_number LE] [N bytes: tokens] [0x00]
# A sentinel line with line_number = 0x0000 marks the end of the program.
# -----------------------------------------------------------------------

.text

# -----------------------------------------------------------------------
# PROG_INIT - Initialize program memory with sentinel
# -----------------------------------------------------------------------
# Description:
#   Clears the program area and writes a sentinel line (line number 0)
#   at MEM_PROG_START. Sets MEM_PROG_END to point just past the sentinel.
#
# Input: None
# Output: None
# Clobbers: $t0, $t1, $t2
# -----------------------------------------------------------------------
PROG_INIT:
    la      $t0, MEM_PROG_START
    la      $t1, MEM_PROG_END

    # Write sentinel: line number = 0x0000 (2 bytes) + null terminator
    sb      $zero, 0($t0)          # line number low byte = 0
    sb      $zero, 1($t0)          # line number high byte = 0
    sb      $zero, 2($t0)          # null terminator (empty token stream)

    # MEM_PROG_END points to byte after sentinel (start of usable space)
    addiu   $t2, $t0, 3
    sw      $t2, 0($t1)

    # Clear remaining program memory
    la      $t2, MEM_PROG_END
    lw      $t1, 0($t2)            # $t1 = current MEM_PROG_END

PI_CLEAR:
    la      $t2, MEM_PROG_START
    addiu   $t2, $t2, 1024         # End of program area
    beq     $t1, $t2, PI_DONE
    sb      $zero, 0($t1)
    addiu   $t1, $t1, 1
    j       PI_CLEAR

PI_DONE:
    jr      $ra
