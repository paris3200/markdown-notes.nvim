local config = require("markdown-notes.config")
local templates = require("markdown-notes.templates")

local M = {}

local function run_daily_note_command(command, date, file_path)
	local args = {}
	for i, arg in ipairs(command) do
		arg = arg:gsub("{{date}}", function()
			return date
		end)
		args[i] = i == 1 and vim.fn.expand(arg) or arg
	end

	local output = vim.fn.system(args)
	if vim.v.shell_error ~= 0 or vim.fn.filereadable(file_path) == 0 then
		vim.notify(
			"daily_note_command did not create " .. file_path .. ", using template instead\n" .. output,
			vim.log.levels.WARN
		)
	end
end

function M.open_daily_note(offset)
	offset = offset or 0
	local date = os.date("%Y-%m-%d", os.time() + (offset * 86400))
	local options = config.get_current_config()
	-- "{{year}}" in dailies_path is the note's year, so notes land in per-year folders
	local dailies_path = options.dailies_path:gsub("{{year}}", date:sub(1, 4))
	local file_path = vim.fn.expand(dailies_path .. "/" .. date .. ".md")

	-- Create directory if it doesn't exist
	local dir = vim.fn.fnamemodify(file_path, ":h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end

	if vim.fn.filereadable(file_path) == 0 and options.daily_note_command then
		run_daily_note_command(options.daily_note_command, date, file_path)
	end

	-- Create file with template if it doesn't exist
	if vim.fn.filereadable(file_path) == 0 then
		local template_path = vim.fn.expand(options.templates_path .. "/Daily.md")
		if vim.fn.filereadable(template_path) == 1 then
			local template_content = vim.fn.readfile(template_path)
			local custom_vars = {
				date = date,
				title = date,
				datetime = date .. " " .. os.date("%H:%M"),
			}
			template_content = templates.substitute_template_vars(template_content, custom_vars)
			vim.fn.writefile(template_content, file_path)
		end
	end

	vim.cmd("edit " .. file_path)
end

return M
