; commands.asm - PBasic (Z80) command handler index
; Each file implements the routine corresponding to a command keyword,
; expecting HL to point immediately after the keyword token.
; All routines must return by jumping to REPL_LOOP or REPL_DISPATCH.

; -----------------------------------------------------------------------
; CMD_JUMP_TABLE - O(1) Lookup table for command execution
; Maps tokens 0x80-0x8C to their respective DO_* routines
; -----------------------------------------------------------------------

CMD_JUMP_TABLE:
    dw      DO_LET              ; 0x80: LET
    dw      DO_GOTO             ; 0x81: GOTO
    dw      DO_GOSUB            ; 0x82: GOSUB
    dw      DO_PRINT            ; 0x83: PRINT
    dw      DO_IF               ; 0x84: IF
    dw      DO_INPUT            ; 0x85: INPUT
    dw      DO_RETURN           ; 0x86: RETURN
    dw      DO_END              ; 0x87: END
    dw      DO_LIST             ; 0x88: LIST
    dw      DO_RUN              ; 0x89: RUN
    dw      DO_NEW              ; 0x8A: NEW
    dw      DO_EXIT             ; 0x8B: EXIT
    dw      DO_REM              ; 0x8C: REM
