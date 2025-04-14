; lines.asm - Line storage for PBasic (Z80)
; -----------------------------------------------------------------------
; Handles the linked list of tokenized BASIC lines in the program memory area.
;
; Node layout:
;   [2 bytes: next ptr LE, 0x0000 = end-of-list]
;   [2 bytes: line number LE]
;   [N bytes: tokens]
;   [0x00: terminator]
;
; Empty program: sentinel at MEM_PROG_START with next=0x0000.
; MEM_PROG_END = one byte past the last written byte.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; PROG_INIT - Erase all BASIC lines.
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
PROG_INIT:
    push    AF                  ; Save AF
    push    HL                  ; Save HL

    ld      HL, MEM_PROG_START  ; Point to start of program memory
    ld      (HL), 0x00          ; Write low byte of sentinel (0x00)
    inc     HL
    ld      (HL), 0x00          ; Write high byte of sentinel (0x00)

    ld      HL, MEM_PROG_START + 2 ; HL = memory just after the sentinel
    ld      (MEM_PROG_END), HL  ; Update end-of-program pointer

    pop     HL                  ; Restore HL
    pop     AF                  ; Restore AF
    ret                         ; Return

; -----------------------------------------------------------------------
; NODE_LEN - Byte length of node at HL (4 header bytes + body + 0x00).
; Output: BC = length
; Preserves: AF, DE, HL
; -----------------------------------------------------------------------
NODE_LEN:
    push    AF                  ; Save AF
    push    HL                  ; Save HL pointer to start of node

    inc     HL                  ; Skip next-ptr low byte
    inc     HL                  ; Skip next-ptr high byte
    inc     HL                  ; Skip line-number low byte
    inc     HL                  ; Skip line-number high byte
                                ; HL now points to the first token

    call    TOKEN_LEN           ; Calculate length of tokens up to 0x00 (returns in BC)
    push    HL                  ; Save token pointer
    ld      H, B                ; Move token length (BC) to HL
    ld      L, C
    ld      BC, 4               ; BC = 4 (header bytes)
    add     HL, BC              ; HL = token length + header length
    ld      B, H                ; Move total length back to BC
    ld      C, L
    pop     HL                  ; Restore token pointer

    pop     HL                  ; Restore original node pointer
    pop     AF                  ; Restore AF
    ret                         ; Return length in BC

; -----------------------------------------------------------------------
; TOKEN_LEN - Byte length of token stream including 0x00 terminator.
; Understands multi-byte tokens (0xC0 + 2B number, 0xC1 ... 0xC1 string).
; Input: HL = token stream start
; Output: BC = length (including final 0x00)
; Preserves: AF, DE, HL
; -----------------------------------------------------------------------
TOKEN_LEN:
    push    AF                  ; Save AF
    push    HL                  ; Save HL

    ld      BC, 0               ; Initialize length counter

TLN_LOOP:
    ld      A, (HL)             ; Read current token
    inc     HL                  ; Advance pointer
    inc     BC                  ; Increment length counter
    or      A                   ; Is it 0x00 (end of line)?
    jr      z, TLN_DONE         ; If so, we are done
    cp      0xC0                ; Is it a number literal token?
    jr      z, TLN_NUM          ; If so, handle number
    cp      0xC1                ; Is it a string literal token?
    jr      z, TLN_STR          ; If so, handle string
    jr      TLN_LOOP            ; Otherwise, loop for next standard token

TLN_NUM:
    inc     HL                  ; Skip low byte of number
    inc     BC                  ; Count it
    inc     HL                  ; Skip high byte of number
    inc     BC                  ; Count it
    jr      TLN_LOOP            ; Continue parsing

TLN_STR:
    ld      A, (HL)             ; Read character inside string
    inc     HL                  ; Advance pointer
    inc     BC                  ; Count it
    cp      0xC1                ; Is it the closing string marker?
    jr      nz, TLN_STR         ; If not, continue parsing string
    jr      TLN_LOOP            ; Once closed, continue parsing normal tokens

TLN_DONE:
    pop     HL                  ; Restore original pointer
    pop     AF                  ; Restore AF
    ret                         ; Return length in BC

