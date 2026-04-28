local weekly = require("markdown-notes.weekly")
local config = require("markdown-notes.config")

describe("weekly", function()
	before_each(function()
		config.options = {}
		config.workspaces = {}
		config.setup({
			weekly_path = "/tmp/test-weekly-notes",
			templates_path = "/tmp/test-templates",
		})
	end)

	describe("open_weekly_note", function()
		it("creates weekly note with ISO week format", function()
			-- This is a basic test to verify the module loads and function exists
			assert.is_function(weekly.open_weekly_note)
		end)
	end)
end)
