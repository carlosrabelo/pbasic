; defs.inc - Memory map and constants for PBasic M6502 (m6502)
; -----------------------------------------------------------------------
; This file defines the hardware constants and memory layout used by the
; interpreter, including buffer sizes and stack boundaries.
; -----------------------------------------------------------------------

#define TTY_DATA_ADDR   $FFE0    ; Memory-mapped TTY data register
#define TTY_STATUS_ADDR $FFE1    ; Memory-mapped TTY status register
#define TTY_RX_READY    $01      ; Bit 0 = RX ready
#define TTY_TX_READY    $02      ; Bit 1 = TX ready

#define MEM_PROG_START  $2000    ; Start address of the user BASIC program memory

; --- Zero Page Memory ($00 - $FF) ---
; Zero Page is crucial for 6502 indirect addressing.
#define MEM_TOKEN_PTR   $00      ; Pointer to the current token being evaluated (2 bytes)
#define MEM_LINE_PTR    $02      ; Pointer to the start of the currently executing BASIC line (2 bytes)
#define MEM_PROG_END    $04      ; Pointer to the end of the user BASIC program (2 bytes)
#define MEM_RAND_SEED   $06      ; Random number generator seed (2 bytes)
#define MEM_RUN_FLAG    $08      ; Execution state flag (1 = running program, 0 = interactive mode) (1 byte)
#define MEM_GOSUB_SP    $09      ; Current GOSUB stack pointer (depth index) (1 byte)
#define MEM_SCRATCH     $0A      ; General purpose scratchpad (2 bytes)
#define MEM_SCRATCH2    $0C      ; General purpose scratchpad 2 (2 bytes)

; --- Main RAM Memory ($F000 - $FFFF) ---
#define MEM_VARS        $F000    ; Base address for the 26 variables (A-Z) (2 bytes each)
#define MEM_INPUT_BUF   $F034    ; Raw text input buffer (80 bytes)
#define MEM_TOKEN_BUF   $F084    ; Tokenized line buffer (160 bytes max)
#define MEM_GOSUB_STK   $F124    ; GOSUB return address stack (16 levels * 2 bytes = 32 bytes)

; --- Constants ---
#define INPUT_BUF_LEN   80       ; Maximum length of the raw input line buffer
#define TOKEN_BUF_LEN   160      ; Maximum length of the tokenized line buffer
#define GOSUB_DEPTH     16       ; Maximum allowed depth of nested GOSUB calls
