; expr.asm - Expression evaluator for PBasic (Z80)
; -----------------------------------------------------------------------
; Recursive descent parser with standard precedence:
;   expr   = term (('+' | '-') term)*
;   term   = factor (('*' | '/') factor)*
;   factor = number | variable | '(' expr ')' | '-' factor
;
; Uses MEM_TOKEN_PTR as the token stream position.
; All arithmetic is 16-bit signed/unsigned (depending on context).
; -----------------------------------------------------------------------



; -----------------------------------------------------------------------
; EVAL_EXPR - Evaluate an expression.
; Parses addition and subtraction.
; Output: HL = value, MEM_TOKEN_PTR advanced.
; Clobbers: AF, BC, DE
; -----------------------------------------------------------------------
EVAL_EXPR:
    call    EVAL_TERM           ; Parse the first term
EE_LOOP:
    push    HL                  ; Save the current accumulated value
    ld      HL, (MEM_TOKEN_PTR) ; Look at the next token
    ld      A, (HL)
    pop     HL                  ; Restore accumulated value
    cp      '+'                 ; Is it addition?
    jr      z, EE_ADD
    cp      '-'                 ; Is it subtraction?
    jr      z, EE_SUB
    ret                         ; If neither, expression is complete
EE_ADD:
    push    HL                  ; Save left operand
    ld      HL, (MEM_TOKEN_PTR) ; Advance token pointer past '+'
    inc     HL
    ld      (MEM_TOKEN_PTR), HL
    pop     HL                  ; Restore left operand
    push    HL                  ; Save left operand again (to stack for call)
    call    EVAL_TERM           ; Evaluate the right operand term
    pop     DE                  ; Retrieve left operand into DE
    add     HL, DE              ; Add (HL = right + left)
    jr      EE_LOOP             ; Loop for more + or -
EE_SUB:
    push    HL                  ; Save left operand
    ld      HL, (MEM_TOKEN_PTR) ; Advance token pointer past '-'
    inc     HL
    ld      (MEM_TOKEN_PTR), HL
    pop     HL                  ; Restore left operand
    push    HL                  ; Save left operand again
    call    EVAL_TERM           ; Evaluate right operand term
    ex      DE, HL              ; DE = right operand
    pop     HL                  ; HL = left operand
    xor     A                   ; Clear carry
    sbc     HL, DE              ; Subtract (HL = left - right)
    jr      EE_LOOP             ; Loop for more + or -

; -----------------------------------------------------------------------
; EVAL_TERM - Evaluate a term (handles * and /).
; -----------------------------------------------------------------------
EVAL_TERM:
    call    EVAL_FACTOR         ; Parse the first factor
ET_LOOP:
    push    HL                  ; Save current accumulated value
    ld      HL, (MEM_TOKEN_PTR) ; Look at next token
    ld      A, (HL)
    pop     HL                  ; Restore value
    cp      '*'                 ; Is it multiplication?
    jr      z, ET_MUL
    cp      '/'                 ; Is it division?
    jr      z, ET_DIV
    ret                         ; If neither, term is complete
ET_MUL:
    push    HL                  ; Save left operand
    ld      HL, (MEM_TOKEN_PTR) ; Advance token pointer past '*'
    inc     HL
    ld      (MEM_TOKEN_PTR), HL
    pop     HL                  ; Restore left operand
    push    HL                  ; Save left operand to stack
    call    EVAL_FACTOR         ; Evaluate right operand factor
    ex      (SP), HL            ; Swap HL with top of stack (HL = left, Stack = right)
    pop     DE                  ; DE = right operand
    call    MUL16               ; Multiply (HL = left * right)
    jr      ET_LOOP             ; Loop for more * or /
ET_DIV:
    push    HL                  ; Save left operand
    ld      HL, (MEM_TOKEN_PTR) ; Advance token pointer past '/'
    inc     HL
    ld      (MEM_TOKEN_PTR), HL
    pop     HL                  ; Restore left operand
    push    HL                  ; Save left operand to stack
    call    EVAL_FACTOR         ; Evaluate right operand factor
    ex      (SP), HL            ; Swap HL with top of stack (HL = left, Stack = right)
    pop     DE                  ; DE = right operand
    call    DIV16               ; Divide (HL = left / right)
    jr      ET_LOOP             ; Loop for more * or /

