MAKEFLAGS += --no-print-directory

.DEFAULT_GOAL := help

.PHONY: build-z80 build-mips build-m6502 clean help run-mips run-m6502 run-z80

EMULATOR ?= spim
MOJAVE ?= /home/carlos/Sources/mojave/bin/mojave
Z80_BIN := bin/z80/pbasic.bin
MIPS_SRC := bin/mips/pbasic.s
M6502_BIN := bin/m6502/pbasic.bin

help: ## Show available targets
	@echo "pbasic - Available targets"
	@echo ""
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*## "} {printf "  %-15s %s\n", $$1, $$2}'

build-mips: ## Concatenate MIPS sources into a single file
	@./.make/build_mips.sh

build-z80: ## Assemble Z80 sources into a .bin file
	@./.make/build_z80.sh

build-m6502: ## Assemble M6502 sources into a .bin file
	@./.make/build_m6502.sh

run-mips: build-mips ## Build and run MIPS on SPIM/MARS emulator
	$(EMULATOR) -mapped_io -file $(MIPS_SRC)

run-z80: build-z80 ## Build and run Z80 on MOJAVE emulator
	$(MOJAVE) --machine z80 --load-bin $(Z80_BIN)

run-m6502: build-m6502 ## Build and run M6502 on MOJAVE emulator
	$(MOJAVE) --machine m6502 --load-bin $(M6502_BIN)

clean: ## Remove build artifacts
	rm -f $(MIPS_SRC) $(Z80_BIN) $(M6502_BIN)
