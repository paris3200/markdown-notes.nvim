local M = {}

M.defaults = {
  vault_path = "~/repos/notes",
  templates_path = "~/repos/notes/sys/templates",
  dailies_path = "~/repos/notes/personal/dailies/2025",
  weekly_path = "~/repos/notes/personal/weekly",
  notes_subdir = "notes",
  
  -- Template substitution variables
  template_vars = {
    date = function() return os.date("%Y-%m-%d") end,
    time = function() return os.date("%H:%M") end,
    datetime = function() return os.date("%Y-%m-%d %H:%M") end,
    title = function() return vim.fn.expand("%:t:r") end,
    yesterday = function() return os.date("%Y-%m-%d", os.time() - 86400) end,
    tomorrow = function() return os.date("%Y-%m-%d", os.time() + 86400) end,
  },
  
  -- Key mappings
  mappings = {
    daily_note_today = "<leader>od",
    daily_note_yesterday = "<leader>oy", 
    daily_note_tomorrow = "<leader>ot",
    new_note = "<leader>on",
    find_notes = "<leader>of",
    search_notes = "<leader>os",
    insert_link = "<leader>ol",
    insert_template = "<leader>op",
    search_tags = "<leader>og",
    show_backlinks = "<leader>ob",
    follow_link = "gf",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M