; io.asm - Base I/O routines for PBasic Z80
; -----------------------------------------------------------------------
; Provides low-level TTY communication via port-mapped I/O at Port 0x00.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; INCHAR - Read a single character from TTY (Port 0x00)
; -----------------------------------------------------------------------
; Blocks until a character is available from the TTY input.
;
; Input:  None
; Output: A = ASCII value of the character read
; -----------------------------------------------------------------------
INCHAR:
	in	a, (0)
	ret

; -----------------------------------------------------------------------
; OUTCHAR - Write a single character to TTY (Port 0x00)
; -----------------------------------------------------------------------
; Sends the character to the TTY output.
;
; Input:  A = ASCII character to print
; Output: None
; -----------------------------------------------------------------------
OUTCHAR:
	out	(0), a
	ret
