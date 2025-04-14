; cmd_list.asm - LIST command handler for PBasic (Z80)
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; DO_LIST - Prints the entire tokenized program to the screen
; Input: None
; Output: None
; Clobbers: None (delegates to LINE_LIST)
; -----------------------------------------------------------------------
DO_LIST:
    call    LINE_LIST           ; Call the sub-routine to traverse the linked list and print lines
    jp      REPL_LOOP           ; Return to the interactive prompt
