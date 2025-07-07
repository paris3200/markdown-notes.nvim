#!/bin/bash

# markdown-notes.nvim Test Setup Script
# Creates a clean testing environment for the plugin

set -e

echo "🧪 Setting up markdown-notes.nvim test environment..."

# Configuration
TEST_DIR="$HOME/test-markdown-notes"
CONFIG_FILE="$TEST_DIR/test-config.lua"

# Clean up existing test directory
if [ -d "$TEST_DIR" ]; then
    echo "🧹 Cleaning up existing test directory..."
    rm -rf "$TEST_DIR"
fi

# Create test directory structure
echo "📁 Creating test directory structure..."
mkdir -p "$TEST_DIR"/{vault/{templates,daily,notes},config}

# Create test templates
echo "📝 Creating test templates..."

# Basic template
cat > "$TEST_DIR/vault/templates/basic.md" << 'EOF'
---
title: {{title}}
date: {{date}}
tags: []
---

# {{title}}

Created: {{datetime}}

## Notes

EOF

# Daily template
cat > "$TEST_DIR/vault/templates/Daily.md" << 'EOF'
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

EOF

# Meeting template
cat > "$TEST_DIR/vault/templates/meeting.md" << 'EOF'
---
title: {{title}}
date: {{date}}
tags: [meeting]
attendees: []
---

# {{title}}

**Date:** {{datetime}}
**Attendees:** 

## Agenda

## Notes

## Action Items
- [ ] 

EOF

# Project template
cat > "$TEST_DIR/vault/templates/project.md" << 'EOF'
---
title: {{title}}
date: {{date}}
tags: [project]
status: planning
---

# {{title}}

**Created:** {{datetime}}

## Overview

## Goals

## Tasks
- [ ] 

## Resources

EOF

# Create minimal test configuration
echo "⚙️  Creating test configuration..."
cat > "$CONFIG_FILE" << EOF
-- Test configuration for markdown-notes.nvim
-- Run with: nvim -u $CONFIG_FILE

-- Minimal vim setup
vim.cmd('set runtimepath^=~/.vim runtimepath+=~/.vim/after')
vim.cmd('let &packpath = &runtimepath')

-- Add current plugin directory to runtime path
vim.opt.rtp:prepend('$(pwd)')

-- Try to add fzf-lua from common locations
local fzf_paths = {
    vim.fn.expand('~/.local/share/nvim/lazy/fzf-lua'),
    vim.fn.expand('~/.local/share/nvim/site/pack/*/start/fzf-lua'),
    vim.fn.expand('~/.config/nvim/pack/*/start/fzf-lua'),
}

for _, path in ipairs(fzf_paths) do
    if vim.fn.isdirectory(path) == 1 then
        vim.opt.rtp:prepend(path)
        print('📦 Found fzf-lua at: ' .. path)
        break
    end
end

-- Set leader key
vim.g.mapleader = ' '

-- Basic settings for testing
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false

-- Setup markdown-notes
local ok, markdown_notes = pcall(require, 'markdown-notes')
if not ok then
    print('❌ Failed to load markdown-notes: ' .. tostring(markdown_notes))
    return
end

markdown_notes.setup({
    vault_path = '$TEST_DIR/vault',
    templates_path = '$TEST_DIR/vault/templates',
    dailies_path = '$TEST_DIR/vault/daily',
    notes_subdir = 'notes',
    default_template = 'basic',
})

print('✅ markdown-notes.nvim loaded successfully!')
print('📁 Test vault: $TEST_DIR/vault')
print('')
print('🧪 Test Commands:')
print('  <leader>nd  - Create daily note')
print('  <leader>nn  - Create new note')
print('  <leader>nc  - Create from template')
print('  <leader>nf  - Find notes')
print('  <leader>ns  - Search notes')
print('  <leader>np  - Insert template')
print('  :help markdown-notes - View documentation')
print('')
print('📂 Available templates:')
print('  - basic.md')
print('  - Daily.md')
print('  - meeting.md')
print('  - project.md')
print('')
print('🔧 To inspect config: :lua print(vim.inspect(require("markdown-notes.config").options))')
EOF

# Create some sample notes for testing
echo "📄 Creating sample notes..."

cat > "$TEST_DIR/vault/notes/welcome.md" << 'EOF'
---
title: Welcome to Test Notes
date: 2025-01-06
tags: [welcome, test]
---

# Welcome to Test Notes

This is a sample note for testing the markdown-notes.nvim plugin.

## Features to Test

- [[daily-workflow]] - Link to daily workflow
- [[project-management]] - Link to project management
- Create new notes with templates
- Search functionality

## Sample Links

Try following these links with `gf`:
- [[welcome]] (this note)
- [[nonexistent-note]] (will create new note)

EOF

cat > "$TEST_DIR/vault/notes/daily-workflow.md" << 'EOF'
---
title: Daily Workflow
date: 2025-01-06
tags: [workflow, daily]
---

# Daily Workflow

This note demonstrates the daily workflow with markdown-notes.nvim.

## Morning Routine
1. Open daily note with `<leader>nd`
2. Review yesterday's note with `<leader>ny`
3. Plan today's tasks

## Evening Review
1. Update daily note
2. Plan tomorrow with `<leader>nt`

This note links back to [[welcome]].

EOF

# Create launch script
echo "🚀 Creating launch script..."
cat > "$TEST_DIR/launch-test.sh" << EOF
#!/bin/bash
echo "🧪 Launching markdown-notes.nvim test environment..."
echo "📁 Test vault: $TEST_DIR/vault"
echo ""
cd '$TEST_DIR/vault'
nvim -u '$CONFIG_FILE'
EOF

chmod +x "$TEST_DIR/launch-test.sh"

# Create cleanup script
cat > "$TEST_DIR/cleanup.sh" << EOF
#!/bin/bash
echo "🧹 Cleaning up test environment..."
rm -rf '$TEST_DIR'
echo "✅ Test environment cleaned up!"
EOF

chmod +x "$TEST_DIR/cleanup.sh"

echo ""
echo "✅ Test environment setup complete!"
echo ""
echo "🚀 To start testing:"
echo "   $TEST_DIR/launch-test.sh"
echo ""
echo "📁 Test vault location:"
echo "   $TEST_DIR/vault"
echo ""
echo "⚙️  Config file:"
echo "   $CONFIG_FILE"
echo ""
echo "🧹 To cleanup when done:"
echo "   $TEST_DIR/cleanup.sh"
echo ""
echo "📋 Test checklist:"
echo "  □ Daily notes (<leader>nd, <leader>ny, <leader>nt)"
echo "  □ New notes (<leader>nn, <leader>nc)"
echo "  □ Finding notes (<leader>nf)"
echo "  □ Searching content (<leader>ns)"
echo "  □ Following links (gf on [[links]])"
echo "  □ Inserting templates (<leader>np)"
echo "  □ Help documentation (:help markdown-notes)"
echo "  □ Workspace functionality"