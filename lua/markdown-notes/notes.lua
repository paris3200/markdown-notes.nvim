local config = require("markdown-notes.config")

local M = {}

function M.create_new_note()
  local title = vim.fn.input("Note title: ")
  if title == "" then return end
  
  local filename = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
  local file_path = vim.fn.expand(config.options.vault_path .. "/" .. config.options.notes_subdir .. "/" .. filename .. ".md")
  
  -- Create directory if needed
  local dir = vim.fn.fnamemodify(file_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  
  vim.cmd("edit " .. file_path)
  
  -- Insert basic frontmatter
  local frontmatter = {
    "---",
    "title: " .. title,
    "date: " .. os.date("%Y-%m-%d"),
    "tags: []",
    "---",
    "",
    "# " .. title,
    "",
  }
  vim.api.nvim_buf_set_lines(0, 0, 0, false, frontmatter)
end

function M.find_notes()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  
  fzf.files({
    prompt = "Find Notes> ",
    cwd = vim.fn.expand(config.options.vault_path),
    find_opts = "-name '*.md' -type f -not -path '*/.*'",
  })
end

function M.search_notes()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  
  fzf.grep({
    prompt = "Search Notes> ",
    cwd = vim.fn.expand(config.options.vault_path),
  })
end

function M.search_tags()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  
  fzf.grep({
    prompt = "Search Tags> ",
    cwd = vim.fn.expand(config.options.vault_path),
    search = "#",
  })
end

return M