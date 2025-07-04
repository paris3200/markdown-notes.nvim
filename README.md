# markdown-notes.nvim

A simple, configurable markdown note-taking plugin for Neovim with support for daily notes, templates, wiki-style linking, and powerful search capabilities.

## Features

- **Daily Notes**: Quick creation and navigation of daily notes with automatic templating
- **Templates**: Flexible template system with variable substitution (`{{date}}`, `{{time}}`, etc.)
- **Wiki-style Links**: Create and follow `[[note-name]]` links between notes
- **Powerful Search**: Find notes by filename or content, search tags
- **Backlinks**: Discover which notes reference the current note
- **Configurable**: Customize paths, keybindings, and behavior

## Requirements

- Neovim >= 0.8.0
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) for fuzzy finding
- [marksman](https://github.com/artempyanykh/marksman) LSP (optional, for enhanced link completion)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "paris3200/markdown-notes.nvim",
  dependencies = {
    "ibhagwan/fzf-lua",
  },
  config = function()
    require("markdown-notes").setup({
      -- your configuration here
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "paris3200/markdown-notes.nvim",
  requires = { "ibhagwan/fzf-lua" },
  config = function()
    require("markdown-notes").setup()
  end
}
```

## Configuration

Default configuration:

```lua
require("markdown-notes").setup({
  vault_path = "~/repos/notes",
  templates_path = "~/repos/notes/sys/templates",
  dailies_path = "~/repos/notes/personal/dailies/2025",
  weekly_path = "~/repos/notes/personal/weekly",
  notes_subdir = "notes",
  
  -- Custom template variables
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
})
```

## Usage

### Daily Notes

- `<leader>od` - Open today's daily note
- `<leader>oy` - Open yesterday's daily note
- `<leader>ot` - Open tomorrow's daily note

Daily notes are automatically created with your `Daily.md` template if it exists.

### Note Management

- `<leader>on` - Create a new note with frontmatter
- `<leader>of` - Find and open existing notes
- `<leader>os` - Search within note contents

### Links and Navigation

- `<leader>ol` - Search for a note and insert a `[[wiki-link]]`
  - Press `Enter` to open the selected note
  - Press `Ctrl+L` to insert a link to the note
- `gf` - Follow the link under cursor
- `<leader>ob` - Show backlinks to the current note

### Templates

- `<leader>op` - Insert a template at cursor position
- Templates support variable substitution with `{{variable}}` syntax

### Tags

- `<leader>og` - Search for tags (lines containing `#`)

## Template Variables

Available template variables:

- `{{date}}` - Current date (YYYY-MM-DD)
- `{{time}}` - Current time (HH:MM)
- `{{datetime}}` - Current date and time
- `{{title}}` - Current file name without extension
- `{{yesterday}}` - Yesterday's date
- `{{tomorrow}}` - Tomorrow's date

## Directory Structure

```
~/repos/notes/
├── sys/
│   └── templates/
│       ├── Daily.md
│       ├── Meeting.md
│       └── Project.md
├── personal/
│   └── dailies/
│       └── 2025/
│           ├── 2025-01-01.md
│           └── 2025-01-02.md
└── notes/
    ├── project-ideas.md
    └── learning-resources.md
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.