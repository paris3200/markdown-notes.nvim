local config = require("markdown-notes.config")

local M = {}

-- Helper function to insert a link at cursor position
local function insert_link_at_cursor(file_path)
	-- Normalize path by removing leading ./ if present
	local normalized_path = file_path:gsub("^%./", "")
	-- Remove .md extension but keep the full path
	local link_path = normalized_path:gsub("%.md$", "")
	local link = "[[" .. link_path .. "]]"

	-- Insert link at cursor
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line = vim.api.nvim_get_current_line()
	local new_line = line:sub(1, cursor_pos[2]) .. link .. line:sub(cursor_pos[2] + 1)
	vim.api.nvim_set_current_line(new_line)
	vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] + #link })
end

function M.search_and_link()
	local ok, fzf = pcall(require, "fzf-lua")
	if not ok then
		vim.notify("fzf-lua not available", vim.log.levels.ERROR)
		return
	end
	local options = config.get_current_config()

	fzf.files({
		prompt = "Link to Note> ",
		cwd = vim.fn.expand(options.vault_path),
		cmd = "find . -name '*.md' -type f -not -path '*/.*'",
		file_icons = false,
		path_shorten = false,
		formatter = nil,
		previewer = "builtin",
		actions = {
			["default"] = function(selected)
				if selected and #selected > 0 then
					local file_path = vim.fn.expand(options.vault_path .. "/" .. selected[1])
					vim.cmd("edit " .. vim.fn.fnameescape(file_path))
				end
			end,
			["ctrl-l"] = function(selected)
				if selected and #selected > 0 then
					insert_link_at_cursor(selected[1])
				end
			end,
		},
	})
end

function M.follow_link()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local options = config.get_current_config()

	-- Look for [[link]] pattern around cursor
	local link_start = line:sub(1, col + 1):find("%[%[[^%]]*$")
	if link_start then
		local link_end = line:find("%]%]", col + 1)
		if link_end then
			local link_text = line:sub(link_start + 2, link_end - 1)
			local file_path = vim.fn.expand(options.vault_path .. "/" .. link_text .. ".md")

			-- Try to find the file if exact match doesn't exist
			if vim.fn.filereadable(file_path) == 0 then
				local find_cmd = "find "
					.. vim.fn.expand(options.vault_path)
					.. " -name '*"
					.. link_text
					.. "*.md' -type f -not -path '*/.*'"
				local found_files = vim.fn.systemlist(find_cmd)
				if #found_files > 0 then
					file_path = found_files[1]
				end
			end

			if vim.fn.filereadable(file_path) == 1 then
				vim.cmd("edit " .. file_path)
			else
				vim.notify("File not found: " .. link_text, vim.log.levels.WARN)
			end
			return
		end
	end

	-- Fallback to default gf behavior
	vim.cmd("normal! gf")
end

function M.show_backlinks()
	local current_path = vim.fn.expand("%:p")
	local options = config.get_current_config()
	local vault_path = vim.fn.expand(options.vault_path)

	-- Get relative path from vault root and remove .md extension
	local relative_path = current_path:gsub("^" .. vim.pesc(vault_path) .. "/", ""):gsub("%.md$", "")

	if relative_path == "" then
		vim.notify("No current file", vim.log.levels.WARN)
		return
	end

	local ok, fzf = pcall(require, "fzf-lua")
	if not ok then
		vim.notify("fzf-lua not available", vim.log.levels.ERROR)
		return
	end

	-- Find files that contain links to this note
	local search_text = "[[" .. relative_path .. "]]"

	-- Get all markdown files first, then check each one
	local all_files_cmd = "cd " .. vim.fn.shellescape(vault_path) .. " && find . -name '*.md' -type f -not -path '*/.*'"
	local all_files = vim.fn.systemlist(all_files_cmd)

	-- Remove ./ prefix from paths
	for i, file in ipairs(all_files) do
		all_files[i] = file:gsub("^%./", "")
	end

	local linked_files = {}
	for _, file in ipairs(all_files) do
		local full_path = vault_path .. "/" .. file
		local file_content = vim.fn.readfile(full_path)
		local content_str = table.concat(file_content, "\n")

		-- Simple string search for the exact link
		if content_str:find(search_text, 1, true) then
			table.insert(linked_files, file)
		end

		-- Also check for links with display text (|)
		local link_with_display = "%[%[" .. vim.pesc(relative_path) .. "|"
		if content_str:find(link_with_display) then
			table.insert(linked_files, file)
		end
	end

	if #linked_files == 0 then
		vim.notify("No backlinks found for: " .. relative_path, vim.log.levels.INFO)
		return
	end

	fzf.fzf_exec(linked_files, {
		prompt = "Backlinks> ",
		cwd = vault_path,
		previewer = "builtin",
		actions = {
			["default"] = function(selected)
				if selected and #selected > 0 then
					local file_path = vim.fn.expand(options.vault_path .. "/" .. selected[1])
					vim.cmd("edit " .. vim.fn.fnameescape(file_path))
				end
			end,
			["ctrl-l"] = function(selected)
				if selected and #selected > 0 then
					insert_link_at_cursor(selected[1])
				end
			end,
		},
	})
