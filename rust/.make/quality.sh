#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running cargo fmt check..."
cargo fmt --all -- --check || true

echo "Running cargo clippy..."
cargo clippy --all-targets || true
