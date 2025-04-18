; math.asm - Core mathematical primitives for PBasic (Z80)
; -----------------------------------------------------------------------
; Implements 16-bit integer multiplication, division, modulo, and pseudo-random
; number generation. These are pure functions independent of the parser.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; MUL16 - Unsigned 16-bit multiply.
; Input:  HL = op1, DE = op2
; Output: HL = op1 * op2 (lower 16 bits)
; Clobbers: AF, BC, DE
; -----------------------------------------------------------------------
MUL16:
    ld      A, H                ; Check if both high bytes are 0
    or      D
    jr      nz, MUL16_16BIT     ; If not, use 16-bit math

    ; --- Fast-path: 8-bit * 8-bit ---
    ld      B, 0
    ld      C, L                ; BC = op1 (low byte only)
    ld      HL, 0               ; Accumulator
    ld      A, 8                ; 8 iterations
MUL16_LOOP_8:
    add     HL, HL              ; Shift result left
    rl      E                   ; Shift op2 left, MSB into carry
    jr      nc, MUL16_SKIP_8
    add     HL, BC              ; Add op1 if carry
MUL16_SKIP_8:
    dec     A
    jr      nz, MUL16_LOOP_8
    ret

MUL16_16BIT:
    ld      B, H                ; Save op1 in BC
    ld      C, L
    ld      HL, 0               ; Initialize accumulator (result) to 0
    ld      A, 16               ; Loop 16 times
MUL16_LOOP:
    add     HL, HL              ; Shift result left by 1
    rl      E                   ; Shift op2 (DE) left, MSB goes into Carry
    rl      D
    jr      nc, MUL16_SKIP      ; If Carry is 0, don't add op1
    add     HL, BC              ; If Carry is 1, add op1 (BC) to result
MUL16_SKIP:
    dec     A                   ; Decrement loop counter
    jr      nz, MUL16_LOOP      ; Repeat until all 16 bits are processed
    ret                         ; Return result in HL

; -----------------------------------------------------------------------
; DIV16_AUX - Shared 16-bit division helper
; Input:  HL = dividend, DE = divisor
; Output: HL = quotient, A = remainder high, C = remainder low
; Clobbers: AF, BC, DE
; -----------------------------------------------------------------------
DIV16_AUX:
    ld      A, H                ; Save dividend in A (high) and C (low)
    ld      C, L
    ld      HL, 0               ; Initialize remainder to 0
    ld      B, 16               ; Loop 16 times
DIV16_AUX_LOOP:
    sla     C                   ; Shift dividend left, MSB to Carry
    rla
    adc     HL, HL              ; Shift remainder left, pull in Carry
    push    AF                  ; Save A (dividend high byte)
    xor     A                   ; Clear Carry
    sbc     HL, DE              ; Subtract divisor from remainder
    jr      nc, DIV16_AUX_SUB   ; If no borrow, subtraction successful
    add     HL, DE              ; If borrow, restore remainder
    pop     AF                  ; Restore A
    dec     B
    jr      nz, DIV16_AUX_LOOP  ; Loop (quotient bit is 0)
    ld      H, A                ; Move quotient from AC to HL
    ld      L, C
    ret
DIV16_AUX_SUB:
    pop     AF                  ; Restore A
    inc     C                   ; Set lowest bit of quotient to 1
    dec     B
    jr      nz, DIV16_AUX_LOOP  ; Loop
    ld      H, A                ; Move quotient from AC to HL
    ld      L, C
    ret

; -----------------------------------------------------------------------
; DIV16 - Unsigned 16-bit divide.
; Input:  HL = dividend, DE = divisor
; Output: HL = quotient
; Clobbers: AF, BC, DE.  Returns 65535 (0xFFFF) on div-by-zero.
; -----------------------------------------------------------------------
DIV16:
    ld      A, D                ; Check for division by zero
    or      E
    jr      nz, DIV16_OK        ; If divisor is not 0, proceed
    ld      HL, 0xFFFF          ; If 0, return 65535
    ret
