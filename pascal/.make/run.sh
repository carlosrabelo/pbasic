#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/bin"
BINARY_NAME="pbasic"

if [ ! -f "$BUILD_DIR/$BINARY_NAME" ]; then
    echo "Binary not found. Run 'make build' first."
    exit 1
fi

exec "$BUILD_DIR/$BINARY_NAME" "$@"
