local templates = require("markdown-notes.templates")
local config = require("markdown-notes.config")

describe("templates", function()
	before_each(function()
		config.options = {}
		config.workspaces = {}
		config.setup({})
	end)

	describe("substitute_template_vars", function()
		it("substitutes date variables", function()
			local content = { "Today is {{date}}", "Time is {{time}}" }
			local result = templates.substitute_template_vars(content)

			assert.is_not.equal("Today is {{date}}", result[1])
			assert.is_not.equal("Time is {{time}}", result[2])
			assert.matches("%d%d%d%d%-%d%d%-%d%d", result[1])
			assert.matches("%d%d:%d%d", result[2])
		end)

		it("substitutes custom variables", function()
			local content = { "Hello {{name}}" }
			local custom_vars = { name = "World" }
			local result = templates.substitute_template_vars(content, custom_vars)

		assert.are.equal("Hello World", result[1])
	end)

	it("handles function variables", function()
		local content = { "Value is {{custom}}" }
		local custom_vars = {
			custom = function()
				return "dynamic"
			end,
		}
		local result = templates.substitute_template_vars(content, custom_vars)

		assert.are.equal("Value is dynamic", result[1])
	end)

	it("handles multiple substitutions in one line", function()
		local content = { "{{date}} - {{time}} - {{title}}" }
		local result = templates.substitute_template_vars(content)

		assert.matches("%d%d%d%d%-%d%d%-%d%d", result[1])
		assert.matches("%d%d:%d%d", result[1])
	end)

	it("uses config-defined template variables", function()
		-- Setup config with custom template variables
		config.setup({
			template_vars = {
				author = function()
					return "Test Author"
				end,
				project = function()
					return "my-project"
				end,
				custom_static = "static-content",
			},
		})

		local content = {
			"Author: {{author}}",
			"Project: {{project}}",
			"Static: {{custom_static}}",
			"Date: {{date}}",
		}

		local result = templates.substitute_template_vars(content)

		-- Custom variables should be substituted
		assert.are.equal("Author: Test Author", result[1])
		assert.are.equal("Project: my-project", result[2])
		assert.are.equal("Static: static-content", result[3])

		-- Default variables should still work
		assert.matches("Date: %d%d%d%d%-%d%d%-%d%d", result[4])
	end)

	it("overrides config variables with custom vars parameter", function()
		-- Setup config with a template variable
		config.setup({
			template_vars = {
				author = function()
					return "Config Author"
				end,
			},
		})

		local content = { "Author: {{author}}" }

		-- Override with custom vars
		local custom_vars = {
			author = function()
				return "Override Author"
			end,
		}

		local result = templates.substitute_template_vars(content, custom_vars)

		-- Should use the override, not the config value
		assert.are.equal("Author: Override Author", result[1])
	end)
	end)
end)
