local M = {}

M.defaults = {
  vault_path = "~/repos/notes",
  templates_path = "~/repos/notes/sys/templates",
  dailies_path = "~/repos/notes/personal/dailies/2025",
  weekly_path = "~/repos/notes/personal/weekly",
  notes_subdir = "notes",
  default_template = nil, -- Optional default template for new notes
  
  -- Template substitution variables
  template_vars = {
    date = function() return os.date("%Y-%m-%d") end,
    time = function() return os.date("%H:%M") end,
    datetime = function() return os.date("%Y-%m-%d %H:%M") end,
    title = function() return vim.fn.expand("%:t:r") end,
    yesterday = function() return os.date("%Y-%m-%d", os.time() - 86400) end,
    tomorrow = function() return os.date("%Y-%m-%d", os.time() + 86400) end,
  },
  
  -- Default workspace (optional)
  default_workspace = nil,
  
  -- Key mappings
  mappings = {
    daily_note_today = "<leader>nd",
    daily_note_yesterday = "<leader>ny", 
    daily_note_tomorrow = "<leader>nt",
    new_note = "<leader>nn",
    new_note_from_template = "<leader>nc",
    find_notes = "<leader>nf",
    search_notes = "<leader>ns",
    insert_link = "<leader>nl",
    insert_template = "<leader>np",
    search_tags = "<leader>ng",
    show_backlinks = "<leader>nb",
    follow_link = "gf",
    rename_note = "<leader>nr",
    pick_workspace = "<leader>nw",
  },
}

M.workspaces = {}
M.default_workspace = nil
M.current_active_workspace = nil
M.options = {}

local function deep_extend(target, source)
  for k, v in pairs(source) do
    if type(v) == "table" and type(target[k]) == "table" then
      deep_extend(target[k], v)
    else
      target[k] = v
    end
  end
  return target
end

function M.setup(opts)
  if vim and vim.tbl_deep_extend then
    M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  else
    -- Fallback for test environment
    M.options = {}
    for k, v in pairs(M.defaults) do
      M.options[k] = v
    end
    if opts then
      deep_extend(M.options, opts)
    end
  end
  
  -- Set default workspace if specified in config
  if M.options.default_workspace then
    M.default_workspace = M.options.default_workspace
  end
end

function M.setup_workspace(name, opts)
  local workspace_config
  if vim and vim.tbl_deep_extend then
    workspace_config = vim.tbl_deep_extend("force", M.defaults, opts or {})
  else
    workspace_config = {}
    for k, v in pairs(M.defaults) do
      workspace_config[k] = v
    end
    if opts then
      deep_extend(workspace_config, opts)
    end
  end
  M.workspaces[name] = workspace_config
end

local function ensure_active_workspace()
  -- If no active workspace set, use default workspace
  if M.current_active_workspace == nil then
    if M.default_workspace and M.workspaces[M.default_workspace] then
      M.current_active_workspace = M.default_workspace
    else
      -- Fall back to first configured workspace
      for name, _ in pairs(M.workspaces) do
        M.current_active_workspace = name
        break
      end
      
      -- If no workspaces configured, create a "default" workspace from base config
      if M.current_active_workspace == nil then
        M.workspaces["default"] = M.options
        M.current_active_workspace = "default"
      end
    end
  end
  
  -- Validate current active workspace still exists
  if not M.workspaces[M.current_active_workspace] then
    if M.default_workspace and M.workspaces[M.default_workspace] then
      M.current_active_workspace = M.default_workspace
    else
      -- Fall back to first workspace
      for name, _ in pairs(M.workspaces) do
        M.current_active_workspace = name
        break
      end
    end
  end
end

function M.get_current_config(bufnr)
  ensure_active_workspace()
  -- Always return a workspace config (guaranteed to exist)
  return M.workspaces[M.current_active_workspace], M.current_active_workspace
end

function M.get_workspaces()
  return M.workspaces
end

function M.set_active_workspace(name)
  if M.workspaces[name] then
    M.current_active_workspace = name
    return true
  else
    vim.notify("Workspace '" .. name .. "' not found", vim.log.levels.ERROR)
    return false
  end
end

function M.get_active_workspace()
  return M.current_active_workspace
end

function M.set_default_workspace(name)
  if M.workspaces[name] then
    M.default_workspace = name
    return true
  else
    vim.notify("Workspace '" .. name .. "' not found", vim.log.levels.ERROR)
    return false
  end
end

function M.get_default_workspace()
  return M.default_workspace
end

return M