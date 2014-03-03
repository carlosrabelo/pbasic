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

# -----------------------------------------------------------------------
# PRINT_STR - Print a null-terminated string
# -----------------------------------------------------------------------
# Description:
#   Prints the null-terminated string located at address $a0.
#
# Input: $a0 (Address of string)
# Output: None
# Clobbers: $v0
# -----------------------------------------------------------------------
PRINT_STR:
    li      $v0, 4          # MARS syscall 4: Print String
    syscall
    jr      $ra

# -----------------------------------------------------------------------
# PRINT_NUMBER - Print an integer
# -----------------------------------------------------------------------
# Description:
#   Prints the 32-bit integer passed in $a0.
#
# Input: $a0 (Integer to print)
# Output: None
# Clobbers: $v0
# -----------------------------------------------------------------------
PRINT_NUMBER:
    li      $v0, 1          # MARS syscall 1: Print Integer
    syscall
    jr      $ra

# -----------------------------------------------------------------------
# PRINT_CRLF - Print a newline
# -----------------------------------------------------------------------
# Description:
#   Prints a CR/LF (newline) sequence to the console.
#
# Input: None
# Output: None
# Clobbers: $v0, $a0
# -----------------------------------------------------------------------
PRINT_CRLF:
    la      $a0, STR_CRLF
    li      $v0, 4          # MARS syscall 4: Print String
    syscall
    jr      $ra
