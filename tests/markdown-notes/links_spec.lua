local links = require("markdown-notes.links")
local config = require("markdown-notes.config")

describe("links", function()
	local temp_dir = "/tmp/markdown-notes-test"
	local vault_path = temp_dir .. "/vault"

	before_each(function()
		-- Clean up and create test directory
		vim.fn.system("rm -rf " .. temp_dir)
		vim.fn.mkdir(vault_path, "p")

		-- Setup config
		config.setup({
			vault_path = vault_path,
		})

		-- Mock vim.fn.confirm to always return 1 (Yes)
		_G.original_confirm = vim.fn.confirm
		vim.fn.confirm = function(message, choices, default)
			return 1
		end

		-- Mock vim.notify to capture notifications
		_G.notifications = {}
		_G.original_notify = vim.notify
		vim.notify = function(message, level)
			table.insert(_G.notifications, { message = message, level = level })
		end
	end)

	after_each(function()
		-- Restore original functions
		vim.fn.confirm = _G.original_confirm
		vim.notify = _G.original_notify

		-- Clean up
		vim.fn.system("rm -rf " .. temp_dir)
	end)

	describe("rename_note", function()
		it("renames a note without links", function()
			-- Create a test note
			local note_path = vault_path .. "/test-note.md"
			vim.fn.writefile({ "# Test Note", "This is a test note" }, note_path)

			-- Open the note
			vim.cmd("edit " .. note_path)

			-- Rename the note
			links.rename_note("renamed-note", { skip_ui = true })

			-- Check that the file was renamed
			assert.is_true(vim.fn.filereadable(vault_path .. "/renamed-note.md") == 1)
			assert.is_true(vim.fn.filereadable(note_path) == 0)

			-- Check notification
			assert.is_true(#_G.notifications > 0)
			assert.is_not_nil(_G.notifications[#_G.notifications].message:match("Renamed note"))
		end)

		it("renames a note and updates simple links", function()
			-- Create notes with links
			local note_path = vault_path .. "/original-note.md"
			local linking_note_path = vault_path .. "/linking-note.md"

			vim.fn.writefile({ "# Original Note", "Content here" }, note_path)
			vim.fn.writefile({ "# Linking Note", "See [[original-note]] for details" }, linking_note_path)

			-- Verify initial state
			local initial_content = table.concat(vim.fn.readfile(linking_note_path), "\n")
			assert.is_not_nil(initial_content:find("[[original-note]]", 1, true))

			-- Open the original note
			vim.cmd("edit " .. note_path)

			-- Rename the note
			links.rename_note("new-name", { skip_ui = true })

			-- Check that the file was renamed
			assert.is_true(vim.fn.filereadable(vault_path .. "/new-name.md") == 1)
			assert.is_true(vim.fn.filereadable(note_path) == 0)

			-- Check that the link was updated
			local linking_content = vim.fn.readfile(linking_note_path)
			local content_str = table.concat(linking_content, "\n")

			assert.is_not_nil(content_str:find("[[new-name]]", 1, true))
			assert.is_nil(content_str:find("[[original-note]]", 1, true))

			-- Check notification mentions updating files
			assert.is_true(#_G.notifications > 0)
			assert.is_not_nil(_G.notifications[#_G.notifications].message:match("updated 1 files"))
		end)

		it("renames a note and updates display text links", function()
			-- Create notes with display text links
			local note_path = vault_path .. "/technical-doc.md"
			local linking_note_path = vault_path .. "/index.md"

			vim.fn.writefile({ "# Technical Documentation", "Content here" }, note_path)
			vim.fn.writefile({ "# Index", "Check out [[technical-doc|Technical Docs]] for info" }, linking_note_path)

			-- Open the original note
			vim.cmd("edit " .. note_path)

			-- Rename the note
			links.rename_note("tech-guide", { skip_ui = true })

			-- Check that the file was renamed
			assert.is_true(vim.fn.filereadable(vault_path .. "/tech-guide.md") == 1)
			assert.is_true(vim.fn.filereadable(note_path) == 0)

			-- Check that the display text link was updated but display text preserved
			local linking_content = vim.fn.readfile(linking_note_path)
			local content_str = table.concat(linking_content, "\n")
			assert.is_not_nil(content_str:find("[[tech-guide|Technical Docs]]", 1, true))
			assert.is_nil(content_str:find("[[technical-doc|Technical Docs]]", 1, true))
		end)

		it("handles multiple files with different link types", function()
			-- Create the note to be renamed
			local note_path = vault_path .. "/main-topic.md"
			vim.fn.writefile({ "# Main Topic", "Content here" }, note_path)

			-- Create multiple files with different link types
			local file1_path = vault_path .. "/file1.md"
			local file2_path = vault_path .. "/file2.md"
			local file3_path = vault_path .. "/file3.md"

			vim.fn.writefile({ "See [[main-topic]] for details" }, file1_path)
			vim.fn.writefile({ "Reference: [[main-topic|Main Topic Page]]" }, file2_path)
			vim.fn.writefile({ "Both [[main-topic]] and [[main-topic|the main topic]]" }, file3_path)

			-- Open the note to rename
			vim.cmd("edit " .. note_path)

			-- Rename the note
			links.rename_note("primary-topic", { skip_ui = true })

			-- Check file was renamed
			assert.is_true(vim.fn.filereadable(vault_path .. "/primary-topic.md") == 1)
			assert.is_true(vim.fn.filereadable(note_path) == 0)

			-- Check all links were updated
			local file1_content = table.concat(vim.fn.readfile(file1_path), "\n")
			local file2_content = table.concat(vim.fn.readfile(file2_path), "\n")
			local file3_content = table.concat(vim.fn.readfile(file3_path), "\n")

			assert.is_not_nil(file1_content:find("[[primary-topic]]", 1, true))
			assert.is_not_nil(file2_content:find("[[primary-topic|Main Topic Page]]", 1, true))
			assert.is_not_nil(file3_content:find("[[primary-topic]]", 1, true))
			assert.is_not_nil(file3_content:find("[[primary-topic|the main topic]]", 1, true))

			-- Check notification mentions updating 3 files
			assert.is_true(#_G.notifications > 0)
			assert.is_not_nil(_G.notifications[#_G.notifications].message:match("updated 3 files"))
		end)

		it("prevents overwriting existing files", function()
			-- Create original note and target note
			local note_path = vault_path .. "/original.md"
			local existing_path = vault_path .. "/existing.md"

			vim.fn.writefile({ "# Original" }, note_path)
			vim.fn.writefile({ "# Existing" }, existing_path)

			-- Open original note
			vim.cmd("edit " .. note_path)

			-- Try to rename to existing file name
			links.rename_note("existing", { skip_ui = true })

			-- Check that original file was not renamed
			assert.is_true(vim.fn.filereadable(note_path) == 1)
			assert.is_true(vim.fn.filereadable(existing_path) == 1)

			-- Check error notification
			assert.is_true(#_G.notifications > 0)
			local found_error = false
			for _, notification in ipairs(_G.notifications) do
				if notification.message:match("File already exists") then
					found_error = true
					break
				end
			end
			assert.is_true(found_error)
		end)

		it("handles notes in subdirectories", function()
			-- Create subdirectory and note
			local subdir = vault_path .. "/projects"
			vim.fn.mkdir(subdir, "p")
			local note_path = subdir .. "/project-a.md"
			local linking_note_path = vault_path .. "/index.md"

			vim.fn.writefile({ "# Project A" }, note_path)
			vim.fn.writefile({ "See [[projects/project-a]] for details" }, linking_note_path)

			-- Open the note
			vim.cmd("edit " .. note_path)

			-- Rename the note
			links.rename_note("alpha-project", { skip_ui = true })

			-- Check file was renamed in same directory
			assert.is_true(vim.fn.filereadable(subdir .. "/alpha-project.md") == 1)
			assert.is_true(vim.fn.filereadable(note_path) == 0)

			-- Check link was updated with correct path
			local linking_content = table.concat(vim.fn.readfile(linking_note_path), "\n")
			assert.is_not_nil(linking_content:find("[[projects/alpha-project]]", 1, true))
			assert.is_nil(linking_content:find("[[projects/project-a]]", 1, true))
		end)

		it("strips .md extension from new name", function()
			-- Create a test note
			local note_path = vault_path .. "/test.md"
			vim.fn.writefile({ "# Test" }, note_path)

			-- Open the note
			vim.cmd("edit " .. note_path)

			-- Rename with .md extension
			links.rename_note("new-name.md", { skip_ui = true })

			-- Check that file was renamed without double extension
			assert.is_true(vim.fn.filereadable(vault_path .. "/new-name.md") == 1)
			assert.is_true(vim.fn.filereadable(vault_path .. "/new-name.md.md") == 0)
		end)

		it("handles similar note names without partial matches", function()
			-- Create notes with similar names
			local note_path = vault_path .. "/project.md"
			local similar_note_path = vault_path .. "/project-archive.md"
			local linking_note_path = vault_path .. "/index.md"

			vim.fn.writefile({ "# Project" }, note_path)
			vim.fn.writefile({ "# Project Archive" }, similar_note_path)
			vim.fn.writefile({
				"# Index",
				"See [[project]] for current work",
				"See [[project-archive]] for old work",
			}, linking_note_path)

			-- Verify initial state
			local initial_content = table.concat(vim.fn.readfile(linking_note_path), "\n")
			assert.is_not_nil(initial_content:find("[[project]]", 1, true))
			assert.is_not_nil(initial_content:find("[[project-archive]]", 1, true))

			-- Open and rename the "project" note
			vim.cmd("edit " .. note_path)
			links.rename_note("main-project", { skip_ui = true })

			-- Check that files were renamed correctly
			assert.is_true(vim.fn.filereadable(vault_path .. "/main-project.md") == 1)
			assert.is_true(vim.fn.filereadable(note_path) == 0)
			assert.is_true(vim.fn.filereadable(similar_note_path) == 1) -- Should still exist

			-- Check that links were updated correctly
			local final_content = table.concat(vim.fn.readfile(linking_note_path), "\n")

			-- Should find the new link
			assert.is_not_nil(final_content:find("[[main-project]]", 1, true))

			-- Should NOT find the old exact link
			assert.is_nil(final_content:find("[[project]]", 1, true))

			-- Should still have the similar link UNCHANGED
			assert.is_not_nil(final_content:find("[[project-archive]]", 1, true))

			-- Verify the similar link wasn't corrupted
			assert.is_nil(final_content:find("[[main-project-archive]]", 1, true))
		end)

		it("handles very similar note names correctly", function()
			-- Test even trickier edge cases
			local note_path = vault_path .. "/api.md"
			local linking_note_path = vault_path .. "/docs.md"

			vim.fn.writefile({ "# API" }, note_path)
			vim.fn.writefile({
				"Links: [[api]], [[api-docs]], [[api-v2]], [[legacy-api]]",
			}, linking_note_path)

			-- Open and rename
			vim.cmd("edit " .. note_path)
			links.rename_note("new-api", { skip_ui = true })

			-- Check final content
			local final_content = table.concat(vim.fn.readfile(linking_note_path), "\n")

			-- Only the exact match should be replaced
			assert.is_not_nil(final_content:find("[[new-api]]", 1, true))
			assert.is_not_nil(final_content:find("[[api-docs]]", 1, true))
			assert.is_not_nil(final_content:find("[[api-v2]]", 1, true))
			assert.is_not_nil(final_content:find("[[legacy-api]]", 1, true))

			-- The old exact link should be gone
			assert.is_nil(final_content:find("[[api]]", 1, true))
		end)

		it("handles files with spaces in names", function()
			-- Create notes with spaces in filenames
			local note_path = vault_path .. "/my project.md"
			local linking_note_path = vault_path .. "/index.md"

			vim.fn.writefile({ "# My Project" }, note_path)
			vim.fn.writefile({ "See [[my project]] for details" }, linking_note_path)

			-- Open and rename
			vim.cmd("edit " .. vim.fn.fnameescape(note_path))
			links.rename_note("new project name", { skip_ui = true })

			-- Check results
			assert.is_true(vim.fn.filereadable(vault_path .. "/new project name.md") == 1)
			assert.is_true(vim.fn.filereadable(note_path) == 0)

			local final_content = table.concat(vim.fn.readfile(linking_note_path), "\n")
			assert.is_not_nil(final_content:find("[[new project name]]", 1, true))
			assert.is_nil(final_content:find("[[my project]]", 1, true))
		end)

		it("handles empty or whitespace-only names gracefully", function()
			local note_path = vault_path .. "/test.md"
			vim.fn.writefile({ "# Test" }, note_path)
			vim.cmd("edit " .. note_path)

			-- Clear notifications
			_G.notifications = {}

			-- Test empty string
			links.rename_note("", { skip_ui = true })
			assert.is_true(vim.fn.filereadable(note_path) == 1) -- Should still exist

			-- Test whitespace only
			links.rename_note("   ", { skip_ui = true })
			assert.is_true(vim.fn.filereadable(note_path) == 1) -- Should still exist

			-- Should have error notifications
			local found_error = false
			for _, notification in ipairs(_G.notifications) do
				if notification.level == vim.log.levels.ERROR then
					found_error = true
					break
				end
			end
			assert.is_true(found_error)
		end)

		it("handles invalid filename characters", function()
			local note_path = vault_path .. "/test.md"
			vim.fn.writefile({ "# Test" }, note_path)
			vim.cmd("edit " .. note_path)

			-- Clear notifications
			_G.notifications = {}

			-- Test invalid characters
			links.rename_note("test/invalid", { skip_ui = true })
			links.rename_note("test\\invalid", { skip_ui = true })
			links.rename_note("test:invalid", { skip_ui = true })

			-- File should still exist since rename should fail
			assert.is_true(vim.fn.filereadable(note_path) == 1)

			-- Should have error notifications
			local found_error = false
			for _, notification in ipairs(_G.notifications) do
				if notification.level == vim.log.levels.ERROR and notification.message:find("invalid characters") then
					found_error = true
					break
				end
			end
			assert.is_true(found_error)
		end)

		it("handles no current file gracefully", function()
			-- Clear current buffer
			vim.cmd("enew")

			-- Should handle gracefully without crashing
			links.rename_note("test", { skip_ui = true })

			-- Check for appropriate notification
			assert.is_true(#_G.notifications > 0)
			local found_warning = false
			for _, notification in ipairs(_G.notifications) do
				if notification.message:find("No current file") then
					found_warning = true
					break
				end
			end
			assert.is_true(found_warning)
		end)

		it("respects show_rename_preview config option", function()
			-- Create a note with links
			local note_path = vault_path .. "/original-note.md"
			local linking_note_path = vault_path .. "/linking-note.md"

			vim.fn.writefile({ "# Original Note" }, note_path)
			vim.fn.writefile({ "Link to [[original-note]]" }, linking_note_path)

			-- Test with show_rename_preview = false
			local original_config = config.get_current_config()
			local test_config = vim.deepcopy(original_config)
			test_config.ui = test_config.ui or {}
			test_config.ui.show_rename_preview = false

			-- Mock the config to return our test config
			local original_get_config = config.get_current_config
			config.get_current_config = function()
				return test_config
			end

			vim.cmd("edit " .. note_path)

			-- This should use simple confirmation, not fzf-lua preview
			-- Since we're using skip_ui=true, it should still work
			links.rename_note("renamed-note", { skip_ui = true })

			-- Verify the rename worked
			assert.is_true(vim.fn.filereadable(vault_path .. "/renamed-note.md") == 1)
			assert.is_true(vim.fn.filereadable(note_path) == 0)

			-- Verify the link was updated
			local updated_content = table.concat(vim.fn.readfile(linking_note_path), "\n")
			assert.is_not_nil(updated_content:find("[[renamed-note]]", 1, true))
			assert.is_nil(updated_content:find("[[original-note]]", 1, true))

			-- Restore original config
			config.get_current_config = original_get_config
		end)
	end)

	describe("follow_link", function()
		it("follows simple wikilinks", function()
			-- Create target note
			local target_path = vault_path .. "/target-note.md"
			vim.fn.writefile({ "# Target Note", "This is the target" }, target_path)

			-- Create source note with link
			local source_path = vault_path .. "/source-note.md"
			vim.fn.writefile({ "See [[target-note]] for details" }, source_path)

			-- Open source note and position cursor on link
			vim.cmd("edit " .. source_path)
			vim.api.nvim_win_set_cursor(0, { 1, 6 }) -- Position on "target-note"

			-- Follow the link
			links.follow_link()

			-- Check that we're now in the target file
			local current_file = vim.fn.expand("%:p")
			assert.are.equal(target_path, current_file)
		end)

		it("follows wikilinks with pipe separator display text", function()
			-- Create target note
			local target_path = vault_path .. "/long-filename.md"
			vim.fn.writefile({ "# Long Filename", "This is the target" }, target_path)

			-- Create source note with pipe-separated link
			local source_path = vault_path .. "/source-note.md"
			vim.fn.writefile({ "See [[long-filename|Short Title]] for details" }, source_path)

			-- Open source note and position cursor on link
			vim.cmd("edit " .. source_path)
			vim.api.nvim_win_set_cursor(0, { 1, 8 }) -- Position inside the link

			-- Follow the link
			links.follow_link()

			-- Check that we're now in the target file
			local current_file = vim.fn.expand("%:p")
			assert.are.equal(target_path, current_file)
		end)

		it("follows wikilinks with path and pipe separator", function()
			-- Create subdirectory and target note
			local subdir = vault_path .. "/projects"
			vim.fn.mkdir(subdir, "p")
			local target_path = subdir .. "/some-long-filename.md"
			vim.fn.writefile({ "# Some Long Filename", "This is the target" }, target_path)

			-- Create source note with pipe-separated link including path
			local source_path = vault_path .. "/source-note.md"
			vim.fn.writefile({ "Check [[projects/some-long-filename|Project Summary]] here" }, source_path)

			-- Open source note and position cursor on link
			vim.cmd("edit " .. source_path)
			vim.api.nvim_win_set_cursor(0, { 1, 15 }) -- Position inside the link

			-- Follow the link
			links.follow_link()

			-- Check that we're now in the target file
			local current_file = vim.fn.expand("%:p")
			assert.are.equal(target_path, current_file)
		end)

		it("handles multiple pipe separators correctly", function()
			-- Create target note
			local target_path = vault_path .. "/technical-doc.md"
			vim.fn.writefile({ "# Technical Doc", "Content here" }, target_path)

			-- Create source note with multiple pipes (only first one should be used as separator)
			local source_path = vault_path .. "/source-note.md"
			vim.fn.writefile({ "See [[technical-doc|Title | With | Pipes]] for info" }, source_path)

			-- Open source note and position cursor on link
			vim.cmd("edit " .. source_path)
			vim.api.nvim_win_set_cursor(0, { 1, 8 }) -- Position inside the link

			-- Follow the link
			links.follow_link()

			-- Check that we're now in the target file
			local current_file = vim.fn.expand("%:p")
			assert.are.equal(target_path, current_file)
		end)

		it("falls back to fuzzy search when exact file not found", function()
			-- Create target note with partial name match
			local target_path = vault_path .. "/very-long-filename.md"
			vim.fn.writefile({ "# Very Long Filename", "Content here" }, target_path)

			-- Create source note with partial link (should find via fuzzy search)
			local source_path = vault_path .. "/source-note.md"
			vim.fn.writefile({ "See [[long-filename]] for details" }, source_path)

			-- Open source note and position cursor on link
			vim.cmd("edit " .. source_path)
			vim.api.nvim_win_set_cursor(0, { 1, 8 }) -- Position inside the link

			-- Follow the link
			links.follow_link()

			-- Check that we found the file via fuzzy search
			local current_file = vim.fn.expand("%:p")
			assert.are.equal(target_path, current_file)
		end)

		it("shows warning when file not found", function()
			-- Create source note with link to non-existent file
			local source_path = vault_path .. "/source-note.md"
			vim.fn.writefile({ "See [[nonexistent-file]] for details" }, source_path)

			-- Clear notifications
			_G.notifications = {}

			-- Open source note and position cursor on link
			vim.cmd("edit " .. source_path)
			vim.api.nvim_win_set_cursor(0, { 1, 8 }) -- Position inside the link

			-- Follow the link
			links.follow_link()

			-- Check that we got a warning notification
			assert.is_true(#_G.notifications > 0)
			local found_warning = false
			for _, notification in ipairs(_G.notifications) do
				if notification.message:find("File not found") and notification.level == vim.log.levels.WARN then
					found_warning = true
					break
				end
			end
			assert.is_true(found_warning)
		end)

		it("handles cursor not on a link gracefully", function()
			-- Create source note without wikilinks but with a word that could be a filename
			local source_path = vault_path .. "/source-note.md"
			vim.fn.writefile({ "Check the README file for instructions" }, source_path)

			-- Create the README file so gf won't fail
			local readme_path = vault_path .. "/README"
			vim.fn.writefile({ "# Instructions" }, readme_path)

			-- Open source note and position cursor on "README"
			vim.cmd("edit " .. source_path)
			vim.api.nvim_win_set_cursor(0, { 1, 12 }) -- Position on "README"

			-- This should fall back to normal gf behavior and open README
			links.follow_link()

			-- Check that we're now in the README file (normal gf behavior)
			local current_file = vim.fn.expand("%:p")
			assert.are.equal(readme_path, current_file)
		end)
	end)
end)
