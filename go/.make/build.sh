#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BINARY_NAME="pbasic"
CMD_PATH="./pbasic/cmd/pbasic"

mkdir -p "$ROOT_DIR/bin"
cd "$ROOT_DIR"
echo "Building $BINARY_NAME..."
go build -o "$ROOT_DIR/bin/$BINARY_NAME" "$CMD_PATH"
echo "Build complete: $ROOT_DIR/bin/$BINARY_NAME"
