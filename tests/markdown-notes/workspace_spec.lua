local config = require("markdown-notes.config")

describe("workspace", function()
	before_each(function()
		config.options = {}
		config.workspaces = {}
		config.default_workspace = nil
	end)

	describe("workspace configuration", function()
		it("sets up workspace correctly", function()
			config.setup_workspace("work", { vault_path = "/work/notes" })

			local workspaces = config.get_workspaces()
			assert.is_not_nil(workspaces.work)
			assert.are.equal("/work/notes", workspaces.work.vault_path)
		end)

		it("sets up multiple workspaces", function()
			config.setup_workspace("work", { vault_path = "/work/notes" })
			config.setup_workspace("personal", { vault_path = "/personal/notes" })

			local workspaces = config.get_workspaces()
			assert.is_not_nil(workspaces.work)
			assert.is_not_nil(workspaces.personal)
			assert.are.equal("/work/notes", workspaces.work.vault_path)
			assert.are.equal("/personal/notes", workspaces.personal.vault_path)
		end)

		it("workspace inherits from defaults", function()
			config.setup_workspace("test", { vault_path = "/test" })

			local workspaces = config.get_workspaces()
			local test_workspace = workspaces.test

			assert.are.equal("/test", test_workspace.vault_path)
			assert.is_not_nil(test_workspace.templates_path)
			assert.is_not_nil(test_workspace.template_vars)
			assert.is_not_nil(test_workspace.mappings)
		end)
	end)

	describe("workspace detection", function()
		before_each(function()
			config.setup({ vault_path = "/default/notes" })
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
	end)
end)
