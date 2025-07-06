local config = require("markdown-notes.config")
local templates = require("markdown-notes.templates")
local daily = require("markdown-notes.daily")
local notes = require("markdown-notes.notes")
local links = require("markdown-notes.links")
local workspace = require("markdown-notes.workspace")

local M = {}

function M.setup(opts)
  config.setup(opts)
  M.setup_keymaps()
end

function M.setup_workspace(name, opts)
  config.setup_workspace(name, opts)
  
  -- If this is the first workspace and no default is set, make it the default
  if not config.get_default_workspace() then
    config.set_default_workspace(name)
  end
end

function M.set_default_workspace(name)
  return config.set_default_workspace(name)
end

function M.setup_keymaps()
  
  -- Set up key mappings
  local function map(mode, key, cmd, desc)
    -- Use a wrapper that gets current workspace config at runtime
    local function wrapped_cmd()
      if type(cmd) == "function" then
        cmd()
      else
        return cmd
      end
    end
    
    if config.options.mappings[key] then
      vim.keymap.set(mode, config.options.mappings[key], wrapped_cmd, { 
        noremap = true, 
        silent = true, 
        desc = desc 
      })
    end
  end
  
  -- Daily notes
  map("n", "daily_note_today", function() daily.open_daily_note(0) end, "Open today's note")
  map("n", "daily_note_yesterday", function() daily.open_daily_note(-1) end, "Open yesterday's note")
  map("n", "daily_note_tomorrow", function() daily.open_daily_note(1) end, "Open tomorrow's note")
  
  -- Note management
  map("n", "new_note", notes.create_new_note, "Create new note")
  map("n", "new_note_from_template", notes.create_from_template, "Create new note from template")
  map("n", "find_notes", notes.find_notes, "Find notes")
  map("n", "search_notes", notes.search_notes, "Search notes")
  
  -- Links
  map("n", "insert_link", links.search_and_link, "Insert link to note")
  map("n", "follow_link", links.follow_link, "Follow link")
  map("n", "show_backlinks", links.show_backlinks, "Show backlinks")
  map("n", "rename_note", function() 
    vim.ui.input({prompt = "New note name: "}, function(input)
      if input then
        links.rename_note(input)
      end
    end)
  end, "Rename note and update links")
  
  -- Templates
  map("n", "insert_template", templates.pick_template, "Insert template")
  
  -- Tags
  map("n", "search_tags", notes.search_tags, "Search tags")
  
  -- Workspaces
  map("n", "pick_workspace", workspace.pick_workspace, "Pick workspace")
  
  -- Note management commands
  vim.api.nvim_create_user_command("MarkdownNotesRename", function(opts)
    if opts.args and opts.args ~= "" then
      links.rename_note(opts.args)
    else
      vim.ui.input({prompt = "New note name: "}, function(input)
        if input then
          links.rename_note(input)
        end
      end)
    end
  end, { nargs = "?", desc = "Rename current note and update links" })
  
  -- Workspace management commands
  vim.api.nvim_create_user_command("MarkdownNotesWorkspaceStatus", workspace.show_current_workspace, { desc = "Show current workspace" })
  vim.api.nvim_create_user_command("MarkdownNotesWorkspacePick", workspace.pick_workspace, { desc = "Pick workspace with fzf" })
  vim.api.nvim_create_user_command("MarkdownNotesWorkspaceSwitch", function(opts)
    workspace.switch_to_workspace(opts.args)
  end, { 
    nargs = 1, 
    desc = "Switch to workspace", 
    complete = function()
      local workspaces = config.get_workspaces()
      local names = {}
      for name, _ in pairs(workspaces) do
        table.insert(names, name)
      end
      return names
    end 
  })
  vim.api.nvim_create_user_command("MarkdownNotesWorkspaceSetDefault", function(opts)
    workspace.set_default_workspace(opts.args)
  end, { 
    nargs = 1, 
    desc = "Set default workspace", 
    complete = function()
      local workspaces = config.get_workspaces()
      local names = {}
      for name, _ in pairs(workspaces) do
        table.insert(names, name)
      end
      return names
    end 
  })
  vim.api.nvim_create_user_command("MarkdownNotesWorkspaceShowDefault", workspace.show_default_workspace, { desc = "Show default workspace" })
  vim.api.nvim_create_user_command("MarkdownNotesWorkspaceActive", function()
    local _, active = config.get_current_config()
    vim.notify("Active workspace: " .. active, vim.log.levels.INFO)
  end, { desc = "Show active workspace" })
end

return M