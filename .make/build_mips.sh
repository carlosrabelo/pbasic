#!/usr/bin/env bash
# build_mips.sh - Helper script to combine PBasic MIPS sources
# -----------------------------------------------------------------------

set -e

# Directories
SRC_DIR="src/mips"
OUT_DIR="bin/mips"
OUT_FILE="${OUT_DIR}/pbasic.s"

# Ensure output directory exists
mkdir -p "$OUT_DIR"

# Start the combined file
echo "# PBasic MIPS SPIM/MARS Combined Source" > "$OUT_FILE"

# Array defining the precise order of files to combine
# This ensures dependencies like constants and functions are available
# before the main execution loop.
FILES=(
    "main.asm"
    "defs.asm"
    "strings.asm"
    "util.asm"
    "variables.asm"
    "math.asm"
    "expr.asm"
    "commands.asm"
    "io.asm"
    "tokenize.asm"
    "detokenize.asm"
    "memmgr.asm"
    "lines.asm"
)

# Concatenate all files into the output
for file in "${FILES[@]}"; do
    cat "${SRC_DIR}/${file}" >> "$OUT_FILE"
done

echo "Compiled MIPS source: ${OUT_FILE}"
