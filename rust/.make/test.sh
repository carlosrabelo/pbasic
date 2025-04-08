#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "Running Rust unit tests..."
cargo test

"$ROOT_DIR/.make/build.sh"

if [ -f "$ROOT_DIR/demos/99_test.bas" ]; then
    echo "Running regression demo suite (demos/99_test.bas)..."
    DEMO_OUTPUT=$("$ROOT_DIR/bin/pbasic" "$ROOT_DIR/demos/99_test.bas")

    assert_contains() {
        local pattern="$1"
        if ! echo "$DEMO_OUTPUT" | grep -F -e "$pattern" >/dev/null; then
            echo "Regression assertion failed: pattern '$pattern' not found in demo output."
            echo "Output was:"
            echo "$DEMO_OUTPUT"
            exit 1
        fi
    }

    assert_contains "--- TEST COMPLETE ---"
    assert_contains "IN SUBROUTINE!"
    assert_contains "ABS OF -15 IS: 15"
    assert_contains "NEG FIFTEEN IS: -15"

    echo "All regression assertions passed."
fi