end

function M.rename_note(new_name, opts)
	opts = opts or {}
	local current_path = vim.fn.expand("%:p")
	local options = config.get_current_config()
	local vault_path = vim.fn.expand(options.vault_path)

	-- Get current note info
	local relative_path = current_path:gsub("^" .. vim.pesc(vault_path) .. "/", ""):gsub("%.md$", "")
	local current_dir = vim.fn.expand("%:p:h")

	if relative_path == "" then
		vim.notify("No current file", vim.log.levels.WARN)
		return
	end

	-- Validate new name
	if not new_name or new_name == "" then
		vim.notify("New name cannot be empty", vim.log.levels.ERROR)
		return
	end

	-- Ensure new_name doesn't have .md extension
	new_name = new_name:gsub("%.md$", "")

	-- Check for whitespace-only names
	if new_name:match("^%s*$") then
		vim.notify("New name cannot be only whitespace", vim.log.levels.ERROR)
		return
	end

	-- Check for invalid filename characters (basic check)
	if new_name:match('[/\\:*?"<>|]') then
		vim.notify("New name contains invalid characters", vim.log.levels.ERROR)
		return
	end

	-- Create new file path
	local new_file_path = current_dir .. "/" .. new_name .. ".md"

	-- Check if target file already exists
	if vim.fn.filereadable(new_file_path) == 1 then
		vim.notify("File already exists: " .. new_name .. ".md", vim.log.levels.ERROR)
		return
	end

	-- Find all files that link to this note
	local search_text = "[[" .. relative_path .. "]]"
	local link_with_display = "%[%[" .. vim.pesc(relative_path) .. "|"

	-- Get all markdown files
	local all_files_cmd = "cd " .. vim.fn.shellescape(vault_path) .. " && find . -name '*.md' -type f -not -path '*/.*'"
	local all_files = vim.fn.systemlist(all_files_cmd)

	-- Remove ./ prefix from paths
	for i, file in ipairs(all_files) do
		all_files[i] = file:gsub("^%./", "")
	end

	local files_to_update = {}
	local update_count = 0

	-- Find files with links to update
	for _, file in ipairs(all_files) do
		local full_path = vault_path .. "/" .. file
		local file_content = vim.fn.readfile(full_path)
		local content_str = table.concat(file_content, "\n")
		local updated = false

		-- Check for exact link matches
		if content_str:find(search_text, 1, true) then
			updated = true
		end

		-- Check for display text links
		if content_str:find(link_with_display) then
			updated = true
		end

		if updated then
			table.insert(files_to_update, { file = file, path = full_path })
		end
	end

	-- Get new relative path for links
	local current_dir_relative = current_dir:gsub("^" .. vim.pesc(vault_path) .. "/?", "")
	local new_relative_path
	if current_dir_relative == "" then
		-- File is in vault root
		new_relative_path = new_name
	else
		-- File is in subdirectory
		new_relative_path = current_dir_relative .. "/" .. new_name
	end

	-- Show affected files and ask for confirmation
	if #files_to_update > 0 and not opts.skip_ui and options.ui.show_rename_preview then
		local ok, fzf = pcall(require, "fzf-lua")
		if not ok then
			vim.notify("fzf-lua not available", vim.log.levels.ERROR)
			return
		end

		-- Show files that will be updated
		local file_list = {}
		for _, file_info in ipairs(files_to_update) do
			table.insert(file_list, file_info.file)
		end

		fzf.fzf_exec(file_list, {
			prompt = "Files to update (" .. #files_to_update .. ") - Enter to rename, Esc to cancel > ",
			cwd = vault_path,
			previewer = "builtin",
			actions = {
				["default"] = function()
					-- Proceed with rename directly (preview was the confirmation)
					M._perform_rename(
						current_path,
						new_file_path,
						files_to_update,
						relative_path,
						new_relative_path,
						update_count
					)
				end,
			},
		})
	else
		-- Skip UI for tests or when no files to update
		local message = "Rename '" .. relative_path .. "' to '" .. new_name .. "'"
		if #files_to_update > 0 then
			message = message .. " and update " .. #files_to_update .. " files?"
		else
			message = message .. "?"
		end
		local confirm = opts.skip_ui and 1 or vim.fn.confirm(message, "&Yes\n&No", 2)
		if confirm == 1 then
			M._perform_rename(
				current_path,
				new_file_path,
				files_to_update,
				relative_path,
				new_relative_path,
				update_count
			)
		end
	end
