if vim.g.loaded_markdown_notes == 1 then
  return
end
vim.g.loaded_markdown_notes = 1

-- Plugin will be set up via require('markdown-notes').setup() in user config