; -----------------------------------------------------------------------
; EVAL_FACTOR - Evaluate a factor (number, variable, parens, unary -).
; -----------------------------------------------------------------------
EVAL_FACTOR:
    ld      HL, (MEM_TOKEN_PTR) ; Look at current token
    ld      A, (HL)

    cp      0xC0                ; Is it a number literal token?
    jr      nz, EF_NOT_NUM
    ; Number literal: 0xC0 lo hi
    inc     HL                  ; Skip 0xC0
    ld      E, (HL)             ; Load low byte
    inc     HL
    ld      D, (HL)             ; Load high byte
    inc     HL                  ; Advance past high byte
    ld      (MEM_TOKEN_PTR), HL ; Update token pointer
    ex      DE, HL              ; Move value to HL
    ret                         ; Return value

EF_NOT_NUM:
    cp      0xA0                ; Is it FREE function?
    jr      nz, EF_NOT_FREE
    inc     HL                  ; Skip FREE token
    ld      (MEM_TOKEN_PTR), HL ; Update pointer
    ld      DE, (MEM_PROG_END)  ; Calculate free memory (0xF000 - MEM_PROG_END)
    ld      HL, 0xF000
    xor     A
    sbc     HL, DE
    ret                         ; Return result in HL

EF_NOT_FREE:
    cp      0xA1                ; Is it RND function?
    jr      nz, EF_NOT_RND
    inc     HL                  ; Skip RND token
    ld      (MEM_TOKEN_PTR), HL
    call    EVAL_FACTOR         ; Evaluate argument
    ld      A, H                ; Check if argument is 0
    or      L
    jr      z, EF_RND_ZERO
    push    HL                  ; Save argument (X)
    call    RAND16              ; HL = random number
    pop     DE                  ; DE = X
    call    MOD16               ; HL = HL % X
    inc     HL                  ; HL = (HL % X) + 1
    ret
EF_RND_ZERO:
    call    RAND16              ; Just return raw random number
    ret

EF_NOT_RND:
    cp      0xA2                ; Is it ABS function?
    jr      nz, EF_NOT_ABS
    inc     HL                  ; Skip ABS token
    ld      (MEM_TOKEN_PTR), HL
    call    EVAL_FACTOR         ; Evaluate argument
    bit     7, H                ; Is it negative (bit 15 set)?
    ret     z                   ; If positive, return as is
    ; Two's complement negation
    ld      A, H
    cpl                         ; NOT H
    ld      H, A
    ld      A, L
    cpl                         ; NOT L
    ld      L, A
    inc     HL                  ; Add 1
    ret

EF_NOT_ABS:
    cp      0xD0                ; Is it a variable token (0xD0-0xE9)?
    jr      c, EF_NOT_VAR
    cp      0xEA
    jr      nc, EF_NOT_VAR
    ; Variable: call VAR_GET(A), advance 1
    push    HL                  ; Save token pointer
    call    VAR_GET             ; Get variable value into HL
    ex      (SP), HL            ; Swap value with token pointer on stack
    inc     HL                  ; Advance token pointer past variable
    ld      (MEM_TOKEN_PTR), HL ; Update pointer
    pop     HL                  ; Restore value into HL
    ret                         ; Return

