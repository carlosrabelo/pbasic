; memmgr.asm - Memory management for PBasic (Z80)
; -----------------------------------------------------------------------
; Low-level operations on the program memory area (opening and closing holes).
; Used when inserting or deleting lines.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; MEM_OPEN_HOLE - Make room for A bytes at HL.
; Shifts [HL .. MEM_PROG_END) right by A. Updates MEM_PROG_END += A.
; Input:  HL = hole start, A = hole size (1..255)
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
MEM_OPEN_HOLE:
    push    AF                  ; Save AF
    push    BC                  ; Save BC
    push    DE                  ; Save DE
    push    HL                  ; Save HL

    ld      (MEM_SCRATCH + 2), A ; Save hole size temporarily

    ld      DE, (MEM_PROG_END)  ; DE = End of program (one past last byte)
    push    HL                  ; Save hole start
    ld      H, D                ; Move DE to HL for subtraction
    ld      L, E
    pop     BC                  ; BC = hole start
    xor     A                   ; Clear carry
    sbc     HL, BC              ; HL = End - Start (number of bytes to move)
    ld      B, H                ; BC = number of bytes to move
    ld      C, L

    ld      A, (MEM_SCRATCH + 2) ; A = hole size
    ld      HL, (MEM_PROG_END)  ; HL = End of program
    add     A, L                ; Add hole size to low byte
    ld      L, A
    jr      nc, MOH_NC1         ; If no carry, skip high byte increment
    inc     H                   ; Propagate carry to high byte
MOH_NC1:
    ld      (MEM_PROG_END), HL  ; Update MEM_PROG_END to new end

    ld      A, B                ; Check if number of bytes to move is 0
    or      C
    jr      z, MOH_DONE         ; If 0 bytes to move, we're done (hole at very end)

    ld      H, D                ; HL = Old end
    ld      L, E
    dec     HL                  ; HL = Last byte to move (source)
    ld      DE, (MEM_PROG_END)  ; DE = New end
    dec     DE                  ; DE = Last byte destination
    lddr                        ; Move BC bytes from HL to DE, decrementing pointers (right shift)

MOH_DONE:
    pop     HL                  ; Restore registers
    pop     DE
    pop     BC
    pop     AF
    ret                         ; Return

; -----------------------------------------------------------------------
; MEM_CLOSE_HOLE - Remove A bytes at HL.
; Shifts [HL+A .. MEM_PROG_END) left by A. Updates MEM_PROG_END -= A.
; Input:  HL = hole start, A = hole size (1..255)
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
MEM_CLOSE_HOLE:
    push    AF                  ; Save AF
    push    BC                  ; Save BC
    push    DE                  ; Save DE
    push    HL                  ; Save HL

    ld      (MEM_SCRATCH + 2), A ; Save hole size

    ld      B, 0                ; Prepare BC = hole size
    ld      C, A
    add     HL, BC              ; HL = start of block to move (hole start + size)
    ld      D, H                ; DE = block start (source)
    ld      E, L

    pop     HL                  ; HL = hole start (destination)
    push    HL                  ; Save it back

    push    HL                  ; Save destination
    push    DE                  ; Save source
    ld      HL, (MEM_PROG_END)  ; HL = End of program
    xor     A                   ; Clear carry
    sbc     HL, DE              ; HL = End - Source (number of bytes to move)
    ld      B, H                ; BC = number of bytes to move
    ld      C, L
    pop     DE                  ; Restore source
    pop     HL                  ; Restore destination

    ld      A, (MEM_SCRATCH + 2) ; A = hole size
    push    HL                  ; Save destination
    push    DE                  ; Save source
    ld      HL, (MEM_PROG_END)  ; HL = End of program
    ld      D, 0                ; DE = hole size
    ld      E, A
    xor     A                   ; Clear carry
    sbc     HL, DE              ; HL = New End (Old End - hole size)
    ld      (MEM_PROG_END), HL  ; Update MEM_PROG_END
    pop     DE                  ; Restore source
    pop     HL                  ; Restore destination

    ex      DE, HL              ; HL = source, DE = destination
    ldir                        ; Move BC bytes from HL to DE, incrementing pointers (left shift)

    pop     HL                  ; Restore registers
    pop     DE
    pop     BC
    pop     AF
    ret                         ; Return

; -----------------------------------------------------------------------
; FIX_NEXT_SUB - Subtract A from each node's next-ptr starting at HL.
; Stops at sentinel (next-ptr = 0x0000).
; Input: HL = first node, A = subtract amount
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
FIX_NEXT_SUB:
    push    AF                  ; Save registers
    push    DE
    push    HL
    ld      E, A                ; E = subtract amount
    ld      D, 0                ; D = 0 (DE = 16-bit amount)

FNS_LOOP:
    ld      A, (HL)             ; Check if next-ptr is 0x0000
    inc     HL
    or      (HL)
    dec     HL
    jr      z, FNS_DONE         ; If 0x0000, we hit the sentinel, stop

    ld      A, (HL)             ; Load low byte of next-ptr
    sub     E                   ; Subtract low byte of amount
    ld      (HL), A             ; Store back
    inc     HL                  ; Move to high byte
    ld      A, (HL)             ; Load high byte of next-ptr
    sbc     A, D                ; Subtract with carry (high byte)
    ld      (HL), A             ; Store back
    dec     HL                  ; Back to low byte

    ld      A, (HL)             ; Read the new (subtracted) next-ptr
    inc     HL
    ld      H, (HL)             ; H = high byte
    ld      L, A                ; L = low byte (HL = next node)
    jp      FNS_LOOP            ; Continue to next node

FNS_DONE:
    pop     HL                  ; Restore registers
    pop     DE
    pop     AF
    ret                         ; Return

; -----------------------------------------------------------------------
; FIX_NEXT_ADD - Add A to each node's next-ptr starting at HL.
; Stops at sentinel (next-ptr = 0x0000).
; Input: HL = first node, A = add amount
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
FIX_NEXT_ADD:
    push    AF                  ; Save registers
    push    DE
    push    HL
    ld      E, A                ; E = add amount
    ld      D, 0                ; D = 0 (DE = 16-bit amount)

FNA_LOOP:
    ld      A, (HL)             ; Check if next-ptr is 0x0000
    inc     HL
    or      (HL)
    dec     HL
    jr      z, FNA_DONE         ; If 0x0000, we hit the sentinel, stop

    ld      A, (HL)             ; Load low byte of next-ptr
    add     A, E                ; Add low byte of amount
    ld      (HL), A             ; Store back
    inc     HL                  ; Move to high byte
    ld      A, (HL)             ; Load high byte of next-ptr
    adc     A, D                ; Add with carry (high byte)
    ld      (HL), A             ; Store back
    dec     HL                  ; Back to low byte

    ld      A, (HL)             ; Read the new (added) next-ptr
    inc     HL
    ld      H, (HL)             ; H = high byte
    ld      L, A                ; L = low byte (HL = next node)
    jp      FNA_LOOP            ; Continue to next node

FNA_DONE:
    pop     HL                  ; Restore registers
    pop     DE
    pop     AF
    ret                         ; Return
