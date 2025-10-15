MAKEFLAGS += --no-print-directory

.DEFAULT_GOAL := help

.PHONY: build clean help quality test

help: ## Show available targets
	@echo "pbasic - Available targets"
	@echo ""
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*## "} {printf "  %-15s %s\n", $$1, $$2}'

build: ## Build all components
	@$(MAKE) -C cpp build
	@$(MAKE) -C go build
	@$(MAKE) -C pascal build
	@$(MAKE) -C rust build

test: ## Run tests across all components
	@$(MAKE) -C cpp test
	@$(MAKE) -C go test
	@$(MAKE) -C pascal test
	@$(MAKE) -C rust test

quality: ## Run quality checks across all components
	@$(MAKE) -C cpp quality
	@$(MAKE) -C go quality
	@$(MAKE) -C pascal quality
	@$(MAKE) -C rust quality

clean: ## Remove build artifacts
	@$(MAKE) -C cpp clean
	@$(MAKE) -C go clean
	@$(MAKE) -C pascal clean
	@$(MAKE) -C rust clean
