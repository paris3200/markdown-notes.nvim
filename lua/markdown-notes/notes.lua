local config = require("markdown-notes.config")
local templates = require("markdown-notes.templates")

local M = {}

function M.create_new_note()
  local title = vim.fn.input("Note title (optional): ")
  local options = config.get_current_config()
  
  -- Generate timestamp-based filename
  local timestamp = tostring(os.time())
  local filename = timestamp
  if title ~= "" then
    local clean_title = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
    filename = timestamp .. "-" .. clean_title
  end
  
  local file_path = vim.fn.expand(options.vault_path .. "/" .. options.notes_subdir .. "/" .. filename .. ".md")
  
  -- Create directory if needed
  local dir = vim.fn.fnamemodify(file_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  
  vim.cmd("edit " .. file_path)
  
  local display_title = title ~= "" and title or "Untitled"
  
  -- Use default template if configured, otherwise use basic frontmatter
  if options.default_template then
    local custom_vars = {
      title = display_title,
      note_title = display_title,
    }
    if not templates.apply_template_to_file(options.default_template, custom_vars) then
      -- Fall back to basic frontmatter if template fails
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
  else
    -- Insert basic frontmatter
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
end

function M.create_from_template()
  local title = vim.fn.input("Note title (optional): ")
  local options = config.get_current_config()
  
  -- Generate timestamp-based filename
  local timestamp = tostring(os.time())
  local filename = timestamp
  if title ~= "" then
    local clean_title = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
    filename = timestamp .. "-" .. clean_title
  end
  
  local file_path = vim.fn.expand(options.vault_path .. "/" .. options.notes_subdir .. "/" .. filename .. ".md")
  
  -- Create directory if needed
  local dir = vim.fn.fnamemodify(file_path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  
  vim.cmd("edit " .. file_path)
  
  local display_title = title ~= "" and title or "Untitled"
  
  -- Let user pick a template
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  
  fzf.files({
    prompt = "Select Template> ",
    cwd = vim.fn.expand(options.templates_path),
    cmd = "find . -name '*.md' -type f -not -path '*/.*' -printf '%P\\n'",
    file_icons = false,
    path_shorten = false,
    formatter = nil,
    previewer = "builtin",
    actions = {
      ["default"] = function(selected)
        if selected and #selected > 0 then
          local template_name = vim.fn.fnamemodify(selected[1], ":t:r")
          local custom_vars = {
            title = display_title,
            note_title = display_title,
          }
          templates.apply_template_to_file(template_name, custom_vars)
        end
      end,
    },
  })
end

function M.find_notes()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  local options = config.get_current_config()
  
  fzf.files({
    prompt = "Find Notes> ",
    cwd = vim.fn.expand(options.vault_path),
    cmd = "find . -name '*.md' -type f -not -path '*/.*' -printf '%P\\n'",
    previewer = "builtin",
  })
end

function M.search_notes()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  local options = config.get_current_config()
  
  fzf.grep({
    prompt = "Search Notes> ",
    cwd = vim.fn.expand(options.vault_path),
    previewer = "builtin",
  })
end

function M.search_tags()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua not available", vim.log.levels.ERROR)
    return
  end
  local options = config.get_current_config()
  
  local vault_path = vim.fn.expand(options.vault_path)
  
  -- Get all markdown files
  local find_cmd = "find " .. vim.fn.shellescape(vault_path) .. " -name '*.md' -type f -not -path '*/.*'"
  local all_files = vim.fn.systemlist(find_cmd)
  
  -- Extract all tags from frontmatter
  local tags = {}
  for _, file in ipairs(all_files) do
    local content = vim.fn.readfile(file)
    local in_frontmatter = false
    
    for _, line in ipairs(content) do
      if line == "---" then
        in_frontmatter = not in_frontmatter
      elseif in_frontmatter and line:match("^tags:") then
        -- Extract tags from YAML array format: tags: [tag1, tag2, tag3]
        local tags_line = line:gsub("^tags:%s*", "")
        if tags_line:match("^%[.*%]$") then
          -- Remove brackets and split by comma
          local tags_content = tags_line:gsub("^%[", ""):gsub("%]$", "")
          for tag in tags_content:gmatch("[^,]+") do
            local clean_tag = tag:gsub("%s", ""):gsub('"', ''):gsub("'", "")
            if clean_tag ~= "" then
              if not tags[clean_tag] then
                tags[clean_tag] = {}
              end
              table.insert(tags[clean_tag], file)
            end
          end
        end
        break -- Only process first tags line in frontmatter
      end
    end
  end
  
  -- Convert tags table to list for fzf
  local tag_list = {}
  for tag, files in pairs(tags) do
    table.insert(tag_list, tag .. " (" .. #files .. " files)")
  end
  
  if #tag_list == 0 then
    vim.notify("No tags found in frontmatter", vim.log.levels.INFO)
    return
  end
  
  fzf.fzf_exec(tag_list, {
    prompt = "Search Tags> ",
    actions = {
      ["default"] = function(selected)
        if selected and #selected > 0 then
          local tag = selected[1]:match("^([^%(]+)")
          tag = tag:gsub("%s+$", "") -- trim trailing whitespace
          local files_with_tag = tags[tag]
          
          if files_with_tag and #files_with_tag > 0 then
            -- Show files with this tag
            local relative_files = {}
            for _, file in ipairs(files_with_tag) do
              local relative = file:gsub("^" .. vim.pesc(vault_path) .. "/", "")
              table.insert(relative_files, relative)
            end
            
            fzf.fzf_exec(relative_files, {
              prompt = "Files with tag '" .. tag .. "'> ",
              cwd = vault_path,
              previewer = "builtin",
              actions = {
                ["default"] = function(file_selected)
                  if file_selected and #file_selected > 0 then
                    local file_path = vim.fn.expand(vault_path .. "/" .. file_selected[1])
                    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
                  end
                end,
              },
            })
          end
        end
      end,
    },
  })
end

return M