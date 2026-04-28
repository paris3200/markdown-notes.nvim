local notes = require("markdown-notes.notes")
local config = require("markdown-notes.config")

describe("notes", function()
	before_each(function()
		config.options = {}
		config.workspaces = {}
		config.current_active_workspace = nil
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

		it("uses title slug as filename by default", function()
			local original_input = vim.fn.input
			vim.fn.input = function() return "My New Note" end

			local original_expand = vim.fn.expand
			vim.fn.expand = function(path)
				if path:match("^/tmp/test%-vault") then return path end
				return original_expand(path)
			end

			local original_filereadable = vim.fn.filereadable
			vim.fn.filereadable = function() return 0 end

			local original_fnamemodify = vim.fn.fnamemodify
			vim.fn.fnamemodify = function(path, modifier)
				if modifier == ":h" then return "/tmp/test-vault/notes" end
				return original_fnamemodify(path, modifier)
			end

			local original_isdirectory = vim.fn.isdirectory
			vim.fn.isdirectory = function() return 1 end

			local opened_file = nil
			local original_cmd = vim.cmd
			vim.cmd = function(cmd)
				if cmd:match("^edit ") then opened_file = cmd:match("^edit (.+)$") end
			end

			local original_buf_set_lines = vim.api.nvim_buf_set_lines
			vim.api.nvim_buf_set_lines = function() end

			notes.create_new_note()

			assert.is_not_nil(opened_file)
			assert.matches("my%-new%-note%.md$", opened_file)

			vim.fn.input = original_input
			vim.fn.expand = original_expand
			vim.fn.filereadable = original_filereadable
			vim.fn.fnamemodify = original_fnamemodify
			vim.fn.isdirectory = original_isdirectory
			vim.cmd = original_cmd
			vim.api.nvim_buf_set_lines = original_buf_set_lines
		end)

		it("opens existing file instead of creating when slug already exists", function()
			local original_input = vim.fn.input
			vim.fn.input = function() return "Existing Note" end

			local original_expand = vim.fn.expand
			vim.fn.expand = function(path)
				if path:match("^/tmp/test%-vault") then return path end
				return original_expand(path)
			end

			local original_filereadable = vim.fn.filereadable
			vim.fn.filereadable = function() return 1 end  -- file already exists

			local opened_file = nil
			local original_cmd = vim.cmd
			vim.cmd = function(cmd)
				if cmd:match("^edit ") then opened_file = cmd:match("^edit (.+)$") end
			end

			local mkdir_called = false
			local original_mkdir = vim.fn.mkdir
			vim.fn.mkdir = function() mkdir_called = true end

			notes.create_new_note()

			assert.is_not_nil(opened_file)
			assert.matches("existing%-note%.md$", opened_file)
			assert.is_false(mkdir_called)  -- no directory creation for existing file

			vim.fn.input = original_input
			vim.fn.expand = original_expand
			vim.fn.filereadable = original_filereadable
			vim.cmd = original_cmd
			vim.fn.mkdir = original_mkdir
		end)

		it("prepends timestamp when filename_prefix is timestamp", function()
			config.options = {}
			config.workspaces = {}
			config.setup({
				vault_path = "/tmp/test-vault",
				notes_subdir = "notes",
				filename_prefix = "timestamp",
			})

			local original_os = _G.os
			local test_timestamp = 1720094400
			_G.os = setmetatable({ time = function() return test_timestamp end }, { __index = original_os })

			local original_input = vim.fn.input
			vim.fn.input = function() return "My Note" end

			local original_expand = vim.fn.expand
			vim.fn.expand = function(path)
				if path:match("^/tmp/test%-vault") then return path end
				return original_expand(path)
			end

			local original_fnamemodify = vim.fn.fnamemodify
			vim.fn.fnamemodify = function(path, modifier)
				if modifier == ":h" then return "/tmp/test-vault/notes" end
				return original_fnamemodify(path, modifier)
			end

			local original_isdirectory = vim.fn.isdirectory
			vim.fn.isdirectory = function() return 1 end

			local opened_file = nil
			local original_cmd = vim.cmd
			vim.cmd = function(cmd)
				if cmd:match("^edit ") then opened_file = cmd:match("^edit (.+)$") end
			end

			local original_buf_set_lines = vim.api.nvim_buf_set_lines
			vim.api.nvim_buf_set_lines = function() end

			notes.create_new_note()

			assert.is_not_nil(opened_file)
			assert.matches(tostring(test_timestamp) .. "%-my%-note%.md$", opened_file)

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
