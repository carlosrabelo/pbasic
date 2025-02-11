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

; -----------------------------------------------------------------------
; MEM_OPEN_HOLE - Shift memory right to open a gap
; -----------------------------------------------------------------------
; Shifts all bytes from the insertion point to MEM_PROG_END right by
; the specified size, creating a hole for a new node.
;
; Input:  HL = insertion pointer (threshold)
;         BC = size in bytes to open
; Output: None
; Clobbers: A, D, E
; -----------------------------------------------------------------------
MEM_OPEN_HOLE:
	ld	(MEM_SCRATCH), hl	; save threshold
	ld	(MEM_SCRATCH_LEN), bc	; save size

	ld	de, (MEM_PROG_END)	; DE = end

	; Check if threshold == end (nothing to shift)
	ld	hl, (MEM_SCRATCH)
	ld	a, d
	cp	h
	jr	nz, MOH_COPY
	ld	a, e
	cp	l
	jr	z, MOH_AT_END

MOH_COPY:
	; DE = end, (MEM_SCRATCH) = threshold, (MEM_SCRATCH_LEN) = size

	; Count = end - threshold
	ld	hl, (MEM_SCRATCH)
	xor	a
	ex	de, hl			; HL = end, DE = threshold
	sbc	hl, de			; HL = end - threshold = count
	push	hl			; save count		[C]

	; dst = end + size - 1
	ld	hl, (MEM_PROG_END)	; HL = end
	ld	bc, (MEM_SCRATCH_LEN)	; BC = size
	push	hl			; save end		[E,C]
	add	hl, bc
	dec	hl			; HL = end + size - 1 = dst
	ex	de, hl			; DE = dst

	; src = end - 1
	pop	hl			; HL = end		[C]
	dec	hl			; HL = end - 1 = src

	; count
	pop	bc			; BC = count		[]

	; HL = src, DE = dst, BC = count
MOH_LOOP:
	ld	a, (hl)
	ld	(de), a
	dec	hl
	dec	de
	dec	bc
	ld	a, b
	or	c
	jr	nz, MOH_LOOP

MOH_AT_END:
	; Update MEM_PROG_END = end + size
	ld	hl, (MEM_PROG_END)
	ld	bc, (MEM_SCRATCH_LEN)
	add	hl, bc
	ld	(MEM_PROG_END), hl
	ret

; -----------------------------------------------------------------------
; MEM_CLOSE_HOLE - Shift memory left to close a gap
; -----------------------------------------------------------------------
; Shifts all bytes from (start + size) to MEM_PROG_END left by the
; specified size, closing a hole left by a deleted node.
;
; Input:  HL = start of deletion
;         BC = size in bytes to delete
; Output: None
; Clobbers: A, D, E
; -----------------------------------------------------------------------
MEM_CLOSE_HOLE:
	ld	(MEM_SCRATCH), hl	; save start
	ld	(MEM_SCRATCH_LEN), bc	; save size

	; source = start + size
	ld	hl, (MEM_SCRATCH)
	ld	bc, (MEM_SCRATCH_LEN)
	add	hl, bc			; HL = source
	ex	de, hl			; DE = source

	; Check if source >= end (nothing to shift)
	ld	hl, (MEM_PROG_END)	; HL = end
	ld	a, e
	cp	l
	ld	a, d
	sbc	a, h
	jr	nc, MCH_DONE		; source >= end → skip copy

	; DE = source, HL = end
	; Count = end - source
	xor	a
	ex	de, hl			; HL = end, DE = source
	sbc	hl, de			; HL = count
	push	hl			; save count		[C]

	; src = source (= DE after ex, which is source)
	push	de			; save src		[S,C]

	; dst = start
	ld	hl, (MEM_SCRATCH)
	ex	de, hl			; DE = dst

	; src
	pop	hl			; HL = src		[C]

	; count
	pop	bc			; BC = count		[]

	; HL = src, DE = dst, BC = count
MCH_LOOP:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	dec	bc
	ld	a, b
	or	c
	jr	nz, MCH_LOOP

MCH_DONE:
	; Update MEM_PROG_END = end - size
	ld	hl, (MEM_PROG_END)
	ld	bc, (MEM_SCRATCH_LEN)
	xor	a
	sbc	hl, bc
	ld	(MEM_PROG_END), hl
	ret
