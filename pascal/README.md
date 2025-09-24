# PBasic (Free Pascal)

PicoBasic interpreter implemented in Free Pascal.

## Highlights

- Implemented in modern Free Pascal following Object Pascal conventions
- Zero external runtime dependencies
- Interactive REPL prompt with case folding and immediate mode
- Stored program memory management supporting line numbers 1 to 65535
- 32-bit integer arithmetic with classic 16-bit division semantics
- Comprehensive unit test suite and automated regression suite

## Prerequisites

- **Free Pascal** — Free Pascal 3.2+ (`fpc`)
- **Make** — GNU Make 4.0+

## Installation

### Build from Source

```bash
make build
```

## Usage

### Interactive REPL

```bash
./bin/pbasic
```

### Batch File Execution

```bash
./bin/pbasic program.bas
```

## Project Layout

```
src/                 # Free Pascal source units (main.pas, pbasic_*.pas)
bin/                 # Compiled binaries
tests/               # Unit test runner
.make/               # Automation scripts
Makefile             # Component Makefile
```

## Development

```bash
make build           # Compile binary to bin/pbasic
make test            # Run Free Pascal unit test suite
make quality         # Run compiler checks and test suite
make clean           # Remove build artifacts
```

## License

This project is licensed under the MIT License — see [../LICENSE](../LICENSE) for details.
