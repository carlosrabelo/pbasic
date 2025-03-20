#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT_DIR/src"
TEST_DIR="$ROOT_DIR/tests"
LIB_DIR="$ROOT_DIR/lib"
BUILD_DIR="$ROOT_DIR/bin"
BINARY_NAME="pbasic-tests"
CXX="${CXX:-g++}"
CXXFLAGS="-std=c++20 -Wall -Wextra -Wpedantic -I$SRC_DIR -I$LIB_DIR"

mkdir -p "$BUILD_DIR"
mapfile -t TEST_SRCS < <(find "$TEST_DIR" -name '*.cpp' -print 2>/dev/null | LC_ALL=C sort)
mapfile -t SRC_FILES < <(find "$SRC_DIR" -name '*.cpp' ! -name 'main.cpp' -print 2>/dev/null | LC_ALL=C sort)

if [ "${#TEST_SRCS[@]}" -gt 0 ]; then
    echo "Building $BINARY_NAME..."
    $CXX $CXXFLAGS "${TEST_SRCS[@]}" "${SRC_FILES[@]}" -o "$BUILD_DIR/$BINARY_NAME"
    echo "Running tests..."
    "$BUILD_DIR/$BINARY_NAME" "$@"
fi

# Ensure main binary is built for regression testing
"$ROOT_DIR/.make/build.sh"

echo "Running regression demo suite (demos/99_test.bas)..."
DEMO_OUTPUT=$("$BUILD_DIR/pbasic" "$ROOT_DIR/demos/99_test.bas")

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
