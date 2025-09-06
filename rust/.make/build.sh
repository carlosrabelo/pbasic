#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p "$ROOT_DIR/bin"
cargo build
cp "$ROOT_DIR/target/debug/pbasic" "$ROOT_DIR/bin/pbasic"
echo "Build complete: $ROOT_DIR/bin/pbasic"
