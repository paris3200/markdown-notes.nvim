local notes = require("markdown-notes.notes")
local config = require("markdown-notes.config")

describe("notes", function()
	before_each(function()
		config.options = {}
		config.workspaces = {}
		config.setup({
			vault_path = "/tmp/test-vault",
			notes_subdir = "notes",
		})
	end)

	describe("create_new_note", function()
		it("has create_new_note function", function()
			assert.is_not_nil(notes.create_new_note)
			assert.are.equal("function", type(notes.create_new_note))
		end)

		it("generates timestamp-based filename format", function()
			-- Test the timestamp generation logic by checking it uses os.time
			local original_os = _G.os
			local test_timestamp = 1720094400
			_G.os = setmetatable({
				time = function()
					return test_timestamp
				end,
			}, { __index = original_os })

			-- Mock vim.fn.input to return empty string (no title)
			local original_input = vim.fn.input
			vim.fn.input = function()
				return ""
			end

			-- Mock file operations to avoid actual file creation
			local original_expand = vim.fn.expand
			vim.fn.expand = function(path)
				if path:match("^/tmp/test%-vault") then
					return path
				end
				return original_expand(path)
			end

			local original_fnamemodify = vim.fn.fnamemodify
			vim.fn.fnamemodify = function(path, modifier)
				if modifier == ":h" then
					return "/tmp/test-vault/notes"
				end
				return original_fnamemodify(path, modifier)
			end

			local original_isdirectory = vim.fn.isdirectory
			vim.fn.isdirectory = function()
				return 1
			end

			local opened_file = nil
			local original_cmd = vim.cmd
			vim.cmd = function(cmd)
				if cmd:match("^edit ") then
					opened_file = cmd:match("^edit (.+)$")
				end
			end

			local original_buf_set_lines = vim.api.nvim_buf_set_lines
			vim.api.nvim_buf_set_lines = function() end

			-- Call the function
			notes.create_new_note()

			-- Verify timestamp-based filename was used
			assert.is_not_nil(opened_file)
			assert.matches(tostring(test_timestamp), opened_file)

			-- Restore mocks
			_G.os = original_os
			vim.fn.input = original_input
			vim.fn.expand = original_expand
			vim.fn.fnamemodify = original_fnamemodify
			vim.fn.isdirectory = original_isdirectory
			vim.cmd = original_cmd
			vim.api.nvim_buf_set_lines = original_buf_set_lines
		end)
	end)

	describe("workspace integration", function()
		it("uses workspace-specific vault path", function()
			-- Set up workspace
			config.setup_workspace("work", {
				vault_path = "/work/notes",
				notes_subdir = "projects",
			})

			-- Mock vim.api.nvim_buf_get_name to return work workspace path
			local original_get_name = vim.api.nvim_buf_get_name
			vim.api.nvim_buf_get_name = function(bufnr)
				return "/work/notes/existing.md"
			end

			-- Mock other functions
			local original_input = vim.fn.input
			vim.fn.input = function()
				return "test-note"
			end

			local original_expand = vim.fn.expand
			vim.fn.expand = function(path)
				return path
			end

			local original_fnamemodify = vim.fn.fnamemodify
			vim.fn.fnamemodify = function(path, modifier)
				if modifier == ":h" then
					return "/work/notes/projects"
				end
				return path
			end

			local original_isdirectory = vim.fn.isdirectory
			vim.fn.isdirectory = function()
				return 1
			end

			local opened_file = nil
			local original_cmd = vim.cmd
			vim.cmd = function(cmd)
				if cmd:match("^edit ") then
					opened_file = cmd:match("^edit (.+)$")
				end
			end

			local original_buf_set_lines = vim.api.nvim_buf_set_lines
			vim.api.nvim_buf_set_lines = function() end

			-- Call the function
			notes.create_new_note()

			-- Verify workspace-specific path was used
			assert.is_not_nil(opened_file)
			assert.matches("/work/notes/projects", opened_file)
			assert.matches("test%-note", opened_file)

			-- Restore mocks
			vim.api.nvim_buf_get_name = original_get_name
			vim.fn.input = original_input
			vim.fn.expand = original_expand
			vim.fn.fnamemodify = original_fnamemodify
			vim.fn.isdirectory = original_isdirectory
			vim.cmd = original_cmd
			vim.api.nvim_buf_set_lines = original_buf_set_lines
		end)
	end)
end)
