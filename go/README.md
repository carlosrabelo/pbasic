# PBasic (Go)

PicoBasic interpreter implemented in Go 1.24+.

## Highlights

- Implemented in standard Go following `cmd/internal` package layout
- Zero external runtime dependencies
- Interactive REPL prompt with case folding and immediate mode
- Stored program memory management supporting line numbers 1 to 65535
- 32-bit integer arithmetic with classic 16-bit division semantics
- Comprehensive Go standard unit tests and automated regression suite

## Prerequisites

- **Go** — Go 1.24+ (`go`)
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
pbasic/              # Go source code (cmd/, internal/)
demos/               # BASIC example scripts
bin/                 # Compiled binaries
.make/               # Automation scripts
Makefile             # Component Makefile
go.mod               # Go module declaration
```

## Development

```bash
make build           # Compile binary to bin/pbasic
make test            # Run Go unit test suite
make quality         # Run formatting and go vet
make clean           # Remove build artifacts
```

## License

This project is licensed under the MIT License — see [../LICENSE](../LICENSE) for details.
