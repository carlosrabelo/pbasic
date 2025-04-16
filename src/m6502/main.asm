; main.asm - PBasic interpreter entry point (m6502)
; -----------------------------------------------------------------------
; This is the main compilation unit for the M6502 interpreter.
; It defines the boot sequence and initializes the environment.
; -----------------------------------------------------------------------

#include "defs.inc"

; Start compilation at address $0000 to fill the entire 64KB memory map
* = $0000

; Pad the first 32KB of memory (Zero Page, Stack, RAM) with zeros
.dsb $8000, $00

; -----------------------------------------------------------------------
; START - System initialization and boot entry point.
; Input  None
; Output None
; Clobbers X
; -----------------------------------------------------------------------
START:
    ldx #$FF            ; Load X with $FF
    txs                 ; Transfer X to Stack Pointer (SP = $FF, points to $01FF)

; -----------------------------------------------------------------------
; HALT_LOOP - Safe fallback infinite loop to trap the CPU.
; Input  None
; Output None
; Clobbers None
; -----------------------------------------------------------------------
HALT_LOOP:
    jmp HALT_LOOP       ; Infinite loop to trap CPU

; Fill memory up to hardware vectors
.dsb $FFFA - *, $00

; -----------------------------------------------------------------------
; M6502 Hardware Vectors
; -----------------------------------------------------------------------
* = $FFFA
    .word START         ; NMI Vector
    .word START         ; Reset Vector (loads PC with START on reset)
    .word START         ; IRQ/BRK Vector
