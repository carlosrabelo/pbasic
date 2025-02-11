; memmgr.asm - Program memory management (Z80)
; -----------------------------------------------------------------------
;
; Node format (linked list):
;   [2 bytes: next_ptr (16-bit, 0x0000 = end of list)]
;   [2 bytes: line number (16-bit little-endian)]
;   [N bytes: tokens (null-terminated)]
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; PROG_INIT - Initialize program memory with sentinel
; -----------------------------------------------------------------------
; Writes a 16-bit zero sentinel to MEM_PROG_START and sets MEM_PROG_END
; to point past it, marking an empty linked list.
; -----------------------------------------------------------------------
PROG_INIT:
	ld	hl, MEM_PROG_START
	xor	a
	ld	(hl), a			; sentinel low byte = 0
	inc	hl
	ld	(hl), a			; sentinel high byte = 0
	inc	hl
	ld	(MEM_PROG_END), hl	; save end pointer
	ret

; -----------------------------------------------------------------------
; LINE_FIND - Find line in program linked list
; -----------------------------------------------------------------------
; Traverses the linked list to locate a line number. Returns the node
; pointer on exact match, or the insertion point if not found.
;
; Input:  BC = target line number (16-bit)
; Output: HL = pointer to matching node or insertion point
;         carry = 1 if exact match, 0 if not found
; Clobbers: A, D, E
; -----------------------------------------------------------------------
LINE_FIND:
	ld	hl, MEM_PROG_START

LF_LOOP:
	push	hl			; save current node pointer

	; Read next_ptr (2 bytes at HL) into DE
	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = next_ptr

	; Check for end of list
	ld	a, d
	or	e
	jr	z, LF_MISS_POP		; next_ptr == 0 → end of list

	; Read line number at (HL+1)
	inc	hl
	ld	a, (hl)			; line_num_low
	inc	hl
	ld	h, (hl)			; line_num_high
	ld	l, a			; HL = line number

	; Compare HL with BC (16-bit comparison)
	ld	a, h
	cp	b
	jr	nz, LF_CMP
	ld	a, l
	cp	c
	jr	z, LF_HIT_POP		; exact match

LF_CMP:
	; carry = 1 if HL < BC
	jr	c, LF_NEXT		; line_num < target → keep looking

	; line_num > target → insertion point is current node
	pop	hl			; restore saved node pointer
	or	a			; carry = 0 (not found)
	ret

LF_HIT_POP:
	pop	hl			; restore matching node pointer
	scf				; carry = 1 (found)
	ret

LF_MISS_POP:
	pop	hl			; restore node pointer (end of list)
	or	a			; carry = 0 (not found)
	ret

LF_NEXT:
	pop	af			; discard saved pointer
	ex	de, hl			; HL = next_ptr → advance to next node
	jr	LF_LOOP
