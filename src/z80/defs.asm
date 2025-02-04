; defs.asm - Memory map and constants for PBasic Z80
; -----------------------------------------------------------------------
; Z80 architecture uses 16-bit addressing. Variables are 16-bit words to
; match native register width, unlike the 32-bit words used in MIPS.

; --- Program memory (linked list, grows upward) ---
MEM_PROG_START:	equ	$C000
MEM_PROG_SIZE:	equ	4096

; --- Variables (26 x 2 bytes = 52 bytes) ---
MEM_VARS:	equ	$D000

; --- Buffers ---
MEM_INPUT_BUF:	equ	$D040		; 128 bytes
MEM_TOKEN_BUF:	equ	$D0C0		; 160 bytes

; --- GOSUB return stack (16 levels x 2 bytes = 32 bytes) ---
MEM_GOSUB_STK:	equ	$D160
MEM_GOSUB_SP:	equ	$D180		; depth (1 byte)

; --- Runtime state ---
MEM_RAND_SEED:	equ	$D182		; 2 bytes
MEM_TOKEN_PTR:	equ	$D184		; 2 bytes
MEM_LINE_PTR:	equ	$D186		; 2 bytes
MEM_RUN_FLAG:	equ	$D188		; 1 byte
MEM_PROG_END:	equ	$D18A		; 2 bytes
MEM_SCRATCH:	equ	$D18C		; 2 bytes
MEM_SCRATCH_LEN:equ	$D18E		; 2 bytes

; --- Stack ---
STACK_TOP:	equ	$FFFF		; initial stack pointer

; --- Constants ---
GOSUB_DEPTH:	equ	16
INPUT_BUF_LEN:	equ	128
TOKEN_BUF_LEN:	equ	160
