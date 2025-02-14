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

; -----------------------------------------------------------------------
; FIX_NEXT_ADD - Add offset to next_ptrs past threshold
; -----------------------------------------------------------------------
; Walks the linked list and adds BC to every next_ptr whose value is
; strictly greater than HL. Must be called BEFORE MEM_OPEN_HOLE.
;
; Input:  HL = threshold pointer
;         BC = size to add
; Output: None
; Clobbers: A, D, E
; -----------------------------------------------------------------------
FIX_NEXT_ADD:
	ld	(MEM_SCRATCH), hl	; save threshold

FNA_LOOP:
	push	hl			; [N] save current node

	; Read next_ptr
	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = next_ptr

	; End of list?
	ld	a, d
	or	e
	jr	z, FNA_DONE_POP

	; Compare next_ptr (DE) with threshold
	ld	hl, (MEM_SCRATCH)
	ld	a, e
	sub	l
	ld	a, d
	sbc	a, h
	jr	c, FNA_FOLLOW		; DE < threshold → follow
	jr	z, FNA_FOLLOW		; DE == threshold → follow

	; --- DE > threshold → adjust ---
	; Save old next_ptr for following after adjustment
	ld	(MEM_SCRATCH_LEN), de

	ex	de, hl			; HL = old next_ptr, DE = threshold
	add	hl, bc			; HL = adjusted next_ptr
	ex	de, hl			; DE = adjusted next_ptr

	pop	hl			; HL = node address	[]
	; Write adjusted next_ptr
	ld	(hl), e
	inc	hl
	ld	(hl), d

	; Follow the OLD next_ptr
	ld	hl, (MEM_SCRATCH_LEN)
	jr	FNA_LOOP

FNA_FOLLOW:
	; DE = old next_ptr, [N] on stack
	pop	hl			; discard node address
	ex	de, hl			; HL = old next_ptr → advance
	jr	FNA_LOOP

FNA_DONE_POP:
	pop	hl			; clean stack
	ret

; -----------------------------------------------------------------------
; FIX_NEXT_SUB - Subtract offset from next_ptrs past threshold
; -----------------------------------------------------------------------
; Walks the linked list and subtracts BC from every next_ptr whose value
; is strictly greater than HL. Must be called BEFORE MEM_CLOSE_HOLE.
;
; Input:  HL = threshold pointer
;         BC = size to subtract
; Output: None
; Clobbers: A, D, E
; -----------------------------------------------------------------------
FIX_NEXT_SUB:
	ld	(MEM_SCRATCH), hl	; save threshold

FNS_LOOP:
	push	hl			; [N] save current node

	; Read next_ptr
	ld	e, (hl)
	inc	hl
	ld	d, (hl)			; DE = next_ptr

	; End of list?
	ld	a, d
	or	e
	jr	z, FNS_DONE_POP

	; Compare next_ptr (DE) with threshold
	ld	hl, (MEM_SCRATCH)
	ld	a, e
	sub	l
	ld	a, d
	sbc	a, h
	jr	c, FNS_FOLLOW		; DE < threshold → follow
	jr	z, FNS_FOLLOW		; DE == threshold → follow

	; --- DE > threshold → adjust ---
	ld	(MEM_SCRATCH_LEN), de	; save old next_ptr

	ex	de, hl			; HL = old next_ptr, DE = threshold
	xor	a
	sbc	hl, bc			; HL = next_ptr - size
	ex	de, hl			; DE = adjusted next_ptr

	pop	hl			; HL = node address	[]
	; Write adjusted next_ptr
	ld	(hl), e
	inc	hl
	ld	(hl), d

	; Follow the OLD next_ptr
	ld	hl, (MEM_SCRATCH_LEN)
	jr	FNS_LOOP

FNS_FOLLOW:
	; DE = old next_ptr, [N] on stack
	pop	hl			; discard node address
	ex	de, hl			; HL = old next_ptr → advance
	jr	FNS_LOOP

FNS_DONE_POP:
	pop	hl			; clean stack
	ret

; -----------------------------------------------------------------------
; TOKEN_LEN - Calculate token stream length
; -----------------------------------------------------------------------
; Scans a token stream and returns its total byte length, including the
; null terminator. Handles multi-byte tokens (TK_NUM skips 2 bytes,
; TK_STR skips until matching TK_STR).
;
; Input:  HL = pointer to first token byte
; Output: BC = length in bytes (including null terminator)
; Clobbers: A, D, E, HL advanced past stream
; -----------------------------------------------------------------------
TOKEN_LEN:
	ld	bc, 0			; counter

