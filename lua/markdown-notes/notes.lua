local config = require("markdown-notes.config")

local M = {}

function M.create_new_note()
  local title = vim.fn.input("Note title (optional): ")
  
  -- Generate timestamp-based filename
  local timestamp = tostring(os.time())
  local filename = timestamp
  if title ~= "" then
    local clean_title = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
    filename = timestamp .. "-" .. clean_title
  end
  
  local file_path = vim.fn.expand(config.options.vault_path .. "/" .. config.options.notes_subdir .. "/" .. filename .. ".md")
  
  -- Create directory if needed
  local dir = vim.fn.fnamemodify(file_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  
  vim.cmd("edit " .. file_path)
  
  -- Insert basic frontmatter
  local display_title = title ~= "" and title or "Untitled"
  local frontmatter = {
    "---",
    "title: " .. display_title,
    "date: " .. os.date("%Y-%m-%d"),
    "tags: []",
    "---",
    "",
    "# " .. display_title,
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
    cmd = "find . -name '*.md' -type f -not -path '*/.*'",
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