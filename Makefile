MAKEFLAGS += --no-print-directory

.DEFAULT_GOAL := help

.PHONY: build build-m6502 build-mips build-z80 clean help run run-mips

MIPS_TARGET := bin/mips/pbasic.s

EMULATOR ?= spim

help: ## Show available targets
	@echo "pbasic - Available targets"
	@echo ""
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*## "} {printf "  %-15s %s\n", $$1, $$2}'

build: build-mips ## Build all platforms (MIPS only for now)

build-mips: ## Concatenate MIPS sources into a single file
	@./.make/build_mips.sh

build-z80: ## Assemble Z80 sources into a .bin file
	@./.make/build_z80.sh

build-m6502: ## Assemble M6502 sources into a .bin file
	@./.make/build_m6502.sh

run: run-mips ## Build and run MIPS on SPIM/MARS emulator

run-mips: build-mips ## Build and run MIPS on SPIM/MARS emulator
	$(EMULATOR) -mapped_io -file $(MIPS_TARGET)

clean: ## Remove build artifacts
	rm -f $(MIPS_TARGET) bin/z80/pbasic.bin bin/m6502/pbasic.bin
