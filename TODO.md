# PBasic MIPS — Development Roadmap

## Phase 1: The System Core & I/O
- [x] Memory mapping and CPU stack initialization (defs/constants)
- [x] Base I/O routines: `INCHAR`, `OUTCHAR` (SPIM syscalls 11 and 12)
- [x] String and number output: `PRINT_STR`, `PRINT_NUMBER`, `PRINT_CRLF` (SPIM syscalls 4 and 1)
- [x] Read input buffer: `READ_LINE` (with uppercase conversion)
- [x] The heart of the system: Basic REPL loop (Read-Eval-Print Loop) prompt `>`

## Phase 2: Lexical Analysis (Tokenizer)
- [x] Implement the `TOKENIZE` engine to convert ASCII input into internal 1-byte tokens
- [x] Recognize keywords via `MATCH_KEYWORD` (LET, PRINT, IF, GOTO, etc.)
- [x] Parse decimal ASCII numbers into 16-bit little-endian format (token 0xC0)
- [ ] Classify string literals (token 0xC1) and single-letter variables (A-Z)
- [ ] Detokenizer routines (`PRINT_TOKENS`) to revert tokens back to text

## Phase 3: Program Memory Management
- [ ] Initialize program memory as a Linked List (`PROG_INIT` with sentinel)
- [ ] Line finding algorithm (`LINE_FIND`)
- [ ] Dynamic memory insertion/deletion: `MEM_OPEN_HOLE`, `MEM_CLOSE_HOLE`
- [ ] Store new lines or replace existing ones: `LINE_STORE`
- [ ] Implement the `LIST` command to dump the tokenized linked list

## Phase 4: Mathematical Engine & Variables
- [ ] Variable storage initialization (`.data` section or dynamic heap): `VAR_INIT`
- [ ] Variable access primitives: `VAR_GET`, `VAR_SET`
- [ ] 16-bit unsigned multiplication: `MUL16` (using MIPS native `mult` / `mflo`)
- [ ] 16-bit unsigned division and modulo: `DIV16`, `MOD16` (using MIPS native `div` / `mflo` / `mfhi`)

## Phase 5: Expression Evaluator (Recursive Descent Parser)
- [ ] `EVAL_FACTOR`: Handle numeric literals, variables, parentheses, and unary minus
- [ ] `EVAL_TERM`: Multiplication and division (`*`, `/`)
- [ ] `EVAL_EXPR`: Addition and subtraction (`+`, `-`)
- [ ] `EVAL_COND`: Boolean comparisons (`=`, `<>`, `<`, `>`, `<=`, `>=`)

## Phase 6: Core Execution Engine
- [ ] Direct command jump table: `REPL_DISPATCH`
- [ ] `PRINT`: Output expressions, string literals, handling `,` (tabs) and `;` (no newline)
- [ ] `LET`: Assign evaluated expressions to variables
- [ ] `NEW`: Clear the program linked list and variables
- [ ] `REM`: Ignore the remainder of the line
- [ ] `FREE`: Calculate available bytes between the program end and stack/variable space

## Phase 7: Control Flow
- [ ] `RUN`: Traverse the linked list and dispatch tokens sequentially
- [ ] `END` and `EXIT`: Halt execution cleanly
- [ ] `GOTO`: Unconditional jump by updating the line pointer
- [ ] `GOSUB` and `RETURN`: Subroutine calls using an internal call stack
- [ ] `IF / THEN`: Conditional branching

## Phase 8: Advanced Functions & Interactivity
- [ ] `INPUT`: Pause execution, read from TTY, and assign to variable
- [ ] `RND(x)`: Linear congruential pseudo-random number generator
- [ ] `ABS(x)`: Calculate absolute value (using MIPS `abs` macro)


