local config = require("markdown-notes.config")
local templates = require("markdown-notes.templates")

local M = {}

function M.open_daily_note(offset)
  offset = offset or 0
  local date = os.date("%Y-%m-%d", os.time() + (offset * 86400))
  local file_path = vim.fn.expand(config.options.dailies_path .. "/" .. date .. ".md")
  
  -- Create directory if it doesn't exist
  local dir = vim.fn.fnamemodify(file_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  
  -- Create file with template if it doesn't exist
  if vim.fn.filereadable(file_path) == 0 then
    local template_path = vim.fn.expand(config.options.templates_path .. "/Daily.md")
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