end

-- Helper function to perform the actual rename operation
function M._perform_rename(current_path, new_file_path, files_to_update, relative_path, new_relative_path, update_count)
	-- Check if we're renaming the current buffer's file (before renaming)
	local current_bufnr = vim.fn.bufnr("%")
	local is_current_buffer = current_bufnr ~= -1 and vim.fn.expand("%:p") == current_path

	-- Update all linking files
	for _, file_info in ipairs(files_to_update) do
		local file_content = vim.fn.readfile(file_info.path)
		local content_str = table.concat(file_content, "\n")

		-- Replace exact links using simple string replacement
		local old_link = "[[" .. relative_path .. "]]"
		local new_link = "[[" .. new_relative_path .. "]]"
		content_str = content_str:gsub(vim.pesc(old_link), new_link)

		-- Replace display text links
		local old_display_pattern = "(%[%[)" .. vim.pesc(relative_path) .. "(%|[^%]]*%]%])"
		local new_display_replacement = "%1" .. new_relative_path .. "%2"
		content_str = content_str:gsub(old_display_pattern, new_display_replacement)

		-- Write updated content
		local updated_lines = vim.split(content_str, "\n")
		vim.fn.writefile(updated_lines, file_info.path)
		update_count = update_count + 1
	end

	-- Rename the actual file
	local success = vim.fn.rename(current_path, new_file_path)
	if success == 0 then
		-- Handle buffer management if we renamed the current buffer's file
		if is_current_buffer then
			-- Update the buffer's filename to the new path
			-- Use pcall to handle E95 error if buffer name already exists
			local success_rename = pcall(vim.api.nvim_buf_set_name, current_bufnr, new_file_path)
			if not success_rename then
				-- If buffer name collision, force close conflicting buffer and retry
				local conflicting_bufnr = vim.fn.bufnr(new_file_path)
				if conflicting_bufnr ~= -1 then
					vim.cmd("bwipeout! " .. conflicting_bufnr)
					vim.api.nvim_buf_set_name(current_bufnr, new_file_path)
				end
			end
			-- Reload the buffer to reflect the new filename
			vim.cmd("edit!")
		end
		if update_count > 0 then
			vim.notify("Renamed note and updated " .. update_count .. " files", vim.log.levels.INFO)
		else
			vim.notify("Renamed note (no links to update)", vim.log.levels.INFO)
		end
	else
		vim.notify("Failed to rename file", vim.log.levels.ERROR)
	end
end

return M
