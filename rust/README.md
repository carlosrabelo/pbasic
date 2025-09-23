# PBasic (Rust)

PicoBasic interpreter implemented in Rust 2021 edition.

## Highlights

- Implemented in standard Rust following idiomatic crate module conventions
- Zero external runtime dependencies
- Interactive REPL prompt with case folding and immediate mode
- Stored program memory management supporting line numbers 1 to 65535
- 32-bit integer arithmetic with classic 16-bit division semantics
- Comprehensive unit test suite and automated regression suite

## Prerequisites

- **Rust** — Rust 1.70+ / 2021 edition (`rustc`, `cargo`)
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
src/                 # Rust source code (main.rs, lib.rs, modules)
bin/                 # Compiled binaries
.make/               # Automation scripts
Makefile             # Component Makefile
Cargo.toml           # Cargo package manifest
```

## Development

```bash
make build           # Compile binary to bin/pbasic
make test            # Run Rust unit test suite
make quality         # Run formatting and clippy checks
make clean           # Remove build artifacts
```

## License

This project is licensed under the MIT License — see [../LICENSE](../LICENSE) for details.
