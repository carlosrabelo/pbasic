MAKEFLAGS += --no-print-directory

.DEFAULT_GOAL := help

.PHONY: build clean help quality run test

help: ## Show available targets
	@echo "pbasic (Rust) - Available targets"
	@echo ""
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*## "} {printf "  %-15s %s\n", $$1, $$2}'

build: ## Compile pbasic binary
	@./.make/build.sh

test: ## Run unit tests and regression demo
	@./.make/test.sh

run: ## Run interactive REPL
	@./.make/run.sh

quality: ## Run formatting and linter checks
	@./.make/quality.sh

clean: ## Remove build artifacts
	@rm -rf target bin/pbasic
