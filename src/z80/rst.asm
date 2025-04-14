; rst.asm - RST vector table and system entry point (Z80)
; -----------------------------------------------------------------------
; Defines Z80 restart vectors from address 0x0000. Each RST slot is 8
; bytes. RST 0 jumps to the main START routine; all others are unused
; and simply return.
;
; Layout:
;   0x0000   RST 0 (C7)   → jp START
;   0x0008   RST 1 (CF)   → ret
;   0x0010   RST 2 (D7)   → ret
;   0x0018   RST 3 (DF)   → ret
;   0x0020   RST 4 (E7)   → ret
;   0x0028   RST 5 (EF)   → ret
;   0x0030   RST 6 (F7)   → ret
;   0x0038   RST 7 (FF)   → ret (also IM 1 interrupt)
;   0x0066   NMI          → retn
;   0x0068-0x00FF Padding
;   0x0100   Main code begins
; -----------------------------------------------------------------------

    org     0x0000              ; Set origin to 0x0000 (Z80 reset vector)

    jp      START               ; RST 0 — System reset, jump to main entry
    ds      0x0008 - $          ; Pad to RST 08H slot
    ret                         ; RST 08H
    ds      0x0010 - $
    ret                         ; RST 10H
    ds      0x0018 - $
    ret                         ; RST 18H
    ds      0x0020 - $
    ret                         ; RST 20H
    ds      0x0028 - $
    ret                         ; RST 28H
    ds      0x0030 - $
    ret                         ; RST 30H
    ds      0x0038 - $
    ret                         ; RST 38H — also IM 1 mode interrupt vector
    ds      0x0066 - $
    retn                        ; Non-Maskable Interrupt vector
    ds      0x0100 - $          ; Pad to 0x0100 for main code area