EF_NOT_VAR:
    cp      '('                 ; Is it an opening parenthesis?
    jr      nz, EF_NOT_PAREN
    ; '(' expr ')'
    inc     HL                  ; Skip '('
    ld      (MEM_TOKEN_PTR), HL ; Update pointer
    call    EVAL_EXPR           ; Evaluate inner expression recursively
    push    HL                  ; Save result
    ld      HL, (MEM_TOKEN_PTR) ; Check next token (should be ')')
    inc     HL                  ; Advance past ')' (we assume it's there, no error checking yet)
    ld      (MEM_TOKEN_PTR), HL ; Update pointer
    pop     HL                  ; Restore result
    ret                         ; Return

EF_NOT_PAREN:
    cp      '-'                 ; Is it a unary minus?
    jr      nz, EF_ERR          ; If not, syntax error in expression
    ; Unary minus
    inc     HL                  ; Skip '-'
    ld      (MEM_TOKEN_PTR), HL ; Update pointer
    call    EVAL_FACTOR         ; Evaluate the factor being negated
    ld      A, H                ; Negate HL (Two's complement: NOT HL + 1)
    cpl                         ; NOT H
    ld      H, A
    ld      A, L
    cpl                         ; NOT L
    ld      L, A
    inc     HL                  ; Add 1
    ret                         ; Return negated value

EF_ERR:
    ld      HL, 0               ; Default to 0 on error
    ret

; -----------------------------------------------------------------------
; EVAL_COND - Evaluate a condition: expr relop expr
; Relops: =  <>  <  >  <=  >=
; Tokens: = (0x3D)  <> (0xB0)  < (0x3C)  > (0x3E)  <= (0xB1)  >= (0xB2)
; Output: HL = 1 if true, 0 if false. MEM_TOKEN_PTR advanced.
; Clobbers: AF, BC, DE
; -----------------------------------------------------------------------
EVAL_COND:
    call    EVAL_EXPR           ; Evaluate left side expression
    push    HL                  ; Save left side result
    ld      HL, (MEM_TOKEN_PTR) ; Look at relational operator token
    ld      A, (HL)
    ld      (MEM_SCRATCH), A    ; Save operator token
    inc     HL                  ; Advance past operator
    ld      (MEM_TOKEN_PTR), HL
    call    EVAL_EXPR           ; Evaluate right side expression
    ex      (SP), HL            ; Swap right side with left side (HL = left, Stack = right)
    pop     DE                  ; DE = right side
    ld      A, H                ; Bias both values for signed comparison
    xor     0x80                ; Flip sign bit: map signed to unsigned order
    ld      H, A
    ld      A, D
    xor     0x80
    ld      D, A
    or      A                   ; Clear carry
    sbc     HL, DE              ; Compare (bias preserves ordering)
    push    AF                  ; Save Flags from comparison (Z, C, etc.)
    ld      A, (MEM_SCRATCH)    ; Retrieve operator token
    cp      '='
    jr      z, EC_EQ
    cp      0xB0
    jr      z, EC_NE
    cp      '<'
    jr      z, EC_LT
    cp      '>'
    jr      z, EC_GT
    cp      0xB1
    jr      z, EC_LE
    cp      0xB2
    jr      z, EC_GE
    pop     AF                  ; Clean up stack on invalid operator
    ld      HL, 0               ; Default to false
    ret

EC_EQ:
    pop     AF                  ; Restore flags
    jr      nz, EC_FALSE        ; If NZ (not zero), Left != Right, false
    jr      EC_TRUE             ; Otherwise true

EC_NE:
    pop     AF                  ; Restore flags
    jr      z, EC_FALSE         ; If Z (zero), Left == Right, false
    jr      EC_TRUE             ; Otherwise true

EC_LT:
    pop     AF                  ; Restore flags
    jr      nc, EC_FALSE        ; If NC (no borrow), Left >= Right, false
    jr      EC_TRUE             ; Otherwise true

EC_GT:
    pop     AF                  ; Restore flags
    jr      z, EC_FALSE         ; If Z (zero), Left == Right, false
    jr      c, EC_FALSE         ; If C (borrow), Left < Right, false
    jr      EC_TRUE             ; Otherwise true

EC_LE:
    pop     AF                  ; Restore flags
    jr      z, EC_TRUE          ; If Z (zero), Left == Right, true
    jr      c, EC_TRUE          ; If C (borrow), Left < Right, true
    jr      EC_FALSE            ; Otherwise false

EC_GE:
    pop     AF                  ; Restore flags
    jr      z, EC_TRUE          ; If Z (zero), Left == Right, true
    jr      nc, EC_TRUE         ; If NC (no borrow), Left > Right, true
    jr      EC_FALSE            ; Otherwise false

EC_TRUE:
    ld      HL, 1               ; Return 1 (true)
    ret

EC_FALSE:
    ld      HL, 0               ; Return 0 (false)
    ret
