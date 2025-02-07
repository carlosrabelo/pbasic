; util.asm - Utility routines for PBasic Z80
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; MATCH_KEYWORD - Check if input at HL matches keyword at DE
; -----------------------------------------------------------------------
; Input:  HL = input pointer, DE = keyword string (null-terminated)
; Output: carry=1 if match (HL = advanced past keyword)
;         carry=0 if no match (HL preserved)
; Clobbers: A, DE
; -----------------------------------------------------------------------
MATCH_KEYWORD:
	push	hl

MK_LOOP:
	ld	a, (de)			; keyword char
	or	a
	jr	z, MK_BOUNDARY		; end of keyword

	cp	(hl)			; compare with input
	jr	nz, MK_FAIL

	inc	hl
	inc	de
	jr	MK_LOOP

MK_BOUNDARY:
	ld	a, (hl)			; char following keyword in input
	or	a
	jr	z, MK_SUCCESS		; end of string is valid boundary

	cp	'A'
	jr	c, MK_SUCCESS		; < 'A' is boundary (space, punct)
	cp	'Z' + 1
	jr	nc, MK_SUCCESS		; > 'Z' is boundary
	; 'A'-'Z' means partial match (e.g., PRINTER vs PRINT)

MK_FAIL:
	pop	hl			; restore original HL
	or	a			; carry = 0
	ret

MK_SUCCESS:
	pop	af			; discard saved HL
	scf				; carry = 1
	ret

; -----------------------------------------------------------------------
; PARSE_NUMBER - Parse decimal number at HL
; -----------------------------------------------------------------------
; Input:  HL = input pointer (must point to a digit)
; Output: DE = 16-bit parsed value, HL = advanced pointer
;         carry=0 on success, carry=1 if no digit found (HL unchanged)
; Clobbers: A, B, C
; -----------------------------------------------------------------------
PARSE_NUMBER:
	ld	de, 0
	ld	a, (hl)
	sub	'0'
	jr	c, PN_FAIL
	cp	10
	jr	nc, PN_FAIL

	ld	e, a			; first digit

PN_LOOP:
	inc	hl
	ld	a, (hl)
	sub	'0'
	jr	c, PN_DONE
	cp	10
	jr	nc, PN_DONE

	; DE = DE * 10 + digit
	push	hl
	push	de
	pop	hl
	add	hl, hl			; *2
	push	hl
	add	hl, hl			; *4
	add	hl, hl			; *8
	pop	bc
	add	hl, bc			; *10
	ld	c, a
	ld	b, 0
	add	hl, bc
	push	hl
	pop	de
	pop	hl
	jr	PN_LOOP

PN_DONE:
	or	a			; carry = 0 (success)
	ret

PN_FAIL:
	scf				; carry = 1
	ret
