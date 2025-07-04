local config = require("markdown-notes.config")

local M = {}

function M.search_and_link()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  
  fzf.files({
    prompt = "Link to Note> ",
    cwd = vim.fn.expand(config.options.vault_path),
    find_opts = "-name '*.md' -type f",
    actions = {
      ["default"] = function(selected)
        fzf.actions.file_edit(selected)
      end,
      ["ctrl-l"] = function(selected)
        if selected and #selected > 0 then
          local filename = vim.fn.fnamemodify(selected[1], ":t:r")
          local link = "[[" .. filename .. "]]"
          
          -- Insert link at cursor
          local cursor_pos = vim.api.nvim_win_get_cursor(0)
          local line = vim.api.nvim_get_current_line()
          local new_line = line:sub(1, cursor_pos[2]) .. link .. line:sub(cursor_pos[2] + 1)
          vim.api.nvim_set_current_line(new_line)
          vim.api.nvim_win_set_cursor(0, {cursor_pos[1], cursor_pos[2] + #link})
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
        local find_cmd = "find " .. vim.fn.expand(config.options.vault_path) .. " -name '*" .. link_text .. "*.md' -type f"
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
  local current_file = vim.fn.expand("%:t:r")
  if current_file == "" then
    vim.notify("No current file", vim.log.levels.WARN)
    return
  end
  
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  
  fzf.grep({
    prompt = "Backlinks> ",
    cwd = vim.fn.expand(config.options.vault_path),
    search = "\\[\\[" .. current_file .. "\\]\\]",
  })
end

return M