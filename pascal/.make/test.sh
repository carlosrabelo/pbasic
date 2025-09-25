#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$ROOT_DIR/bin"
TEST_RUNNER="$ROOT_DIR/tests/test_runner.pas"

mkdir -p "$BIN_DIR"

if [ -f "$TEST_RUNNER" ]; then
    echo "Running Free Pascal unit tests..."
    fpc -Mobjfpc -Sh -O2 -gl -gw \
        -FE"$BIN_DIR" \
        -FU"$BIN_DIR" \
        -Fu"$ROOT_DIR/src" \
        -Fu"$ROOT_DIR/lib" \
        "$TEST_RUNNER" \
        -o"test_runner"
    "$BIN_DIR/test_runner" "$@"
fi

# Ensure main binary is built
"$ROOT_DIR/.make/build.sh"

DEMO_FILE="$ROOT_DIR/demos/99_test.bas"
if [ "${ENABLE_DEMOS:-0}" = "1" ]; then
    DEMO_FILE="$ROOT_DIR/../demos/99_test.bas"
fi

if [ -f "$DEMO_FILE" ] && [ -f "$BIN_DIR/pbasic" ]; then
    echo "Running regression demo suite (demos/99_test.bas)..."
    DEMO_OUTPUT=$("$BIN_DIR/pbasic" "$DEMO_FILE")

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
