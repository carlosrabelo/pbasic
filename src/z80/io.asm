; io.asm - I/O base routines for PBasic (Z80)
; -----------------------------------------------------------------------
; Handles all interaction with the hardware environment, specifically the
; Teletype (TTY) interface for character input/output.
; -----------------------------------------------------------------------

    include 'defs.inc'

; -----------------------------------------------------------------------
; INCHAR - Read one character from TTY (blocking)
; Returns: A = character
; Preserves: F, BC, DE, HL
; Note: Use IN A,(C) with BC = port; IN A,(n) forms a 16-bit port from A and n.
; -----------------------------------------------------------------------
INCHAR:
    push    BC
    ld      BC, TTY_STATUS_PORT ; BC = $0001 (status register)
INCHAR_WAIT:
    in      A, (C)              ; Read TTY status register
    rrca                        ; Bit 0 (RX ready) into Carry flag
    jr      nc, INCHAR_WAIT     ; If not ready, keep polling
    ld      BC, TTY_DATA_PORT   ; BC = $0000 (data register)
    in      A, (C)              ; Read the received byte from DATA port
    pop     BC
    ret                         ; Return to caller

; -----------------------------------------------------------------------
; CHECK_BREAK - Check if a break key (Ctrl+C, ESC, q, Q) is pressed (non-blocking)
; Returns: A = 1 if break requested, 0 otherwise
; Preserves: BC, DE, HL
; Clobbers: AF
; -----------------------------------------------------------------------
CHECK_BREAK:
    push    BC
    ld      BC, TTY_STATUS_PORT ; BC = $0001 (status register)
    in      A, (C)              ; Read TTY status register
    rrca                        ; Bit 0 (RX ready) into Carry flag
    jr      nc, CB_NONE         ; If no data ready, return 0 (no break)

    ld      BC, TTY_DATA_PORT   ; BC = $0000 (data register)
    in      A, (C)              ; Read the received byte from DATA port

    cp      3                   ; Is it Ctrl+C (ASCII 3)?
    jr      z, CB_YES           ; If so, trigger execution abort
    cp      27                  ; Is it Escape (ASCII 27)?
    jr      z, CB_YES           ; If so, trigger execution abort
    cp      'q'                 ; Is it lowercase 'q'?
    jr      z, CB_YES           ; If so, trigger execution abort
    cp      'Q'                 ; Is it uppercase 'Q'?
    jr      z, CB_YES           ; If so, trigger execution abort

CB_NONE:
    xor     A                   ; A = 0 (no break requested)
    pop     BC
    ret                         ; Return

CB_YES:
    ld      A, 1                ; A = 1 (break requested)
    pop     BC
    ret                         ; Return

; -----------------------------------------------------------------------
; OUTCHAR - Write one character to TTY
; Input: A = character
; Preserves: AF, BC, DE, HL
; Note: Use OUT (C),A with BC = port; OUT (n),A forms a 16-bit port from A and n.
; -----------------------------------------------------------------------
OUTCHAR:
    push    BC
    ld      BC, TTY_DATA_PORT   ; BC = $0000 (data register)
    out     (C), A              ; Output the byte in register A to the TTY DATA port
    pop     BC
    ret                         ; Return to caller

; -----------------------------------------------------------------------
; PRINT_CRLF - Print CR+LF
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
PRINT_CRLF:
    push    AF                  ; Save AF on the stack
    ld      A, 13               ; Load ASCII 13 (Carriage Return)
    call    OUTCHAR             ; Print it
    ld      A, 10               ; Load ASCII 10 (Line Feed)
    call    OUTCHAR             ; Print it
    pop     AF                  ; Restore AF
    ret                         ; Return to caller

; -----------------------------------------------------------------------
; PRINT_STR - Print null-terminated string
; Input: HL = pointer to string
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
PRINT_STR:
    push    AF                  ; Save AF
    push    HL                  ; Save string pointer
PRINT_STR_LOOP:
    ld      A, (HL)             ; Read character from string
    or      A                   ; Check if it is the null terminator (0)
    jr      z, PRINT_STR_DONE   ; If zero, we are done
    call    OUTCHAR             ; Otherwise, print the character
    inc     HL                  ; Advance pointer to next character
    jr      PRINT_STR_LOOP      ; Loop back
PRINT_STR_DONE:
    pop     HL                  ; Restore pointer
    pop     AF                  ; Restore AF
    ret                         ; Return

; -----------------------------------------------------------------------
; PRINT_NUMBER - Print 16-bit unsigned number in decimal
; Input: HL = number (0-65535)
; Preserves: AF, BC, DE, HL
; -----------------------------------------------------------------------
PRINT_NUMBER:
    push    AF                  ; Save all working registers
    push    BC
    push    DE
    push    HL

    ld      A, H                ; Check if HL is exactly 0
    or      L
    jr      nz, PNUM_NOTZERO    ; If not zero, proceed with division
    ld      A, '0'              ; If zero, just print '0'
    call    OUTCHAR
    jr      PNUM_DONE

