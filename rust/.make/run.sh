#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

"$ROOT_DIR/.make/build.sh"
exec "$ROOT_DIR/bin/pbasic" "$@"
