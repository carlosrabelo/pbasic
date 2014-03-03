# io.asm - Base I/O routines for PBasic MIPS
# -----------------------------------------------------------------------
# Provides the low-level communication between the interpreter and the
# MARS emulator console using standard MIPS syscalls.
# -----------------------------------------------------------------------

.text

# -----------------------------------------------------------------------
# INCHAR - Read a single character from the console
# -----------------------------------------------------------------------
# Description:
#   Halts execution and waits for the user to input a single character
#   from the MARS keyboard console.
#
# Input: None
# Output: $v0 (The ASCII value of the character read)
# Clobbers: $v0
# -----------------------------------------------------------------------
INCHAR:
    li      $v0, 12         # MARS syscall 12: Read Character
    syscall                 # Execute syscall. Character is returned in $v0.
    jr      $ra             # Return to caller

# -----------------------------------------------------------------------
# OUTCHAR - Print a single character to the console
# -----------------------------------------------------------------------
# Description:
#   Prints the ASCII character passed in register $a0 to the MARS console.
#
# Input: $a0 (The ASCII character to print)
# Output: None
# Clobbers: $v0
# -----------------------------------------------------------------------
OUTCHAR:
    li      $v0, 11         # MARS syscall 11: Print Character
    syscall                 # Execute syscall. Prints character in $a0.
    jr      $ra             # Return to caller
