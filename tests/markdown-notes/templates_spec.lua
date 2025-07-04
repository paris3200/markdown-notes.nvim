local templates = require("markdown-notes.templates")
local config = require("markdown-notes.config")

describe("templates", function()
  before_each(function()
    config.setup({})
  end)

  describe("substitute_template_vars", function()
    it("substitutes date variables", function()
      local content = {"Today is {{date}}", "Time is {{time}}"}
      local result = templates.substitute_template_vars(content)
      
      assert.is_not.equal("Today is {{date}}", result[1])
      assert.is_not.equal("Time is {{time}}", result[2])
      assert.matches("%d%d%d%d%-%d%d%-%d%d", result[1])
      assert.matches("%d%d:%d%d", result[2])
    end)

    it("substitutes custom variables", function()
      local content = {"Hello {{name}}"}
      local custom_vars = {name = "World"}
      local result = templates.substitute_template_vars(content, custom_vars)
      
      assert.are.equal("Hello World", result[1])
    end)

    it("handles function variables", function()
      local content = {"Value is {{custom}}"}
      local custom_vars = {custom = function() return "dynamic" end}
      local result = templates.substitute_template_vars(content, custom_vars)
      
      assert.are.equal("Value is dynamic", result[1])
    end)

    it("handles multiple substitutions in one line", function()
      local content = {"{{date}} - {{time}} - {{title}}"}
      local result = templates.substitute_template_vars(content)
      
      assert.matches("%d%d%d%d%-%d%d%-%d%d", result[1])
      assert.matches("%d%d:%d%d", result[1])
    end)
  end)
end)