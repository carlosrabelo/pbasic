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

# -----------------------------------------------------------------------
# MEM_OPEN_HOLE - Open a hole in program memory for insertion
# -----------------------------------------------------------------------
# Description:
#   Shifts all data from $a0 to MEM_PROG_END right by $a1 bytes, creating
#   a gap for new data. Updates MEM_PROG_END accordingly.
#   Copy direction: right-to-left (high to low) to avoid overwriting.
#
# Input: $a0 = address where hole should start
#        $a1 = size of hole in bytes
# Output: None
# Clobbers: $t0, $t1, $t2, $t3
# -----------------------------------------------------------------------
MEM_OPEN_HOLE:
    la      $t0, MEM_PROG_END
    lw      $t0, 0($t0)              # $t0 = MEM_PROG_END (source start, copy from here down)
    addu    $t1, $t0, $a1            # $t1 = MEM_PROG_END + hole_size (destination end)

    # Update MEM_PROG_END += hole_size
    la      $t2, MEM_PROG_END
    sw      $t1, 0($t2)

    # Right-to-left copy: src = MEM_PROG_END-1 down to $a0
    beq     $t0, $a0, MOH_DONE       # Nothing to shift
    addiu   $t0, $t0, -1             # $t0 = last byte before old end
    addiu   $t1, $t1, -1             # $t1 = last byte of new region

MOH_LOOP:
    lb      $t3, 0($t0)
    sb      $t3, 0($t1)
    addiu   $t0, $t0, -1
    addiu   $t1, $t1, -1
    blt     $t0, $a0, MOH_DONE
    j       MOH_LOOP

MOH_DONE:
    jr      $ra

# -----------------------------------------------------------------------
# MEM_CLOSE_HOLE - Close a hole in program memory after deletion
# -----------------------------------------------------------------------
# Description:
#   Shifts all data from ($a0 + $a1) to MEM_PROG_END left by $a1 bytes,
#   closing the gap. Updates MEM_PROG_END accordingly.
#   Copy direction: left-to-right (low to high) to avoid overwriting.
#
# Input: $a0 = start of hole to close
#        $a1 = size of hole in bytes
# Output: None
# Clobbers: $t0, $t1, $t2, $t3
# -----------------------------------------------------------------------
MEM_CLOSE_HOLE:
    # $t0 = source (hole_start + hole_size)
    addu    $t0, $a0, $a1

    # $t1 = MEM_PROG_END
    la      $t3, MEM_PROG_END
    lw      $t1, 0($t3)

    # Update MEM_PROG_END -= hole_size
    subu    $t2, $t1, $a1
    sw      $t2, 0($t3)

    # $t2 = destination (hole_start)
    move    $t2, $a0

MCH_LOOP:
    beq     $t0, $t1, MCH_DONE
    lb      $t3, 0($t0)
    sb      $t3, 0($t2)
    addiu   $t0, $t0, 1
    addiu   $t2, $t2, 1
    j       MCH_LOOP

MCH_DONE:
    jr      $ra

# -----------------------------------------------------------------------
# LINE_STORE - Store or replace a line in the program linked list
# -----------------------------------------------------------------------
# Description:
#   Stores a new line or replaces an existing one in program memory.
#   Lines are kept sorted by line number in ascending order.
#   If MEM_TOKEN_BUF is empty (null at offset 0), deletes the line.
#
# Input: $a0 = line number (16-bit unsigned)
#        MEM_TOKEN_BUF = null-terminated token data to store
# Output: None
# Clobbers: $t0, $t1, $t2, $t3, $s0-$s5
# -----------------------------------------------------------------------
LINE_STORE:
    addiu   $sp, $sp, -28
    sw      $ra, 24($sp)
    sw      $s0, 20($sp)
    sw      $s1, 16($sp)
    sw      $s2, 12($sp)
    sw      $s3, 8($sp)
    sw      $s4, 4($sp)
    sw      $s5, 0($sp)

    move    $s0, $a0                # $s0 = line number

    # Compute token length in MEM_TOKEN_BUF
    la      $t0, MEM_TOKEN_BUF
    li      $s1, 0                  # $s1 = token length
LST_TLEN:
    lb      $t1, 0($t0)
    beqz    $t1, LST_TLEN_DONE
    addiu   $t0, $t0, 1
    addiu   $s1, $s1, 1
    j       LST_TLEN

LST_TLEN_DONE:
    addiu   $s2, $s1, 3            # $s2 = total line size = tokens + 2(line#) + 1(null)

    # Walk list to find insertion point or existing line
    la      $t0, MEM_PROG_START
    li      $s4, 0                  # $s4 = previous line pointer (0 = none)

