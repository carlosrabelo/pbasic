MAKEFLAGS += --no-print-directory

.DEFAULT_GOAL := help

.PHONY: help build run clean

MIPS_TARGET := bin/pbasic.s

EMULATOR ?= spim

help: ## Show available targets
	@echo "pbasic - Available targets"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  %-15s %s\n", $$1, $$2 } /^##@/ { printf "\n%s\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

build: ## Concatenate MIPS sources into a single file
	@./scripts/build_mips.sh

run: build ## Build and run in SPIM/MARS emulator
	$(EMULATOR) -mapped_io -file $(MIPS_TARGET)

clean: ## Remove build artifacts
	rm -f $(MIPS_TARGET)
