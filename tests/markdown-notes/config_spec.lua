local config = require("markdown-notes.config")

describe("config", function()
  before_each(function()
    config.options = {}
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
end)