; -----------------------------------------------------------------------
; LINE_FIND - Find line with number BC.
; Output: Z  + HL = ptr to node  (exact match)
;         NZ + HL = insertion point (first node > BC, or sentinel)
; Preserves: BC, DE.  AF returns status (Z/NZ).
; -----------------------------------------------------------------------
LINE_FIND:
    push    DE                  ; Save DE

    ; --- Forward Caching Optimization ---
    ld      A, (MEM_RUN_FLAG)   ; Is a program currently running?
    or      A
    jr      z, LF_START_BEGIN   ; If not, always start from the beginning

    ; Program is running, MEM_LINE_PTR points to the current executing line
    ld      HL, (MEM_LINE_PTR)  ; Get current line pointer
    inc     HL                  ; Skip next-ptr low
    inc     HL                  ; Skip next-ptr high
    ld      E, (HL)             ; Load current line number low
    inc     HL
    ld      D, (HL)             ; Load current line number high

    ; Compare target line (BC) with current line (DE)
    ld      A, C                ; Low byte compare
    sub     E
    ld      A, B                ; High byte compare with borrow
    sbc     A, D
    jr      c, LF_START_BEGIN   ; If target (BC) < current (DE), search from beginning

    ; Target >= current, start searching from the current line
    ld      HL, (MEM_LINE_PTR)
    jr      LF_LOOP

LF_START_BEGIN:
    ld      HL, MEM_PROG_START  ; Start at the beginning of program memory

LF_LOOP:
    ld      E, (HL)             ; Load low byte of next-ptr
    inc     HL
    ld      D, (HL)             ; Load high byte of next-ptr
    dec     HL                  ; Reset HL back to start of current node

    ld      A, D                ; Check if next-ptr is 0x0000
    or      E
    jr      z, LF_MISS          ; If so, end of list reached (miss)

    push    HL                  ; Save current node pointer
    inc     HL                  ; Skip next-ptr (low)
    inc     HL                  ; Skip next-ptr (high)
    ld      A, (HL)             ; Read line-number (low)
    inc     HL
    ld      H, (HL)             ; Read line-number (high)
    ld      L, A                ; HL now holds the line number of current node

    xor     A                   ; Clear carry flag
    sbc     HL, BC              ; Compare current line number (HL) with target (BC)
    pop     HL                  ; Restore current node pointer

    jr      z, LF_HIT           ; If result is 0 (Z flag), exact match found
    jr      c, LF_ADV           ; If result < 0 (current < target), advance to next node

    or      0xFF                ; If result > 0 (current > target), insertion point found! Clear Z flag.
    pop     DE                  ; Restore DE
    ret                         ; Return (NZ)

LF_HIT:
    xor     A                   ; Set Z flag to indicate exact match
    pop     DE                  ; Restore DE
    ret                         ; Return (Z)

LF_ADV:
    ld      H, D                ; HL = next node pointer (DE)
    ld      L, E
    jr      LF_LOOP             ; Loop to evaluate next node

LF_MISS:
    or      0xFF                ; Clear Z flag (NZ) to indicate miss
    pop     DE                  ; Restore DE
    ret                         ; Return (NZ)

; -----------------------------------------------------------------------
; LINE_STORE - Store/replace/delete a BASIC line from MEM_TOKEN_BUF.
; MEM_TOKEN_BUF format: 0xC0, lo, hi, [body...], 0x00
; Empty body -> delete line (if exists).
; Preserves: BC, DE, HL
; -----------------------------------------------------------------------
LINE_STORE:
    push    AF                  ; Save registers
    push    BC
    push    DE
    push    HL

    ld      HL, MEM_TOKEN_BUF   ; Point to tokenized line buffer
    inc     HL                  ; Skip 0xC0 marker
    ld      C, (HL)             ; Read line number low byte
    inc     HL
    ld      B, (HL)             ; Read line number high byte (BC = line number)
    inc     HL

    ld      A, (HL)             ; Check first byte of the line body
    or      A                   ; Is it 0x00 (empty line)?
    jp      z, LS_DELETE        ; If empty, jump to deletion routine

    ld      (MEM_SCRATCH), HL   ; Save pointer to start of token body

    call    LINE_FIND           ; Search for the line number in BC
    jr      nz, LS_INSERT       ; If NZ (not found), jump to insertion logic (HL points to insertion point)

    ; Line exists, so we must replace it (delete old, insert new)
    push    BC                  ; Save target line number
    push    HL                  ; Save node pointer
    call    NODE_LEN            ; Calculate length of existing node (BC)
    ld      A, C                ; Load length
    or      A                   ; Check for 0 length
    jp      z, LS_ERR_OVER      ; Error if 0
    pop     HL                  ; Restore node pointer
    push    AF                  ; Save length
    push    HL                  ; Save node pointer
    call    MEM_CLOSE_HOLE      ; Remove the old node, shifting everything left
    pop     HL                  ; Restore pointer
    pop     AF                  ; Restore length

    call    FIX_NEXT_SUB        ; Subtract the removed length from all next-ptrs before this node

    pop     BC                  ; Restore target line number
    call    LINE_FIND           ; Re-find the insertion point since memory shifted

