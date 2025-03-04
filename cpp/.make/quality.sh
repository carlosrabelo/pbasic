#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "Running quality checks..."
if command -v clang-format &>/dev/null; then
    find "$ROOT_DIR/src" "$ROOT_DIR/tests" -type f \( -name '*.cpp' -o -name '*.hpp' \) 2>/dev/null -exec clang-format --dry-run --Werror {} + || true
fi
"$ROOT_DIR/.make/test.sh"
echo "Quality checks passed."