DIV16_OK:
    ld      A, H                ; Check if both high bytes are 0
    or      D
    jr      nz, DIV16_16BIT     ; If not, use 16-bit math

    ; --- Fast-path: 8-bit / 8-bit ---
    ld      C, E                ; C = divisor
    ld      H, 0                ; H = remainder
    ld      B, 8                ; 8 iterations
DIV16_LOOP_8:
    sla     L                   ; Shift dividend
    rl      H                   ; Shift remainder
    ld      A, H
    cp      C                   ; Compare remainder with divisor
    jr      c, DIV16_SKIP_8
    sub     C                   ; Subtract divisor (carry already set)
    ld      H, A                ; Store result
    inc     L                   ; Set lowest bit of quotient
DIV16_SKIP_8:
    dec     B
    jr      nz, DIV16_LOOP_8
    ld      H, 0                ; L = quotient, set H to 0
    ret

DIV16_16BIT:
    call    DIV16_AUX           ; HL = quotient, C = remainder
    ret

; -----------------------------------------------------------------------
; MOD16 - Unsigned 16-bit modulo.
; Input:  HL = dividend, DE = divisor
; Output: HL = remainder
; Clobbers: AF, BC, DE. Returns dividend if div-by-zero.
; -----------------------------------------------------------------------
MOD16:
    ld      A, D                ; Check for division by zero
    or      E
    ret     z                   ; If divisor is 0, return dividend as remainder

    ld      A, H                ; Check if both high bytes are 0
    or      D
    jr      nz, MOD16_16BIT     ; If not, use 16-bit math

    ; --- Fast-path: 8-bit % 8-bit ---
    ld      C, E                ; C = divisor
    ld      H, 0                ; H = remainder
    ld      B, 8                ; 8 iterations
MOD16_LOOP_8:
    sla     L                   ; Shift dividend
    rl      H                   ; Shift remainder
    ld      A, H
    cp      C                   ; Compare remainder with divisor
    jr      c, MOD16_SKIP_8
    sub     C                   ; Subtract divisor (carry already set)
    ld      H, A                ; Store result
    inc     L                   ; Set lowest bit of quotient
MOD16_SKIP_8:
    dec     B
    jr      nz, MOD16_LOOP_8
    ld      L, H                ; H = remainder, move to L
    ld      H, 0
    ret

MOD16_16BIT:
    ld      A, H                ; Save dividend in A (high) and C (low)
    ld      C, L
    ld      HL, 0               ; Initialize remainder to 0
    ld      B, 16               ; Loop 16 times
MOD16_AUX_LOOP:
    sla     C                   ; Shift dividend left, MSB to Carry
    rla
    adc     HL, HL              ; Shift remainder left, pull in Carry
    push    AF                  ; Save A
    xor     A                   ; Clear Carry
    sbc     HL, DE              ; Subtract divisor from remainder
    jr      nc, MOD16_AUX_SUB   ; If no borrow, subtraction successful
    add     HL, DE              ; If borrow, restore remainder
    pop     AF                  ; Restore A
    dec     B
    jr      nz, MOD16_AUX_LOOP  ; Loop
    ret                         ; Remainder is in HL
MOD16_AUX_SUB:
    pop     AF                  ; Restore A
    dec     B
    jr      nz, MOD16_AUX_LOOP  ; Loop (no need to inc C for modulo)
    ret                         ; Remainder is in HL

; -----------------------------------------------------------------------
; RAND16 - Pseudo-random number generator (16-bit LCG).
; Algorithm: seed = seed * 5 + 2971
; Output: HL = new random number
; Clobbers: AF, BC, DE
; -----------------------------------------------------------------------
RAND16:
    ld      HL, (MEM_RAND_SEED)
    ; Multiply HL by 5
    ld      B, H
    ld      C, L
    add     HL, HL              ; * 2
    add     HL, HL              ; * 4
    add     HL, BC              ; * 5
    ; Add prime constant 2971
    ld      DE, 2971
    add     HL, DE
    ld      (MEM_RAND_SEED), HL ; Save new seed
    ret
