; commands.asm - Command dispatch engine for PBasic Z80
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; REPL_DISPATCH - Analyze token buffer and execute commands
; -----------------------------------------------------------------------
; For Phase 1, this is a no-op stub. Phase 6+ will implement the
; command jump table and execution engine.
;
; Input:  MEM_TOKEN_BUF (tokenized line), MEM_TOKEN_PTR
; Output: None
; Clobbers: All
; -----------------------------------------------------------------------
REPL_DISPATCH:
	; try to evaluate whether it's a line number or a command
    
	; For Phase 1: just return to REPL
	ret
