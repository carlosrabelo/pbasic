#!/usr/bin/env bash
# build_m6502.sh - Assemble PBasic M6502 sources via xa
# -----------------------------------------------------------------------

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT_DIR/src/m6502"
OUT_DIR="$ROOT_DIR/bin/m6502"
OUT_FILE="${OUT_DIR}/pbasic.bin"

if ! command -v xa &>/dev/null; then
    echo "Error: xa (xa65) not found. Install it with: sudo apt install xa65"
    exit 1
fi

if [ ! -f "$SRC_DIR/main.asm" ]; then
    echo "M6502 sources not found at $SRC_DIR — nothing to build."
    exit 0
fi

mkdir -p "$OUT_DIR"

xa -I "$SRC_DIR" -o "$OUT_FILE" "$SRC_DIR/main.asm"

echo "Assembled M6502 binary: ${OUT_FILE}"
