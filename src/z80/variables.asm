; vars.asm - Variable storage for PBasic (Z80)
; -----------------------------------------------------------------------
; Handles 26 16-bit variables A-Z. Stored at MEM_VARS (0xF000).
; Tokens for variables: 0xD0=A, 0xD1=B, ..., 0xE9=Z.
; Layout: MEM_VARS + (token - 0xD0) * 2
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; VAR_INIT - Set all 26 variables to 0.
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
VAR_INIT:
    push    AF                  ; Save AF
    push    BC                  ; Save BC
    push    HL                  ; Save HL
    ld      HL, MEM_VARS        ; Point HL to the start of the variables array
    ld      (HL), 0             ; Zero the first byte
    ld      DE, MEM_VARS + 1    ; Point DE to the second byte
    ld      BC, 51              ; We need to clear 26*2 = 52 bytes total. 1 byte is cleared, 51 left
    ldir                        ; Copy 0 from HL to DE, effectively filling the array with zeros
    pop     HL                  ; Restore HL
    pop     BC                  ; Restore BC
    pop     AF                  ; Restore AF
    ret                         ; Return

; -----------------------------------------------------------------------
; VAR_GET - Read 16-bit variable value.
; Input:  A = variable token (0xD0-0xE9)
; Output: HL = value
; Preserves: BC, DE
; -----------------------------------------------------------------------
VAR_GET:
    sub     0xD0                ; Subtract 0xD0 to convert token ('A'-'Z') to index (0-25)
    add     A, A                ; Multiply index by 2 (2 bytes per variable)
    ld      E, A                ; Store the offset in E
    ld      D, 0                ; Clear D, so DE = offset
    ld      HL, MEM_VARS        ; Load the base address of the variables array
    add     HL, DE              ; Add offset to base address (HL = pointer to variable)
    ld      A, (HL)             ; Load the low byte of the variable's value
    inc     HL                  ; Move to the high byte
    ld      H, (HL)             ; Load the high byte into H
    ld      L, A                ; Load the low byte into L
    ret                         ; Return with value in HL

; -----------------------------------------------------------------------
; VAR_SET - Write 16-bit variable value.
; Input:  A = variable token (0xD0-0xE9), HL = value
; Preserves: BC, DE
; -----------------------------------------------------------------------
VAR_SET:
    sub     0xD0                ; Subtract 0xD0 to get index (0-25)
    add     A, A                ; Multiply index by 2 (offset)
    ld      E, A                ; Store offset in E
    ld      D, 0                ; DE = offset
    push    HL                  ; Save the value we want to write
    ld      HL, MEM_VARS        ; Load the base address of the variables array
    add     HL, DE              ; Add offset (HL = pointer to variable)
    pop     DE                  ; Retrieve the value into DE
    ld      (HL), E             ; Store low byte
    inc     HL                  ; Move to high byte
    ld      (HL), D             ; Store high byte
    ret                         ; Return
