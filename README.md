# PBasic

Deterministic integer BASIC interpreter implemented across modern programming languages.

## Highlights

- Simple, deterministic integer BASIC execution modeled after classic microcomputer interpreters
- Support for 26 single-letter variables with signed 32-bit integer precision
- Ordered line-numbered program storage from 1 to 65535
- Interactive REPL and non-interactive batch script execution
- Essential control flow commands including GOTO, GOSUB, RETURN, and IF...THEN
- Integer arithmetic primitives with unsigned 16-bit division and modulo semantics
- Built-in functions RND, ABS, and FREE for pseudo-random numbers and memory tracking
- Consistent, multi-language implementations sharing identical syntax semantics and test suites

## Prerequisites

- **GCC / Clang** — C++20 compiler required for the C++ component (`g++` 11+ or `clang++` 13+)
- **Go** — Go 1.24+ required for the Go component
- **Free Pascal** — Free Pascal 3.2+ (`fpc`) required for the Pascal component
- **Rust** — Rust 1.70+ (`cargo`) required for the Rust component
- **Make** — GNU Make 4.0+ for build automation

## Installation

### Build from Source

Clone the repository and compile the components:

```bash
git clone https://github.com/carlosrabelo/pbasic.git
cd pbasic
make build
```

## Usage

### Interactive REPL

Start any implementation's interpreter without arguments:

```bash
# C++
./cpp/bin/pbasic

# Go
./go/bin/pbasic

# Free Pascal
./pascal/bin/pbasic

# Rust
./rust/bin/pbasic
```

Example session:

```basic
> 10 PRINT "HELLO, WORLD!"
> 20 END
> RUN
HELLO, WORLD!
> EXIT
```

### Batch Script Execution

Execute a shared BASIC demo script or any `.bas` file directly with any implementation:

```bash
# Run hello world demo
./cpp/bin/pbasic demos/01_hello.bas
./go/bin/pbasic demos/01_hello.bas
./pascal/bin/pbasic demos/01_hello.bas
./rust/bin/pbasic demos/01_hello.bas
```

The `demos/` directory contains standard example programs:
- `demos/01_hello.bas` — Output, variable loops, and iteration
- `demos/02_math.bas` — Signed 32-bit math, division, and modulo
- `demos/03_guess.bas` — Interactive number guessing game (`INPUT`, `RND`)
- `demos/99_test.bas` — Comprehensive automated regression test suite

## Project Layout

```
cpp/                 # C++20 implementation and Catch2 test suite
go/                  # Go implementation and test suite
pascal/              # Free Pascal implementation and test suite
rust/                # Rust implementation and test suite
demos/               # Shared BASIC demonstration programs
Makefile             # Root orchestrator Makefile
LICENSE              # MIT License
```

## Development

```bash
make build           # Compile all components
make test            # Run tests across all components
make quality         # Run formatting and static analysis checks
make clean           # Remove build artifacts
```

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
