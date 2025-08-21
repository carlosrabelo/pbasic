#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Formatting Go code..."
gofmt -s -w .

echo "Running go vet..."
go vet ./...
