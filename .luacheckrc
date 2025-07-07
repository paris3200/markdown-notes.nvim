-- luacheck configuration for markdown-notes.nvim

-- Use LuaJIT + Neovim standard library
std = "luajit"

-- Add Neovim globals
globals = {
	"vim",
}

-- Additional read-only globals for testing
read_globals = {
	-- Busted testing framework
	"describe",
	"it",
	"before_each",
	"after_each",
	"setup",
	"teardown",
	"assert",
	"spy",
	"stub",
	"mock",
	-- Plenary testing
	"require",
}

-- Files/directories to exclude
exclude_files = {
	".luarocks/",
	"doc/tags",
}

-- Ignore specific warnings
ignore = {
	"212", -- Unused argument (common in Neovim plugins for callback functions)
	"213", -- Unused loop variable (common in ipairs/pairs loops)
}

-- Maximum line length
max_line_length = 120

-- Files and their specific configurations
files = {
	["tests/"] = {
		-- Allow longer lines in tests for readability
		max_line_length = 120,
		-- Additional testing globals
		globals = {
			"vim", -- vim is mocked in tests
		},
	},
}
