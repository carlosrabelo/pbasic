#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$ROOT_DIR/bin"
SRC_MAIN="$ROOT_DIR/src/main.pas"

mkdir -p "$BIN_DIR"

if [ -f "$SRC_MAIN" ]; then
    echo "Building pbasic (Free Pascal)..."
    fpc -Mobjfpc -Sh -O2 -gl -gw \
        -FE"$BIN_DIR" \
        -FU"$BIN_DIR" \
        -Fu"$ROOT_DIR/src" \
        -Fu"$ROOT_DIR/lib" \
        "$SRC_MAIN" \
        -o"pbasic"
    echo "Build complete: $BIN_DIR/pbasic"
else
    echo "Notice: $SRC_MAIN not present yet. Skipping binary compilation."
fi
