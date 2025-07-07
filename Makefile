# Makefile for markdown-notes.nvim

.PHONY: test lint lint-fix clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  test     - Run all tests"
	@echo "  lint     - Run luacheck linter"
	@echo "  lint-fix - Run luacheck and show detailed issues for fixing"
	@echo "  clean    - Clean up temporary files"
	@echo "  help     - Show this help message"

# Run tests
test:
	nvim --headless -u tests/minimal_init.vim -c "lua require('plenary.test_harness').test_directory('tests')"

# Run linter
lint:
	luacheck lua/ tests/

# Run linter with detailed output for fixing
lint-fix:
	luacheck --formatter plain --codes lua/ tests/

# Clean up
clean:
	find . -name "*.tmp" -delete
	find . -name "luacov.*" -delete

# Check dependencies
check-deps:
	@command -v luacheck >/dev/null 2>&1 || { echo "luacheck not found. Install with: luarocks install luacheck"; exit 1; }
	@echo "✓ All dependencies available"