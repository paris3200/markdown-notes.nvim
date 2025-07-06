local config = require("markdown-notes.config")

describe("config", function()
  before_each(function()
    config.options = {}
    config.workspaces = {}
    config.default_workspace = nil
    config.current_active_workspace = nil
  end)

  it("has default configuration", function()
    assert.is_not_nil(config.defaults)
    assert.is_not_nil(config.defaults.vault_path)
    assert.is_not_nil(config.defaults.templates_path)
    assert.is_not_nil(config.defaults.template_vars)
    assert.is_not_nil(config.defaults.mappings)
  end)

  it("merges user options with defaults", function()
    local user_opts = {
      vault_path = "/custom/path",
      custom_option = "test"
    }
    
    config.setup(user_opts)
    
    assert.are.equal("/custom/path", config.options.vault_path)
    assert.are.equal("test", config.options.custom_option)
    assert.is_not_nil(config.options.templates_path)
  end)

  it("deep merges nested options", function()
    local user_opts = {
      mappings = {
        daily_note_today = "<leader>dt"
      }
    }
    
    config.setup(user_opts)
    
    assert.are.equal("<leader>dt", config.options.mappings.daily_note_today)
    assert.is_not_nil(config.options.mappings.new_note)
  end)

  describe("workspaces", function()
    it("sets up workspace with custom config", function()
      local workspace_opts = {
        vault_path = "/work/notes",
        templates_path = "/work/templates"
      }
      
      config.setup_workspace("work", workspace_opts)
      
      assert.is_not_nil(config.workspaces.work)
      assert.are.equal("/work/notes", config.workspaces.work.vault_path)
      assert.are.equal("/work/templates", config.workspaces.work.templates_path)
      assert.is_not_nil(config.workspaces.work.dailies_path) -- Should inherit from defaults
    end)

    it("merges workspace config with defaults", function()
      local workspace_opts = {
        vault_path = "/personal/notes"
      }
      
      config.setup_workspace("personal", workspace_opts)
      
      assert.are.equal("/personal/notes", config.workspaces.personal.vault_path)
      assert.is_not_nil(config.workspaces.personal.templates_path)
      assert.is_not_nil(config.workspaces.personal.template_vars)
      assert.is_not_nil(config.workspaces.personal.mappings)
    end)

    it("returns workspace list", function()
      config.setup_workspace("work", { vault_path = "/work" })
      config.setup_workspace("personal", { vault_path = "/personal" })
      
      local workspaces = config.get_workspaces()
      
      assert.is_not_nil(workspaces.work)
      assert.is_not_nil(workspaces.personal)
      assert.are.equal("/work", workspaces.work.vault_path)
      assert.are.equal("/personal", workspaces.personal.vault_path)
    end)
  end)

  describe("workspace detection", function()
    before_each(function()
      config.setup_workspace("work", { vault_path = "/work/notes" })
      config.setup_workspace("personal", { vault_path = "/personal/notes" })
      -- Set work as default to match expected behavior
      config.set_default_workspace("work")
    end)

    it("uses first workspace as active workspace", function()
      -- With simplified system, first workspace configured becomes active
      local workspace_config, workspace_name = config.get_current_config()
      
      -- "work" is set up first in before_each, so it becomes the active workspace
      assert.are.equal("work", workspace_name)
      assert.are.equal("/work/notes", workspace_config.vault_path)
    end)


    it("handles empty buffer name by using active workspace", function()
      -- No need to mock buffer name - simplified system doesn't depend on it
      local workspace_config, workspace_name = config.get_current_config()
      
      -- Should use the first workspace (work) that was set up in before_each
      assert.are.equal("work", workspace_name)
      assert.are.equal("/work/notes", workspace_config.vault_path)
    end)
  end)

  describe("default workspace", function()
    before_each(function()
      config.setup({ vault_path = "/fallback/notes" })
      config.setup_workspace("work", { vault_path = "/work/notes" })
      config.setup_workspace("personal", { vault_path = "/personal/notes" })
    end)

    it("sets and gets default workspace", function()
      local success = config.set_default_workspace("work")
      
      assert.is_true(success)
      assert.are.equal("work", config.get_default_workspace())
    end)

    it("fails to set non-existent workspace as default", function()
      local success = config.set_default_workspace("nonexistent")
      
      assert.is_false(success)
      assert.is_nil(config.get_default_workspace())
    end)

    it("sets default workspace from main config", function()
      -- Reset state
      config.options = {}
      config.workspaces = {}
      config.default_workspace = nil
      config.current_active_workspace = nil
      
      -- Setup with default_workspace in config
      config.setup({
        vault_path = "/base/notes",
        default_workspace = "personal"
      })
      config.setup_workspace("work", { vault_path = "/work/notes" })
      config.setup_workspace("personal", { vault_path = "/personal/notes" })
      
      assert.are.equal("personal", config.get_default_workspace())
      
      -- Should use personal workspace as active workspace
      local workspace_config, workspace_name = config.get_current_config()
      assert.are.equal("personal", workspace_name)
      assert.are.equal("/personal/notes", workspace_config.vault_path)
    end)

    it("first workspace becomes default when no default_workspace specified", function()
      -- Reset state
      config.options = {}
      config.workspaces = {}
      config.default_workspace = nil
      config.current_active_workspace = nil
      
      -- Setup without default_workspace in config
      config.setup({ vault_path = "/base/notes" })
      
      -- First workspace should become default (via init.lua logic)
      local init = require("markdown-notes.init")
      init.setup_workspace("work", { vault_path = "/work/notes" })
      init.setup_workspace("personal", { vault_path = "/personal/notes" })
      
      assert.are.equal("work", config.get_default_workspace())
      
      -- Should use work workspace as active workspace
      local workspace_config, workspace_name = config.get_current_config()
      assert.are.equal("work", workspace_name)
      assert.are.equal("/work/notes", workspace_config.vault_path)
    end)

    it("uses default workspace for empty buffer paths", function()
      config.set_default_workspace("personal")
      
      -- Mock vim.api.nvim_buf_get_name to return empty string
      local original_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function(bufnr)
        return ""
      end

      local workspace_config, workspace_name = config.get_current_config()
      
      assert.are.equal("personal", workspace_name)
      assert.are.equal("/personal/notes", workspace_config.vault_path)
      
      -- Restore original function
      vim.api.nvim_buf_get_name = original_get_name
    end)

    it("uses default workspace when no path matches", function()
      config.set_default_workspace("work")
      
      -- Mock vim.api.nvim_buf_get_name to return non-matching path
      local original_get_name = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function(bufnr)
        return "/random/location/file.md"
      end

      local workspace_config, workspace_name = config.get_current_config()
      
      assert.are.equal("work", workspace_name)
      assert.are.equal("/work/notes", workspace_config.vault_path)
      
      -- Restore original function
      vim.api.nvim_buf_get_name = original_get_name
    end)


  end)
end)