local M = {}

-- List item prefixes that can hold a checkbox: bullets (-, *, +) and numbered items (1.)
local checkbox_patterns = {
	"^(%s*[-*+]%s+%[)([ xX])(%])",
	"^(%s*%d+%.%s+%[)([ xX])(%])",
}

-- Returns the line with its checkbox flipped, or nil if it has no checkbox
local function toggle_line(line)
	for _, pattern in ipairs(checkbox_patterns) do
		local prefix, mark = line:match(pattern)
		if prefix then
			local new_mark = mark == " " and "x" or " "
			return prefix .. new_mark .. line:sub(#prefix + 2)
		end
	end
	return nil
end

function M.toggle_checkbox(start_line, end_line)
	-- Use the visual selection when called from visual mode, otherwise the current line
	if not start_line then
		local mode = vim.fn.mode()
		if mode == "v" or mode == "V" or mode == "\22" then
			start_line, end_line = vim.fn.line("v"), vim.fn.line(".")
			if start_line > end_line then
				start_line, end_line = end_line, start_line
			end
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
		else
			start_line = vim.fn.line(".")
		end
	end
	end_line = end_line or start_line

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local changed = false
	for i, line in ipairs(lines) do
		local new_line = toggle_line(line)
		if new_line then
			lines[i] = new_line
			changed = true
		end
	end

	if changed then
		vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
		vim.api.nvim_win_set_cursor(0, cursor_pos)
	end
end

return M
