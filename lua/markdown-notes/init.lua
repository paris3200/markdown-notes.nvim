local config = require("markdown-notes.config")
local templates = require("markdown-notes.templates")
local daily = require("markdown-notes.daily")
local notes = require("markdown-notes.notes")
local links = require("markdown-notes.links")

local M = {}

function M.setup(opts)
  config.setup(opts)
  
  -- Set up key mappings
  local function map(mode, key, cmd, desc)
    if config.options.mappings[key] then
      vim.keymap.set(mode, config.options.mappings[key], cmd, { 
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
  
  -- Templates
  map("n", "insert_template", templates.pick_template, "Insert template")
  
  -- Tags
  map("n", "search_tags", notes.search_tags, "Search tags")
end

return M