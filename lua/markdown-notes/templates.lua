local config = require("markdown-notes.config")
local picker = require("markdown-notes.picker")

local M = {}

function M.substitute_template_vars(content, custom_vars)
	local options = config.get_current_config()
	-- Fallback to config.options if no workspace config available
	if not options then
		options = config.options
	end
	local template_vars = options.template_vars or config.defaults.template_vars
	local vars = {}

	-- Manual merge since vim.tbl_extend might not be available in tests
	for k, v in pairs(template_vars) do
		vars[k] = v
	end

	if custom_vars then
		for k, v in pairs(custom_vars) do
			vars[k] = v
		end
	end

	for i, line in ipairs(content) do
		for var_name, var_func in pairs(vars) do
			local pattern = "{{" .. var_name .. "}}"
			local replacement = type(var_func) == "function" and var_func() or var_func
			content[i] = string.gsub(content[i], pattern, replacement)
		end
	end

	return content
end

function M.insert_template(template_name, custom_vars)
	local options = config.get_current_config()
	if not options then
		options = config.options
	end
	local template_path = vim.fn.expand(options.templates_path .. "/" .. template_name .. ".md")

	if vim.fn.filereadable(template_path) == 0 then
		vim.notify("Template not found: " .. template_path, vim.log.levels.ERROR)
		return
	end

	local template_content = vim.fn.readfile(template_path)
	template_content = M.substitute_template_vars(template_content, custom_vars)

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	vim.api.nvim_buf_set_lines(0, cursor_pos[1] - 1, cursor_pos[1] - 1, false, template_content)
end

function M.apply_template_to_file(template_name, custom_vars)
	local options = config.get_current_config()
	if not options then
		options = config.options
	end
	local template_path = vim.fn.expand(options.templates_path .. "/" .. template_name .. ".md")

	if vim.fn.filereadable(template_path) == 0 then
		vim.notify("Template not found: " .. template_path, vim.log.levels.ERROR)
		return false
	end

	local template_content = vim.fn.readfile(template_path)
	template_content = M.substitute_template_vars(template_content, custom_vars)

	-- Replace entire buffer content
	vim.api.nvim_buf_set_lines(0, 0, -1, false, template_content)
	return true
end

function M.pick_template()
	local options = config.get_current_config()
	if not options then
		options = config.options
	end

	picker.files({
		title = "Select Template",
		cwd = vim.fn.expand(options.templates_path),
		actions = {
			["default"] = function(selected)
				M.insert_template(vim.fn.fnamemodify(selected, ":t:r"))
			end,
		},
	})
end

return M
