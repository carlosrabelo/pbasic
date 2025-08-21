MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
.SUFFIXES:

.PHONY: help build test run quality clean

help: ## Show available targets
	@echo "pbasic (Go) - Available targets"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build binary
	@.make/build.sh

test: ## Run test suite
	@.make/test.sh

run: ## Run interactive REPL
	@.make/run.sh

quality: ## Run code quality checks
	@.make/quality.sh

clean: ## Clean build artifacts
	@rm -rf bin/pbasic
