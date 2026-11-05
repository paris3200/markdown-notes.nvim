local tasks = require("markdown-notes.tasks")

describe("tasks", function()
	local function set_buffer(lines)
		vim.cmd("enew!")
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	end

	local function get_buffer()
		return vim.api.nvim_buf_get_lines(0, 0, -1, false)
	end

	describe("toggle_checkbox", function()
		it("checks an unchecked item", function()
			set_buffer({ "- [ ] Buy milk" })
			tasks.toggle_checkbox()
			assert.are.same({ "- [x] Buy milk" }, get_buffer())
		end)

		it("unchecks a checked item", function()
			set_buffer({ "- [x] Buy milk" })
			tasks.toggle_checkbox()
			assert.are.same({ "- [ ] Buy milk" }, get_buffer())
		end)

		it("unchecks an uppercase X", function()
			set_buffer({ "- [X] Buy milk" })
			tasks.toggle_checkbox()
			assert.are.same({ "- [ ] Buy milk" }, get_buffer())
		end)

		it("handles nested items and other bullet markers", function()
			set_buffer({ "  - [ ] Set 1:", "    * [ ] Set 2:", "\t+ [x] Set 3:" })
			for line = 1, 3 do
				tasks.toggle_checkbox(line)
			end
			assert.are.same({ "  - [x] Set 1:", "    * [x] Set 2:", "\t+ [ ] Set 3:" }, get_buffer())
		end)

		it("handles numbered items", function()
			set_buffer({ "1. [ ] First", "  12. [x] Twelfth" })
			tasks.toggle_checkbox(1)
			tasks.toggle_checkbox(2)
			assert.are.same({ "1. [x] First", "  12. [ ] Twelfth" }, get_buffer())
		end)

		it("leaves lines without a checkbox unchanged", function()
			local lines = { "- Plain item", "Some text with [ ] brackets", "- [] not a checkbox" }
			set_buffer(lines)
			for line = 1, 3 do
				tasks.toggle_checkbox(line)
			end
			assert.are.same(lines, get_buffer())
		end)

		it("keeps the cursor position", function()
			set_buffer({ "- [ ] Buy milk" })
			vim.api.nvim_win_set_cursor(0, { 1, 9 })
			tasks.toggle_checkbox()
			assert.are.same({ 1, 9 }, vim.api.nvim_win_get_cursor(0))
		end)

		it("toggles every checkbox in a line range", function()
			set_buffer({ "- [ ] One", "Not a task", "- [x] Two", "- [ ] Outside" })
			tasks.toggle_checkbox(1, 3)
			assert.are.same({ "- [x] One", "Not a task", "- [ ] Two", "- [ ] Outside" }, get_buffer())
		end)

		it("toggles every checkbox in a visual selection", function()
			set_buffer({ "- [ ] One", "Not a task", "  - [x] Two", "- [ ] Outside" })
			vim.keymap.set("x", "<F2>", tasks.toggle_checkbox, { buffer = 0 })
			local keys = vim.api.nvim_replace_termcodes("ggVjj<F2>", true, false, true)
			vim.api.nvim_feedkeys(keys, "x", false)
			assert.are.same({ "- [x] One", "Not a task", "  - [ ] Two", "- [ ] Outside" }, get_buffer())
			assert.are.equal("n", vim.fn.mode())
		end)
	end)
end)
