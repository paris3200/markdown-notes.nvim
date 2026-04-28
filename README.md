# 📝 markdown-notes.nvim

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg)](https://neovim.io/)

**A powerful, lightweight markdown note-taking plugin for Neovim that transforms your editor into a comprehensive knowledge management system.**

Perfect for developers, researchers, and knowledge workers who want to seamlessly integrate note-taking into their Neovim workflow.

## 📋 Table of Contents

- [✨ Quick Start](#-quick-start)
- [🚀 Features](#-features)
- [📦 Installation](#-installation)
- [⚙️ Basic Configuration](#️-basic-configuration)
- [📖 Usage Guide](#-usage-guide)
- [🔧 Advanced Configuration](#-advanced-configuration)
- [📄 Template System](#-template-system)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📜 License](#-license)

## ✨ Quick Start

**1. Install with your favorite plugin manager:**

```lua
-- lazy.nvim
{
  "paris3200/markdown-notes.nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  config = true,
}
```

**2. Start taking notes immediately:**
- `<leader>nd` - Create today's daily note
- `<leader>nn` - Create a new note
- `<leader>nf` - Find existing notes
- `<leader>ns` - Search note contents

**3. Create your first template** (optional):
```bash
mkdir -p ~/notes/templates
echo "# {{title}}\n\nCreated: {{date}}" > ~/notes/templates/basic.md
```

That's it! You're ready to start building your knowledge base.

## 🚀 Features

### Core Features
- **📅 Daily Notes** - Quick creation and navigation with automatic templating
- **📆 Weekly Notes** - ISO week-based notes for weekly reviews and planning
- **📝 Template System** - Flexible templates with variable substitution (`{{date}}`, `{{time}}`, `{{title}}`, etc.)
- **🔗 Wiki-style Links** - Create and follow `[[note-name]]` links between notes
- **🔄 Smart Renaming** - Rename notes and automatically update all references with file preview
- **🔍 Powerful Search** - Find notes by filename or content with syntax highlighting
- **↩️ Backlinks** - Discover which notes reference the current note

### Advanced Features
- **🏢 Multi-Workspace Support** - Manage multiple independent note vaults
- **🏷️ Tag Management** - Search and organize by frontmatter tags
- **⚡ High Performance** - Built for speed with fuzzy finding via fzf-lua
- **🎨 Highly Configurable** - Customize paths, keybindings, and behavior

## 📦 Installation

### Requirements
- **Neovim >= 0.8.0**
- **[fzf-lua](https://github.com/ibhagwan/fzf-lua)** - Required for fuzzy finding

### Plugin Managers

#### [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  "paris3200/markdown-notes.nvim",
  dependencies = { "ibhagwan/fzf-lua" },
  config = function()
    require("markdown-notes").setup({
      -- your configuration here
    })
  end,
}
```

#### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "paris3200/markdown-notes.nvim",
  requires = { "ibhagwan/fzf-lua" },
  config = function()
    require("markdown-notes").setup()
  end
}
```

#### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'ibhagwan/fzf-lua'
Plug 'paris3200/markdown-notes.nvim'

" In your init.lua or after/plugin/markdown-notes.lua
lua require("markdown-notes").setup()
```

## ⚙️ Basic Configuration

The plugin works out of the box with sensible defaults. Here's a minimal setup:

```lua
require("markdown-notes").setup({
  vault_path = "~/notes",                    -- Where your notes live
  templates_path = "~/notes/templates",      -- Where your templates live
  dailies_path = "~/notes/daily",           -- Where daily notes go
  weekly_path = "~/notes/weekly",           -- Where weekly notes go
})
```

### Key Mappings (Default)

All keybindings use `<leader>n` as the prefix for easy discovery:

| Keybinding | Action | Description |
|------------|--------|-------------|
| `<leader>nd` | Daily note (today) | Create/open today's daily note |
| `<leader>ny` | Daily note (yesterday) | Open yesterday's daily note |
| `<leader>nt` | Daily note (tomorrow) | Open tomorrow's daily note |
| `<leader>nww` | Weekly note (this week) | Create/open this week's weekly note |
| `<leader>nwl` | Weekly note (last week) | Open last week's weekly note |
| `<leader>nwn` | Weekly note (next week) | Open next week's weekly note |
| `<leader>nn` | New note | Create a new note |
| `<leader>nc` | New note from template | Create note with template selection |
| `<leader>nf` | Find notes | Search and open existing notes |
| `<leader>ns` | Search notes | Search within note contents |
| `<leader>nl` | Insert link | Search for note and insert wiki-link |
| `<leader>np` | Insert template | Insert template at cursor |
| `<leader>ng` | Search tags | Find notes by frontmatter tags |
| `<leader>nb` | Show backlinks | Show notes linking to current note |
| `<leader>nr` | Rename note | Rename note and update all references with preview |
| `<leader>nW` | Pick workspace | Switch between workspaces (capital W) |
| `gf` | Follow link | Follow link under cursor |

> **💡 Tip:** All keybindings can be customized in your configuration.

## 📖 Usage Guide

### Getting Started with Daily Notes

Daily notes are the heart of many note-taking workflows. Start your day by creating today's note:

```
<leader>nd  →  Creates/opens today's daily note (e.g., 2025-01-15.md)
```

If you have a `Daily.md` template, it will be automatically applied. Otherwise, a basic note with frontmatter is created.

### Weekly Notes and Reviews

Weekly notes help you plan and review your week at a higher level. They use ISO week numbers for consistency:

```
<leader>nww  →  Creates/opens this week's note (e.g., W03-2025-Weekly-Review.md)
<leader>nwl  →  Opens last week's note
<leader>nwn  →  Opens next week's note
```

Weekly notes are created with the format `W{week}-{year}-Weekly-Review.md` and automatically apply your `Weekly.md` template if available. The plugin uses ISO week numbers where:
- Weeks start on Monday
- Week 1 is the week containing the first Thursday of the year

**Example workflow:**
1. Start each week with `<leader>nww` to create your weekly planning note
2. Review last week with `<leader>nwl` before planning the current week
3. Use template variables like `{{week_number}}`, `{{week_year}}`, and `{{week_id}}` in your Weekly template

### Creating and Managing Notes

#### Basic Note Creation
```
<leader>nn  →  Create a new note with your default template
<leader>nc  →  Choose from available templates
```

#### Finding and Searching
```
<leader>nf  →  Fuzzy find notes by filename (with live preview)
<leader>ns  →  Search inside note contents (with syntax highlighting)
<leader>ng  →  Search by frontmatter tags
```

### Working with Links

#### Creating Links Between Notes
```
<leader>nl  →  Search for a note and insert [[wiki-link]]
               Press Ctrl+L to just insert the link
               Press Enter to open the note
```

#### Following and Managing Links
```
gf          →  Follow the link under cursor
<leader>nb  →  Show all notes that link to current note (backlinks)
<leader>nr  →  Rename current note and update all references
```

**Smart Renaming**: When you rename a note that has links pointing to it, markdown-notes.nvim will:
1. Show you a preview of all files that will be updated
2. Let you browse through them with fzf-lua
3. Update all `[[note-name]]` and `[[note-name|display text]]` references automatically
4. Handle files in subdirectories correctly

> **💡 Tip:** You can disable the preview and use a simple confirmation dialog by setting `ui.show_rename_preview = false` in your configuration.

### Using Templates

Templates make your notes consistent and save time:

```
<leader>np  →  Insert template at cursor position
```

**Example template** (`~/notes/templates/meeting.md`):
```markdown
---
title: {{title}}
date: {{date}}
tags: [meetings]
---

# {{title}}

**Date:** {{datetime}}
**Attendees:** 

## Agenda

## Notes

## Action Items
- [ ] 
```

### Command Reference

| Command | Description |
|---------|-------------|
| `:MarkdownNotesDailyOpen [offset]` | Open daily note (offset in days from today) |
| `:MarkdownNotesWeeklyOpen [offset]` | Open weekly note (offset in weeks from this week) |
| `:MarkdownNotesRename [name]` | Rename current note and update references |
| `:MarkdownNotesWorkspaceStatus` | Show current workspace |
| `:MarkdownNotesWorkspacePick` | Switch workspace with fuzzy finder |
| `:MarkdownNotesWorkspaceSwitch <name>` | Switch to specific workspace |

## 🔧 Advanced Configuration

### Custom Configuration Options

```lua
require("markdown-notes").setup({
  -- Core paths
  vault_path = "~/notes",
  templates_path = "~/notes/templates",
  dailies_path = "~/notes/daily",
  weekly_path = "~/notes/weekly",
  notes_subdir = "notes",
  
  -- Template settings
  default_template = "basic", -- Auto-apply this template to new notes

  -- Filename behavior
  -- "none" (default): use title slug only (e.g. my-note.md); opens existing note on collision
  -- "timestamp": prepend unix timestamp (e.g. 1720094400-my-note.md) for guaranteed uniqueness
  filename_prefix = "none",
  
  -- UI behavior
  ui = {
    show_rename_preview = true, -- Show file preview when renaming notes with links
  },
  
  -- Custom template variables
  template_vars = {
    -- Date/time variables
    date = function() return os.date("%Y-%m-%d") end,
    time = function() return os.date("%H:%M") end,
    datetime = function() return os.date("%Y-%m-%d %H:%M") end,
    title = function() return vim.fn.expand("%:t:r") end,
    yesterday = function() return os.date("%Y-%m-%d", os.time() - 86400) end,
    tomorrow = function() return os.date("%Y-%m-%d", os.time() + 86400) end,
    -- Week variables
    week_number = function() return os.date("%U") end,
    week_year = function() return os.date("%Y") end,
    week_id = function() return "W" .. os.date("%U") .. "-" .. os.date("%Y") end,
    -- Full date format variables
    full_date = function() return os.date("%A, %B %d, %Y") end,
    year = function() return os.date("%Y") end,
    month = function() return os.date("%B") end,
    day_name = function() return os.date("%A") end,
    -- Add your own custom variables
    author = function() return "Your Name" end,
    project = function() return vim.fn.getcwd():match("([^/]+)$") end,
  },
  
  -- Customize keybindings
  mappings = {
    daily_note_today = "<leader>nd",
    daily_note_yesterday = "<leader>ny",
    daily_note_tomorrow = "<leader>nt",
    weekly_note_this_week = "<leader>nww",
    weekly_note_last_week = "<leader>nwl",
    weekly_note_next_week = "<leader>nwn",
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
    pick_workspace = "<leader>nW",
  },
})
```

### Multi-Workspace Configuration

Workspaces allow you to manage multiple independent note vaults simultaneously. Perfect for separating work notes, personal notes, and project-specific documentation.

#### Setting Up Workspaces

```lua
-- Base configuration (becomes your default workspace)
require("markdown-notes").setup({
  vault_path = "~/notes",
  templates_path = "~/notes/templates",
  default_workspace = "personal", -- Optional: specify default
})

-- Work workspace
require("markdown-notes").setup_workspace("work", {
  vault_path = "~/work-notes",
  templates_path = "~/work-notes/templates",
  dailies_path = "~/work-notes/standups",
  default_template = "work-note",
  template_vars = {
    project = function() return "Current Project" end,
    sprint = function() return "Sprint-" .. os.date("%U") end,
  },
})

-- Research workspace
require("markdown-notes").setup_workspace("research", {
  vault_path = "~/research/papers",
  templates_path = "~/research/templates",
  dailies_path = "~/research/lab-notes",
  default_template = "research-paper",
})
```

#### Workspace Workflow

- **Switch workspaces**: Use `<leader>nW` (capital W) to pick from available workspaces
- **Persistent context**: All commands use the active workspace until you switch
- **Independent settings**: Each workspace has its own paths, templates, and variables

### Directory Structure Example

```
~/notes/                          # Main vault
├── templates/                    # Your templates
│   ├── Daily.md                 # Auto-applied to daily notes
│   ├── meeting.md               # Meeting template
│   └── project.md               # Project template
├── daily/                       # Daily notes
│   ├── 2025-01-15.md
│   └── 2025-01-16.md
└── notes/                       # Regular notes
    ├── project-ideas.md
    └── learning-resources.md
```

## 📄 Template System

Templates are markdown files with special `{{variable}}` syntax that gets substituted when creating notes.

### Built-in Template Variables

| Variable | Output | Example |
|----------|--------|---------|
| `{{date}}` | Current date | `2025-01-15` |
| `{{time}}` | Current time | `14:30` |
| `{{datetime}}` | Date and time | `2025-01-15 14:30` |
| `{{title}}` | File name without extension | `meeting-notes` |
| `{{yesterday}}` | Yesterday's date | `2025-01-14` |
| `{{tomorrow}}` | Tomorrow's date | `2025-01-16` |
| `{{week_number}}` | ISO week number | `03` |
| `{{week_year}}` | Year for the week | `2025` |
| `{{week_id}}` | Week identifier | `W03-2025` |
| `{{full_date}}` | Full date format | `Wednesday, January 15, 2025` |
| `{{year}}` | Current year | `2025` |
| `{{month}}` | Current month name | `January` |
| `{{day_name}}` | Current day name | `Wednesday` |

### Creating Custom Variables

Add custom variables in your configuration:

```lua
require("markdown-notes").setup({
  template_vars = {
    author = function() return "Your Name" end,
    project = function() return vim.fn.getcwd():match("([^/]+)$") end,
    week = function() return os.date("Week %U") end,
    uuid = function() return vim.fn.system("uuidgen"):gsub("\n", "") end,
  },
})
```

### Example Templates

**Daily Note Template** (`templates/Daily.md`):
```markdown
---
title: Daily Note - {{date}}
date: {{date}}
tags: [daily]
---

# {{date}} - Daily Notes

## 🎯 Today's Goals
- [ ] 

## 📝 Notes

## 🔄 Tomorrow's Prep
- [ ] 
```

**Weekly Note Template** (`templates/Weekly.md`):
```markdown
---
title: Week {{week_number}} - {{week_year}}
date: {{date}}
week: {{week_id}}
tags: [weekly, review]
---

# Week {{week_number}}, {{week_year}}

## 📊 Week Overview

**Week of:** {{full_date}}

## 🎯 Goals for This Week
- [ ]

## 📝 Weekly Accomplishments

## 🔄 Next Week's Focus

## 📚 Notes and Learnings
```

**Meeting Template** (`templates/meeting.md`):
```markdown
---
title: {{title}}
date: {{date}}
tags: [meeting]
attendees: []
---

# {{title}}

**Date:** {{datetime}}
**Attendees:**

## 📋 Agenda

## 📝 Discussion Notes

## ✅ Action Items
- [ ]

## 🔗 Links
```

## 🛠️ Troubleshooting

### Common Issues

#### "fzf-lua not found" Error
**Solution:** Install fzf-lua dependency:
```lua
-- lazy.nvim
dependencies = { "ibhagwan/fzf-lua" }

-- packer.nvim  
requires = { "ibhagwan/fzf-lua" }
```

#### Templates Not Working
**Checklist:**
1. Verify `templates_path` exists and contains `.md` files
2. Check template syntax uses `{{variable}}` (not `{variable}`)
3. Ensure template file permissions are readable

#### Links Not Following (`gf` not working)
**Solution:** Ensure you're using the correct link format:
- ✅ `[[note-name]]` or `[[note-name.md]]`
- ❌ `[note-name](note-name.md)` (standard markdown links)

#### Performance Issues with Large Vaults
**Solutions:**
- Use `.gitignore` to exclude non-note files from searches
- Consider splitting large vaults into multiple workspaces
- Ensure fzf-lua is properly configured

### Debug Information

Check your configuration:
```lua
:lua print(vim.inspect(require("markdown-notes").config))
```

Check current workspace:
```
:MarkdownNotesWorkspaceStatus
```

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Make** your changes
4. **Test** your changes (run tests if applicable)
5. **Commit** your changes (`git commit -m 'feat: add amazing feature'`)
6. **Push** to the branch (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/markdown-notes.nvim.git
cd markdown-notes.nvim

# Install luacheck for linting (optional but recommended)
luarocks install luacheck

# Run tests
make test

# Run linting
make lint

# Fix linting issues with detailed output
make lint-fix
```

### Development Tools

This project includes several development tools accessible via the Makefile:

- `make test` - Run all tests using plenary.nvim
- `make lint` - Run luacheck linter on source and test files
- `make lint-fix` - Run luacheck with detailed output for fixing issues
- `make clean` - Clean up temporary files
- `make check-deps` - Verify required tools are installed

The project uses GitHub Actions for CI, which automatically runs both tests and linting on all pull requests.

### Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Include your Neovim version and plugin configuration
- Provide steps to reproduce the issue

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

---

<div align="center">

**Happy note-taking! 📝**

If you find this plugin useful, consider ⭐ starring the repository!

</div>
