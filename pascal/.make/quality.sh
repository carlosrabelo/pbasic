#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_MAIN="$ROOT_DIR/src/main.pas"

echo "Running Free Pascal quality checks..."

if [ -f "$SRC_MAIN" ]; then
    fpc -Mobjfpc -Sh -vwne -s \
        -FE"$ROOT_DIR/bin" \
        -FU"$ROOT_DIR/bin" \
        -Fu"$ROOT_DIR/src" \
        -Fu"$ROOT_DIR/lib" \
        "$SRC_MAIN" >/dev/null
fi

"$ROOT_DIR/.make/test.sh"

echo "Quality checks passed."
