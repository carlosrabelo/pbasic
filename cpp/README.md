# PBasic (C++)

PicoBasic interpreter implemented in C++20.

## Highlights

- Implemented in ISO C++20 with modular architecture
- Fast execution with zero external runtime dependencies
- Interactive REPL prompt with case folding and immediate mode
- Stored program memory management supporting line numbers 1 to 65535
- 32-bit integer arithmetic with classic 16-bit division semantics
- Unit testing infrastructure powered by Catch2

## Prerequisites

- **GCC / Clang** — C++20 compiler (`g++` 11+ or `clang++` 13+)
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
src/                 # C++20 source code (main.cpp, core/)
tests/               # Catch2 test suites
lib/                 # Vendored third-party headers (Catch2)
bin/                 # Compiled binaries
.make/               # Automation scripts
Makefile             # Component Makefile
```

## Development

```bash
make setup           # Download test dependencies (Catch2)
make build           # Compile binary to bin/pbasic
make test            # Build and run Catch2 test suite
make quality         # Run format checks and test suite
make clean           # Remove build artifacts
```

## License

This project is licensed under the MIT License — see [../LICENSE](../LICENSE) for details.
