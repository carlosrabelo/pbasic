# PBasic Z80 Development Roadmap

## Phase 1: The System Core & I/O
- [x] Memory mapping and CPU stack initialization (defs/constants)
- [x] Base I/O routines: `INCHAR`, `OUTCHAR` (TTY integration, Port 0x00)
- [x] String and number output: `PRINT_STR`, `PRINT_NUMBER`, `PRINT_CRLF`
- [x] Read input buffer: `READ_LINE` (with uppercase conversion)
- [x] The heart of the system: Basic REPL loop (Read-Eval-Print Loop) prompt `>`

## Phase 2: Lexical Analysis (Tokenizer)
- [x] Implement the `TOKENIZE` engine to convert ASCII input into internal 1-byte tokens
- [x] Recognize keywords via `MATCH_KEYWORD` (LET, PRINT, IF, GOTO, etc.)
- [x] Parse decimal ASCII numbers into 16-bit little-endian format (token 0xC0)
- [x] Classify string literals (token 0xC1) and single-letter variables (A-Z)
- [x] Detokenizer routines (`PRINT_TOKENS`) to revert tokens back to text

## Phase 3: Program Memory Management
- [x] Initialize program memory as a Linked List (`PROG_INIT` with sentinel)
- [x] Line finding algorithm (`LINE_FIND`)
- [x] Dynamic memory insertion/deletion: `MEM_OPEN_HOLE`, `MEM_CLOSE_HOLE`
- [x] Store new lines or replace existing ones: `LINE_STORE`
- [x] Implement the `LIST` command to dump the tokenized linked list

## Phase 4: Mathematical Engine & Variables
- [x] Variable storage initialization (fixed RAM): `VAR_INIT`
- [x] Variable access primitives: `VAR_GET`, `VAR_SET`
- [x] 16-bit unsigned multiplication: `MUL16` (shift-and-add logic)
- [x] 16-bit unsigned division and modulo: `DIV16`, `MOD16`

## Phase 5: Expression Evaluator (Recursive Descent Parser)
- [x] `EVAL_FACTOR`: Handle numeric literals, variables, parentheses, and unary minus
- [x] `EVAL_TERM`: Multiplication and division (`*`, `/`)
- [x] `EVAL_EXPR`: Addition and subtraction (`+`, `-`)
- [x] `EVAL_COND`: Boolean comparisons (`=`, `<>`, `<`, `>`, `<=`, `>=`)

## Phase 6: Core Execution Engine
- [x] Direct command jump table: `REPL_DISPATCH`
- [x] `PRINT`: Output expressions, string literals, handling `,` (tabs) and `;` (no newline)
- [x] `LET`: Assign evaluated expressions to variables
- [x] `NEW`: Clear the program linked list and variables
- [x] `REM`: Ignore the remainder of the line
- [x] `FREE`: Calculate available bytes between the program end and stack/variable space

## Phase 7: Control Flow
- [x] `RUN`: Traverse the linked list and dispatch tokens sequentially
- [x] `END` and `EXIT`: Halt execution cleanly
- [ ] `GOTO`: Unconditional jump by updating the line pointer
- [ ] `GOSUB` and `RETURN`: Subroutine calls using an internal 16-level call stack
- [ ] `IF / THEN`: Conditional branching

## Phase 8: Advanced Functions & Interactivity
- [ ] `INPUT`: Pause execution, read from TTY, and assign to variable
- [ ] `RND(x)`: Linear congruential pseudo-random number generator
- [ ] `ABS(x)`: Calculate absolute value (Two's complement)
