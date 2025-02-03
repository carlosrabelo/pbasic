# PBasic

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Multi-architecture PBasic interpreter (MIPS/Z80/M6502) written in assembly. The MIPS version runs on SPIM and MARS simulators; Z80 and M6502 versions are in development to test the [MOJAVE](https://github.com/carlosrabelo/mojave) emulator platform.

## Highlights

- PBasic dialect supporting LET, PRINT, IF/THEN, LIST, NEW, EXIT, REM, INPUT, RUN, END, and FREE
- Expression evaluator with recursive descent parsing (+, -, *, /, parentheses, unary minus)
- 26 variables (A-Z) stored as 32-bit integers
- 52 KB program area with tokenized line storage as a linked list
- FREE function reports available memory (as command or in expressions)
- I/O via SPIM/MARS standard syscalls (`mapped_io` mode for interactive input)

## Overview

PBasic began in 2014 as a passion project during my Computer Science degree.

The project is now expanding beyond MIPS: ports for **Z80** and **M6502** are in development. These new implementations share the same PBasic dialect and serve as real-world test cases for [MOJAVE](https://github.com/carlosrabelo/mojave), a multi-platform emulator framework. Originally written in MIPS assembly to run on the MARS simulator, I built it to demonstrate to my classmates that assembly language could be used to build practical, fully functional software—like a complete BASIC interpreter—rather than just toy academic exercises.

## Prerequisites

- **spim** — MIPS simulator; install with `sudo apt install spim`
- **mars** — MIPS Assembler and Runtime Simulator (optional, download from [missouristate.edu/MARS](https://courses.missouristate.edu/KenVollmar/MARS/))

## Installation

### Build from Source

```bash
git clone https://github.com/carlosrabelo/pbasic.git
cd pbasic
make build
```

## Usage

### Build and run

```bash
make run                    # uses spim
make run EMULATOR=mars      # uses MARS
```

### Build only

```bash
make build
```

This concatenates all MIPS assembly modules into a single source file:

```bash
# Run MIPS assembly source on SPIM simulator
spim -mapped_io -file bin/mips/pbasic.s

# Run MIPS assembly source on MARS simulator
java -jar MARS.jar bin/mips/pbasic.s
```

### Example session

```
PBasic

> 10 LET A=42
> 20 PRINT A
> 30 PRINT A*2+10
> RUN
42
94
> PRINT FREE
53160
> LIST
10 LET A=42
20 PRINT A
30 PRINT A*2+10
> NEW
OK
```

## Project Layout

```
src/mips/           # MIPS assembly sources
src/z80/            # Z80 assembly sources (in development)
src/m6502/          # M6502 assembly sources (in development)
demos/              # BASIC demonstration programs and test suites
bin/mips/           # MIPS compiled source output (git-ignored)
bin/z80/            # Z80 compiled source output (git-ignored)
bin/m6502/          # M6502 compiled source output (git-ignored)
Makefile            # Build orchestrator
.make/              # Build helper scripts
```

## Development

```bash
make help              # Show available targets
make build             # Build all platforms
make build-mips        # Concatenate MIPS sources
make build-z80         # Assemble Z80 sources into .bin
make build-m6502       # Assemble M6502 sources into .bin
make run               # Build and run MIPS on SPIM/MARS
make run-mips          # Build and run MIPS on SPIM/MARS
make clean             # Remove build artifacts
```

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