TLN_LOOP:
	ld	a, (hl)
	inc	hl
	inc	bc

	or	a
	ret	z			; null terminator → done

	cp	TK_NUM
	jr	z, TLN_NUM
	cp	TK_STR
	jr	z, TLN_STR

	jr	TLN_LOOP		; single-byte token

TLN_NUM:
	inc	bc			; count low byte
	inc	bc			; count high byte
	inc	hl			; skip low byte
	inc	hl			; skip high byte
	jr	TLN_LOOP

TLN_STR:
	ld	a, (hl)			; read char
	inc	hl
	inc	bc
	cp	TK_STR
	jr	nz, TLN_STR		; loop until closing TK_STR

	jr	TLN_LOOP

; -----------------------------------------------------------------------
; NODE_LEN - Calculate total node length
; -----------------------------------------------------------------------
; Returns the full byte size of a linked-list node including header
; (4 bytes: 2 for next_ptr + 2 for line number) and token stream.
;
; Input:  HL = pointer to start of node (next_ptr field)
; Output: BC = total node length in bytes
; Clobbers: A, D, E
; -----------------------------------------------------------------------
NODE_LEN:
	push	hl			; save node pointer	[N]

	; Advance past header to tokens
	inc	hl
	inc	hl			; skip next_ptr
	inc	hl
	inc	hl			; skip line number

	call	TOKEN_LEN		; BC = token length

	pop	hl			; restore node pointer

	ld	hl, 4
	add	hl, bc			; HL = 4 + token_len
	ld	b, h
	ld	c, l			; BC = total node length
	ret

; -----------------------------------------------------------------------
; LINE_STORE - Store, replace, or delete a BASIC line
; -----------------------------------------------------------------------
; Reads the tokenized line from MEM_TOKEN_BUF and inserts, replaces, or
; deletes the corresponding entry in the program linked list.
;
; MEM_TOKEN_BUF format: [0xC0] [line_lo] [line_hi] [tokens... 0x00]
;
; If the token body is empty (starts with 0x00), the line is deleted.
; Otherwise, the line is inserted (or replaces an existing line with the
; same number). Uses the stack for temporary storage of line number and
; body pointer across calls to subroutines.
;
; Input:  MEM_TOKEN_BUF (tokenized line)
; Output: None
; Clobbers: All
; -----------------------------------------------------------------------
LINE_STORE:
	; --- Read line number ---
	ld	hl, MEM_TOKEN_BUF + 1
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a			; HL = line number
	push	hl			; (A) line number

	; --- Check for delete ---
	ld	hl, MEM_TOKEN_BUF + 3
	ld	a, (hl)
	or	a
	jp	z, LS_DELETE

	; --- INSERT / REPLACE ---
	; BC = line number (from stack)
	pop	bc			; BC = line number	[]
	push	bc			; (A) line number

	call	LINE_FIND		; BC = line number, HL = pointer, carry = found

	push	hl			; (B) insertion point
	jr	c, LS_REPLACE

	; --- INSERT (line not found) ---
	; Stack: [ins_point, line_num]
	; Calculate node length: 4 + token_len
	ld	hl, MEM_TOKEN_BUF + 3
	call	TOKEN_LEN		; BC = token length
	ld	hl, 4
	add	hl, bc			; HL = node length
	ld	(MEM_SCRATCH_LEN), hl	; save node length

	; Fix next_ptrs first
	pop	hl			; HL = ins_point	[line_num]
	push	hl			; (B) ins_point
	ld	bc, (MEM_SCRATCH_LEN)
	call	FIX_NEXT_ADD		; HL=ins_point, BC=node_len

	; Open hole
	pop	hl			; HL = ins_point	[line_num]
	push	hl			; (B) ins_point
	ld	bc, (MEM_SCRATCH_LEN)
	call	MEM_OPEN_HOLE		; HL=ins_point, BC=node_len

	; Write node header at insertion point
	pop	hl			; HL = ins_point	[line_num]
	push	hl			; (B) ins_point

	; 1) next_ptr = ins_point + node_len
	push	hl			; save ins_point
	ld	bc, (MEM_SCRATCH_LEN)
	add	hl, bc			; HL = next_ptr value
	ex	de, hl			; DE = next_ptr
	pop	hl			; HL = ins_point

	ld	(hl), e
	inc	hl
	ld	(hl), d			; write next_ptr
	inc	hl			; HL = line number slot

	; 2) Line number
	pop	de			; DE = line number	[]
	ld	a, e
	ld	(hl), a
	inc	hl
	ld	a, d
	ld	(hl), a			; write line number
	inc	hl			; HL = token slot

	; 3) Copy tokens from MEM_TOKEN_BUF + 3
	pop	af			; clean stack (stale ins_point)
	ex	de, hl			; DE = dest
	ld	hl, MEM_TOKEN_BUF + 3	; HL = src

