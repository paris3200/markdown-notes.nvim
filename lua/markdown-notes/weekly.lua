local config = require("markdown-notes.config")
local templates = require("markdown-notes.templates")

local M = {}

-- Calculate ISO week number and year for a given timestamp
-- ISO weeks start on Monday and the first week of the year is the one containing the first Thursday
local function get_iso_week(timestamp)
	timestamp = timestamp or os.time()
	local date = os.date("*t", timestamp)

	-- Get day of week (1=Monday, 7=Sunday)
	local dow = (date.wday + 5) % 7 + 1

	-- Find Thursday of the current week
	local thursday = timestamp + (4 - dow) * 86400
	local thursday_date = os.date("*t", thursday)

	-- Get January 4th of the same year (always in week 1)
	local jan4 = os.time({year = thursday_date.year, month = 1, day = 4, hour = 12})
	local jan4_date = os.date("*t", jan4)
	local jan4_dow = (jan4_date.wday + 5) % 7 + 1

	-- Find Monday of week 1
	local week1_monday = jan4 - (jan4_dow - 1) * 86400

	-- Calculate week number
	local week = math.floor((thursday - week1_monday) / (7 * 86400)) + 1

	return week, thursday_date.year
end

function M.open_weekly_note(offset)
	offset = offset or 0
	local timestamp = os.time() + (offset * 7 * 86400) -- offset in weeks
	local week, year = get_iso_week(timestamp)

	local options = config.get_current_config()
	local filename = string.format("W%02d-%d-Weekly-Review.md", week, year)
	local file_path = vim.fn.expand(options.weekly_path .. "/" .. filename)

	-- Create directory if it doesn't exist
	local dir = vim.fn.fnamemodify(file_path, ":h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end

	-- Create file with template if it doesn't exist
	if vim.fn.filereadable(file_path) == 0 then
		local template_path = vim.fn.expand(options.templates_path .. "/Weekly.md")
		if vim.fn.filereadable(template_path) == 1 then
			local template_content = vim.fn.readfile(template_path)
			local custom_vars = {
				week_number = string.format("%02d", week),
				week_year = tostring(year),
				week_id = string.format("W%02d-%d", week, year),
				title = string.format("Week %d, %d", week, year),
				date = os.date("%Y-%m-%d", timestamp),
				datetime = os.date("%Y-%m-%d %H:%M", timestamp),
			}
			template_content = templates.substitute_template_vars(template_content, custom_vars)
			vim.fn.writefile(template_content, file_path)
		end
	end

	vim.cmd("edit " .. file_path)
end

return M