PNUM_NOTZERO:
    ld      B, 0                ; B will count the number of digits pushed to stack

PNUM_LOOP:
    ld      A, H                ; Check if HL has become 0 after divisions
    or      L
    jr      z, PNUM_PRINT       ; If zero, we have extracted all digits
    call    DIV10               ; Divide HL by 10 (HL = quotient, A = remainder)
    push    AF                  ; Push the remainder (digit) onto the stack
    inc     B                   ; Increment digit counter
    jr      PNUM_LOOP           ; Repeat until quotient is 0

PNUM_PRINT:
    pop     AF                  ; Pop a digit from the stack
    add     A, '0'              ; Convert integer 0-9 to ASCII '0'-'9'
    call    OUTCHAR             ; Print the character
    dec     B
    jr      nz, PNUM_PRINT      ; Decrement B, loop if not zero (print all digits)

PNUM_DONE:
    pop     HL                  ; Restore all working registers
    pop     DE
    pop     BC
    pop     AF
    ret                         ; Return

; -----------------------------------------------------------------------
; DIV10 - Divide HL by 10 (unsigned, 16-bit subtraction-based)
; Input: HL = dividend
; Output: HL = quotient, A = remainder
; Preserves: BC, DE
; -----------------------------------------------------------------------
DIV10:
    push    BC                  ; Save BC
    push    DE                  ; Save DE
    
    ld      BC, 0               ; Initialize quotient to 0 in BC
    ld      DE, -10             ; DE = -10 for subtraction

DIV10_LOOP:
    ld      A, H                ; Check if high byte is zero
    or      A
    jr      nz, DIV10_SUB       ; If H != 0, HL is >= 256, so definitely >= 10
    ld      A, L                ; Check low byte
    cp      10                  ; Is L < 10?
    jr      c, DIV10_DONE       ; If so, division is done

DIV10_SUB:
    add     HL, DE              ; HL = HL - 10
    inc     BC                  ; Increment quotient
    jr      DIV10_LOOP          ; Repeat subtraction

DIV10_DONE:
    ld      A, L                ; Remainder in A
    ld      H, B                ; Move quotient (BC) to HL
    ld      L, C
    
    pop     DE                  ; Restore DE
    pop     BC                  ; Restore BC
    ret                         ; Return

; -----------------------------------------------------------------------
; READ_LINE - Read a line into input buffer
; Handles backspace (8, 127), CR (13), LF (10)
; Output: HL = pointer to null-terminated string in input buffer
; Preserves: AF, BC, DE
; -----------------------------------------------------------------------
READ_LINE:
    push    AF                  ; Save AF
    push    BC                  ; Save BC

    ld      HL, MEM_INPUT_BUF   ; Point HL to the start of the input buffer
    ld      C, 0                ; C tracks the current length of the input

RLINE_LOOP:
    call    INCHAR              ; Read a character from the TTY (blocks in INCHAR loop)

    cp      13                  ; Is it Carriage Return?
    jr      z, RLINE_DONE       ; If yes, finish reading
    cp      10                  ; Is it Line Feed?
    jr      z, RLINE_DONE       ; If yes, finish reading
    cp      127                 ; Is it Backspace (Delete)?
    jr      z, RLINE_BS         ; Handle backspace
    cp      8                   ; Is it Backspace (CTRL-H)?
    jr      z, RLINE_BS         ; Handle backspace

    push    AF                  ; Save the read character
    ld      A, C                ; Check if buffer is full
    cp      INPUT_BUF_LEN - 1   ; Leave room for null terminator
    pop     AF                  ; Restore the character
    jr      z, RLINE_LOOP       ; If full, ignore character and wait for CR/BS

    ld      (HL), A             ; Store the character in the buffer
    call    OUTCHAR             ; Echo the character back to the screen (manual echo)
    inc     HL                  ; Advance the buffer pointer
    inc     C                   ; Increment the length counter
    jr      RLINE_LOOP          ; Loop back for next character

RLINE_BS:
    ld      A, C                ; Check current length
    or      A                   ; Is it 0?
    jr      z, RLINE_LOOP       ; If 0, ignore backspace (can't go back further)

    ; Visual backspace echo to erase character on the terminal
    ld      A, 8                ; Move cursor left
    call    OUTCHAR
    ld      A, ' '              ; Overwrite with space
    call    OUTCHAR
    ld      A, 8                ; Move cursor left again
    call    OUTCHAR

    dec     HL                  ; Move pointer back one position
    dec     C                   ; Decrement length counter
    jr      RLINE_LOOP          ; Loop back

RLINE_DONE:
    call    PRINT_CRLF          ; Print newline to visually advance the terminal
    ld      (HL), 0             ; Null-terminate the string
    ld      HL, MEM_INPUT_BUF   ; Return pointer to the start of the buffer

    pop     BC                  ; Restore registers
    pop     AF
    ret                         ; Return
