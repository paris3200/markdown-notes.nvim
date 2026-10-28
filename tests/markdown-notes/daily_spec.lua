local daily = require("markdown-notes.daily")
local config = require("markdown-notes.config")

describe("daily", function()
	local tmp_dir
	local original_cmd
	local opened_file

	before_each(function()
		tmp_dir = vim.fn.tempname()
		vim.fn.mkdir(tmp_dir .. "/templates", "p")
		vim.fn.writefile({ "# Template {{date}}" }, tmp_dir .. "/templates/Daily.md")

		config.options = {}
		config.workspaces = {}
		config.current_active_workspace = nil

		opened_file = nil
		original_cmd = vim.cmd
		vim.cmd = function(cmd)
			opened_file = cmd:match("^edit (.+)$")
		end
	end)

	after_each(function()
		vim.cmd = original_cmd
		vim.fn.delete(tmp_dir, "rf")
	end)

	local function setup(opts)
		config.setup(vim.tbl_extend("force", {
			dailies_path = tmp_dir .. "/dailies",
			templates_path = tmp_dir .. "/templates",
		}, opts or {}))
	end

	local function today_path()
		return tmp_dir .. "/dailies/" .. os.date("%Y-%m-%d") .. ".md"
	end

	describe("open_daily_note", function()
		it("creates the note from the Daily template", function()
			setup()
			daily.open_daily_note(0)

			assert.are.equal(today_path(), opened_file)
			assert.are.same({ "# Template " .. os.date("%Y-%m-%d") }, vim.fn.readfile(today_path()))
		end)

		it("replaces {{year}} in dailies_path with the note's year", function()
			setup({ dailies_path = tmp_dir .. "/dailies/{{year}}" })
			daily.open_daily_note(-400)

			local date = os.date("%Y-%m-%d", os.time() - 400 * 86400)
			assert.are.equal(tmp_dir .. "/dailies/" .. date:sub(1, 4) .. "/" .. date .. ".md", opened_file)
			assert.are.equal(1, vim.fn.filereadable(opened_file))
		end)

		it("runs daily_note_command with the date substituted", function()
			setup({
				daily_note_command = {
					"sh",
					"-c",
					'echo "# From command $1" > "$2"',
					"sh",
					"{{date}}",
					tmp_dir .. "/dailies/{{date}}.md",
				},
			})
			daily.open_daily_note(0)

			assert.are.equal(today_path(), opened_file)
			assert.are.same({ "# From command " .. os.date("%Y-%m-%d") }, vim.fn.readfile(today_path()))
		end)

		it("falls back to the template when daily_note_command fails", function()
			local original_notify = vim.notify
			local warned = false
			vim.notify = function(_, level)
				warned = level == vim.log.levels.WARN
			end

			setup({ daily_note_command = { "sh", "-c", "exit 1" } })
			daily.open_daily_note(0)
			vim.notify = original_notify

			assert.is_true(warned)
			assert.are.same({ "# Template " .. os.date("%Y-%m-%d") }, vim.fn.readfile(today_path()))
		end)

		it("does not run daily_note_command when the note already exists", function()
			vim.fn.mkdir(tmp_dir .. "/dailies", "p")
			vim.fn.writefile({ "existing" }, today_path())
			setup({ daily_note_command = { "sh", "-c", 'echo ran > "$0"', today_path() } })
			daily.open_daily_note(0)

			assert.are.same({ "existing" }, vim.fn.readfile(today_path()))
		end)
	end)
end)