LST_WALK:
    lb      $t1, 0($t0)
    andi    $t1, $t1, 0xFF
    lb      $t2, 1($t0)
    andi    $t2, $t2, 0xFF
    sll     $t2, $t2, 8
    or      $t1, $t1, $t2          # $t1 = current line number

    beqz    $t1, LST_INSERT_NEW    # Sentinel → insert here
    beq     $t1, $s0, LST_REPLACE  # Exact match → replace

    # Current > target → insert before current
    slt     $t3, $t1, $s0
    beqz    $t3, LST_INSERT_NEW

    # Advance to next line
    move    $s4, $t0
    addiu   $t0, $t0, 2
LST_SCAN:
    lb      $t1, 0($t0)
    addiu   $t0, $t0, 1
    bnez    $t1, LST_SCAN
    j       LST_WALK

LST_INSERT_NEW:
    # $t0 = insertion point, $s4 = previous line
    move    $s3, $t0                # $s3 = insertion point

    move    $a0, $s3
    move    $a1, $s2
    jal     MEM_OPEN_HOLE

    # Write line number (16-bit LE)
    andi    $t1, $s0, 0xFF
    sb      $t1, 0($s3)
    srl     $t1, $s0, 8
    andi    $t1, $t1, 0xFF
    sb      $t1, 1($s3)

    # Copy tokens from MEM_TOKEN_BUF
    la      $t0, MEM_TOKEN_BUF
    addiu   $t2, $s3, 2
LST_COPY:
    lb      $t1, 0($t0)
    sb      $t1, 0($t2)
    beqz    $t1, LST_DONE
    addiu   $t0, $t0, 1
    addiu   $t2, $t2, 1
    j       LST_COPY

LST_REPLACE:
    # $t0 = pointer to existing line
    move    $s3, $t0                # $s3 = existing line pointer

    # Compute old line size
    addiu   $t1, $t0, 2
LST_OLD:
    lb      $t2, 0($t1)
    addiu   $t1, $t1, 1
    bnez    $t2, LST_OLD
    sub     $s5, $t1, $s3           # $s5 = old line total size

    # Empty tokens → delete line
    beqz    $s1, LST_DELETE

    # Same size → overwrite in place
    beq     $s5, $s2, LST_OVERWRITE

    # Different size: close old hole, then re-insert
    move    $a0, $s3
    move    $a1, $s5
    jal     MEM_CLOSE_HOLE

    # Find insertion point after previous line
    beqz    $s4, LST_INS_START
    move    $t0, $s4
    addiu   $t0, $t0, 2
LST_PREV:
    lb      $t1, 0($t0)
    addiu   $t0, $t0, 1
    bnez    $t1, LST_PREV
    move    $s3, $t0
    j       LST_DO_INSERT

LST_INS_START:
    la      $s3, MEM_PROG_START

LST_DO_INSERT:
    move    $a0, $s3
    move    $a1, $s2
    jal     MEM_OPEN_HOLE

    # Write line number
    andi    $t1, $s0, 0xFF
    sb      $t1, 0($s3)
    srl     $t1, $s0, 8
    andi    $t1, $t1, 0xFF
    sb      $t1, 1($s3)

    # Copy tokens
    la      $t0, MEM_TOKEN_BUF
    addiu   $t2, $s3, 2
LST_COPY2:
    lb      $t1, 0($t0)
    sb      $t1, 0($t2)
    beqz    $t1, LST_DONE
    addiu   $t0, $t0, 1
    addiu   $t2, $t2, 1
    j       LST_COPY2

LST_OVERWRITE:
    la      $t0, MEM_TOKEN_BUF
    addiu   $t2, $s3, 2
LST_COPY3:
    lb      $t1, 0($t0)
    sb      $t1, 0($t2)
    beqz    $t1, LST_DONE
    addiu   $t0, $t0, 1
    addiu   $t2, $t2, 1
    j       LST_COPY3

LST_DELETE:
    move    $a0, $s3
    move    $a1, $s5
    jal     MEM_CLOSE_HOLE

LST_DONE:
    lw      $s5, 0($sp)
    lw      $s4, 4($sp)
    lw      $s3, 8($sp)
    lw      $s2, 12($sp)
    lw      $s1, 16($sp)
    lw      $s0, 20($sp)
    lw      $ra, 24($sp)
    addiu   $sp, $sp, 28
    jr      $ra
