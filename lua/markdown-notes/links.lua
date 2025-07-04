local config = require("markdown-notes.config")

local M = {}

-- Helper function to insert a link at cursor position
local function insert_link_at_cursor(file_path)
  -- Remove .md extension but keep the full path
  local link_path = file_path:gsub("%.md$", "")
  local link = "[[" .. link_path .. "]]"
  
  -- Insert link at cursor
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, cursor_pos[2]) .. link .. line:sub(cursor_pos[2] + 1)
  vim.api.nvim_set_current_line(new_line)
  vim.api.nvim_win_set_cursor(0, {cursor_pos[1], cursor_pos[2] + #link})
end

function M.search_and_link()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  
  fzf.files({
    prompt = "Link to Note> ",
    cwd = vim.fn.expand(config.options.vault_path),
    cmd = "find . -name '*.md' -type f -not -path '*/.*'",
    file_icons = false,
    path_shorten = false,
    formatter = nil,
    previewer = "builtin",
    actions = {
      ["default"] = function(selected)
        if selected and #selected > 0 then
          local file_path = vim.fn.expand(config.options.vault_path .. "/" .. selected[1])
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
  
  -- Look for [[link]] pattern around cursor
  local link_start = line:sub(1, col + 1):find("%[%[[^%]]*$")
  if link_start then
    local link_end = line:find("%]%]", col + 1)
    if link_end then
      local link_text = line:sub(link_start + 2, link_end - 1)
      local file_path = vim.fn.expand(config.options.vault_path .. "/" .. link_text .. ".md")
      
      -- Try to find the file if exact match doesn't exist
      if vim.fn.filereadable(file_path) == 0 then
        local find_cmd = "find " .. vim.fn.expand(config.options.vault_path) .. " -name '*" .. link_text .. "*.md' -type f -not -path '*/.*'"
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
  local vault_path = vim.fn.expand(config.options.vault_path)
  
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
  local all_files_cmd = "cd " .. vim.fn.shellescape(vault_path) .. " && find . -name '*.md' -type f -not -path '*/.*' -printf '%P\\n'"
  local all_files = vim.fn.systemlist(all_files_cmd)
  
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
          local file_path = vim.fn.expand(config.options.vault_path .. "/" .. selected[1])
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

return M