LS_INSERT:
    push    HL                  ; Save insertion point
    push    BC                  ; Save target line number
    ld      HL, (MEM_SCRATCH)   ; Point to token body
    call    TOKEN_LEN           ; Calculate body length
    ld      D, B                ; DE = body length
    ld      E, C
    pop     BC                  ; Restore target line number
    pop     HL                  ; Restore insertion point

    push    HL                  ; Save insertion point
    ld      H, D                ; HL = body length
    ld      L, E
    ld      DE, 4               ; DE = 4 (header length)
    add     HL, DE              ; HL = total new node length
    ld      A, L                ; Save total length (assuming < 256)
    pop     HL                  ; Restore insertion point

    ld      (MEM_SCRATCH + 2), A ; Save new node length to scratch

    push    BC                  ; Save line number
    push    HL                  ; Save insertion point
    call    MEM_OPEN_HOLE       ; Shift memory right to make room for new node
    pop     HL                  ; Restore insertion point
    pop     BC                  ; Restore line number

    push    AF                  ; Save status
    push    BC                  ; Save line number
    push    HL                  ; Save insertion point
    ld      C, A                ; BC = new node length
    ld      B, 0
    add     HL, BC              ; HL = node after the newly inserted one
    call    FIX_NEXT_ADD        ; Add new node length to all next-ptrs before this node
    pop     HL                  ; Restore insertion point
    pop     BC                  ; Restore line number
    pop     AF                  ; Restore status

    push    BC                  ; Save line number
    push    HL                  ; Save insertion point
    ld      B, 0                ; BC = new node length
    ld      C, A
    add     HL, BC              ; HL = next node's address
    ld      D, H                ; DE = next node's address
    ld      E, L
    pop     HL                  ; Restore insertion point

    ld      (HL), E             ; Write new node's next-ptr (low)
    inc     HL
    ld      (HL), D             ; Write new node's next-ptr (high)
    inc     HL

    pop     BC                  ; Restore line number
    ld      (HL), C             ; Write line number (low)
    inc     HL
    ld      (HL), B             ; Write line number (high)
    inc     HL

    ld      DE, (MEM_SCRATCH)   ; DE = pointer to token body
    ld      C, A                ; C = total node length
    ld      B, 0                ; BC = total node length
    dec     BC                  ; Subtract 4 bytes (header size)
    dec     BC
    dec     BC
    dec     BC
    ex      DE, HL              ; HL = token body, DE = destination in program memory
    ldir                        ; Copy token body

    jp      LS_DONE             ; Finished insertion

LS_DELETE:
    call    LINE_FIND           ; Search for the line number
    jr      nz, LS_DONE         ; If not found, nothing to delete

    push    BC                  ; Save line number
    push    HL                  ; Save pointer to node to delete
    call    NODE_LEN            ; Get its length
    ld      A, C                ; Store length
    pop     HL                  ; Restore node pointer
    call    MEM_CLOSE_HOLE      ; Remove it, shifting memory left
    call    FIX_NEXT_SUB        ; Update all previous next-ptrs
    pop     BC                  ; Restore line number

LS_DONE:
    pop     HL                  ; Restore all registers
    pop     DE
    pop     BC
    pop     AF
    ret                         ; Return

; -----------------------------------------------------------------------
; LINE_LIST - Print all BASIC lines.
; Format per line: "<linenum> <tokens-as-text>\r\n"
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
LINE_LIST:
    push    AF                  ; Save registers
    push    BC
    push    DE
    push    HL

    ld      HL, MEM_PROG_START  ; Start at beginning of program memory

LLI_LOOP:
    ld      E, (HL)             ; Load next-ptr low
    inc     HL
    ld      D, (HL)             ; Load next-ptr high
    inc     HL
    ld      A, D                ; Check if next-ptr is 0x0000
    or      E
    jr      z, LLI_DONE         ; If 0x0000, end of list

    ld      C, (HL)             ; Read line-number low
    inc     HL
    ld      B, (HL)             ; Read line-number high
    inc     HL                  ; HL now points to tokens

    push    HL                  ; Save token pointer
    push    DE                  ; Save next-ptr
    ld      H, B                ; Load line number to HL
    ld      L, C
    call    PRINT_NUMBER        ; Print the line number
    ld      A, ' '              ; Print a space separator
    call    OUTCHAR
    pop     DE                  ; Restore next-ptr
    pop     HL                  ; Restore token pointer

    call    PRINT_TOKENS        ; Print the tokens as human-readable text

    call    PRINT_CRLF          ; Print newline

    ld      H, D                ; Move to the next node using saved next-ptr
    ld      L, E
    jr      LLI_LOOP            ; Loop back

LLI_DONE:
    pop     HL                  ; Restore registers
    pop     DE
    pop     BC
    pop     AF
    ret                         ; Return

LS_ERR_OVER:
    pop     HL                  ; Restore HL
    pop     DE                  ; Restore DE
    pop     BC                  ; Restore BC
    pop     AF                  ; Restore AF
    jp      REPL_SYNTAX_ERROR   ; Jump to error handler
