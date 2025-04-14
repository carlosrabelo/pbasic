; defs.inc - Memory map and constants for PBasic Z80
; -----------------------------------------------------------------------
; This file defines the hardware constants and memory layout used by the
; interpreter, including buffer sizes and stack boundaries.
; -----------------------------------------------------------------------

TTY_DATA_PORT: equ 0x00         ; Hardware I/O port for the serial Teletype (TTY) data register
TTY_STATUS_PORT: equ 0x01       ; TTY status register (bit 0 = RX ready, bit 1 = TX ready)
MEM_PROG_START: equ 0x2000      ; Start address of the user BASIC program memory
MEM_VARS: equ 0xF000            ; Base address for the 26 variables (A-Z) (2 bytes each)
MEM_INPUT_BUF: equ 0xF034       ; Address of the raw text input buffer (80 bytes)
MEM_TOKEN_BUF: equ 0xF084       ; Address of the tokenized line buffer (160 bytes max)
MEM_GOSUB_STK: equ 0xF124       ; Address of the GOSUB return address stack
MEM_GOSUB_SP: equ 0xF144        ; Address holding the current GOSUB stack pointer (depth index)
MEM_RAND_SEED: equ 0xF146       ; Address holding the current random number generator seed (2 bytes)
MEM_TOKEN_PTR: equ 0xF148       ; Pointer to the current token being evaluated (2 bytes)
MEM_LINE_PTR: equ 0xF14A        ; Pointer to the start of the currently executing BASIC line (2 bytes)
MEM_RUN_FLAG: equ 0xF14C        ; Execution state flag (1 = running program, 0 = interactive mode)
MEM_PROG_END: equ 0xF14E        ; Pointer to the end of the user BASIC program (free memory start)
MEM_SCRATCH: equ 0xF150         ; General purpose scratchpad byte
MEM_STACK: equ 0xFF00           ; Top of the Z80 hardware stack (grows downwards)

INPUT_BUF_LEN: equ 80           ; Maximum length of the raw input line buffer
TOKEN_BUF_LEN: equ 160          ; Maximum length of the tokenized line buffer
GOSUB_DEPTH: equ 16             ; Maximum allowed depth of nested GOSUB calls
