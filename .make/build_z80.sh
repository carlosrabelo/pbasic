#!/usr/bin/env bash
# build_z80.sh - Assemble PBasic Z80 sources via z80asm
# -----------------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT_DIR/src/z80"
OUT_DIR="$ROOT_DIR/bin/z80"
OUT_FILE="${OUT_DIR}/pbasic.bin"

if ! command -v z80asm &>/dev/null; then
    echo "Error: z80asm not found. Install it with: sudo apt install z80asm"
    exit 1
fi

if [ ! -f "$SRC_DIR/main.asm" ]; then
    echo "Z80 sources not found at $SRC_DIR — nothing to build."
    exit 0
fi

mkdir -p "$OUT_DIR"

z80asm -I "$SRC_DIR" -o "$OUT_FILE" "$SRC_DIR/main.asm"

echo "Assembled Z80 binary: ${OUT_FILE}"