LS_COPY_TOK:
	ld	a, (hl)
	ld	(de), a
	or	a
	ret	z			; done after terminator

	inc	hl
	inc	de
	jr	LS_COPY_TOK

; -----------------------------------------------------------------------
LS_REPLACE:
	; Stack: [ins_point, line_num]
	; Delete old node, then insert new one (fall through to insert)

	; Calculate old node length
	pop	hl			; HL = ins_point (old node)
	push	hl			; (B) ins_point

	call	NODE_LEN		; BC = old node length

	; Save old node length
	push	bc			; (C) old_node_len

	; Fix next_ptrs before closing hole (threshold = node, size = old_len)
	pop	bc			; BC = old_node_len	[B]
	pop	hl			; HL = ins_point	[line_num]
	push	hl			; (B) ins_point
	push	bc			; (C) old_node_len

	call	FIX_NEXT_SUB

	; Close the hole
	pop	bc			; BC = old_node_len	[B]
	pop	hl			; HL = ins_point	[line_num]
	push	hl			; (B) ins_point
	push	bc			; (C) old_node_len

	call	MEM_CLOSE_HOLE		; HL=ins_point, BC=old_len

	; Re-find insertion point (memory shifted)
	pop	bc			; discard old_node_len	[B]
	pop	bc			; BC = line number	[]
	push	bc			; (A) line number

	call	LINE_FIND
	; HL = new insertion point, carry (should be 0 since old was deleted)

	; Fall through to INSERT logic above
	; Stack: [line_num]
	; Re-insert by jumping to the INSERT section
	; We need to push the new ins_point and go to the insert code
	push	hl			; (B) ins_point
	jr	LS_INSERT_AFTER		; jump to insert path

; -----------------------------------------------------------------------
LS_DELETE:
	; Stack: [line_num]
	; Delete the line if it exists
	pop	bc			; BC = line number	[]

	call	LINE_FIND
	jr	nc, LS_DONE_DEL		; not found → nothing to delete

	; HL = node to delete
	push	hl			; (D) node

	call	NODE_LEN		; BC = node length

	pop	hl			; HL = node		[]

	; Fix next_ptrs
	push	bc			; (E) node_len
	push	hl			; (D) node
	push	bc			; (E) node_len

	call	FIX_NEXT_SUB		; HL=node, BC=node_len

	; Close hole
	pop	bc			; BC = node_len		[D]
	pop	hl			; HL = node		[E]
	; HL=node, BC=node_len
	call	MEM_CLOSE_HOLE

	pop	bc			; cleanup		[]
	ret

LS_DONE_DEL:
	ret

; -----------------------------------------------------------------------
; Shared insert path after replacement
; -----------------------------------------------------------------------
LS_INSERT_AFTER:
	; Stack: [ins_point, line_num]
	; Reached from LS_REPLACE after re-finding insertion point
	; Re-run the insert logic

	; Calculate node length: 4 + token_len
	ld	hl, MEM_TOKEN_BUF + 3
	call	TOKEN_LEN		; BC = token length
	ld	hl, 4
	add	hl, bc			; HL = node length
	ld	(MEM_SCRATCH_LEN), hl	; save node length

	; Fix next_ptrs
	pop	hl			; HL = ins_point	[line_num]
	push	hl			; (B) ins_point
	ld	bc, (MEM_SCRATCH_LEN)
	call	FIX_NEXT_ADD

	; Open hole
	pop	hl			; HL = ins_point	[line_num]
	push	hl			; (B) ins_point
	ld	bc, (MEM_SCRATCH_LEN)
	call	MEM_OPEN_HOLE

	; Write node header
	pop	hl			; HL = ins_point	[line_num]
	push	hl			; (B) ins_point

	push	hl
	ld	bc, (MEM_SCRATCH_LEN)
	add	hl, bc
	ex	de, hl
	pop	hl

	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl

	pop	de			; DE = line number	[]
	ld	a, e
	ld	(hl), a
	inc	hl
	ld	a, d
	ld	(hl), a
	inc	hl

	pop	af			; clean stack (stale ins_point)
	ex	de, hl
	ld	hl, MEM_TOKEN_BUF + 3

LS_INSERT_COPY:
	ld	a, (hl)
	ld	(de), a
	or	a
	ret	z

	inc	hl
	inc	de
	jr	LS_INSERT_COPY
