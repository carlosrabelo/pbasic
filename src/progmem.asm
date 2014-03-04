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

# -----------------------------------------------------------------------
# LINE_FIND - Find a line by line number in the program linked list
# -----------------------------------------------------------------------
# Description:
#   Walks the program linked list from MEM_PROG_START looking for a line
#   with the given line number. Stops at the sentinel (line number 0).
#
# Input: $a0 = line number to search for (16-bit unsigned)
# Output: $v0 = pointer to the line header if found, 0 if not found
#         $v1 = pointer to the previous line header (0 if first line)
# Clobbers: $t0, $t1, $t2, $t3, $t4
# -----------------------------------------------------------------------
LINE_FIND:
    la      $t0, MEM_PROG_START     # $t0 = current line pointer
    move    $t4, $zero               # $t4 = previous line pointer (0 = none)

LF_LOOP:
    # Read line number (16-bit LE)
    lb      $t2, 0($t0)
    andi    $t2, $t2, 0xFF
    lb      $t3, 1($t0)
    andi    $t3, $t3, 0xFF
    sll     $t3, $t3, 8
    or      $t2, $t2, $t3           # $t2 = current line number

    # Sentinel check (line number == 0)
    beqz    $t2, LF_NOT_FOUND

    # Compare with target
    beq     $t2, $a0, LF_FOUND

    # Advance to next line: skip 2-byte header, then scan past tokens + null
    move    $t4, $t0                 # Save current as previous
    addiu   $t0, $t0, 2             # Skip line number header

LF_SCAN:
    lb      $t1, 0($t0)
    addiu   $t0, $t0, 1
    bnez    $t1, LF_SCAN            # Loop until null terminator

    j       LF_LOOP

LF_FOUND:
    move    $v0, $t0                # Return pointer to matching line
    move    $v1, $t4                # Return previous line pointer (0 if first)
    jr      $ra

LF_NOT_FOUND:
    li      $v0, 0
    move    $v1, $t4
    jr      $ra
