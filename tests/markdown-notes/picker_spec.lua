local config = require("markdown-notes.config")
local picker = require("markdown-notes.picker")

-- Replace a backend module with a stub (or make it unavailable when stub is nil)
local function set_module(name, stub)
	package.loaded[name] = stub
	package.preload[name] = function()
		if stub then
			return stub
		end
		error("module '" .. name .. "' not found (stubbed)")
	end
end

describe("picker", function()
	local saved = {}
	local notifications

	before_each(function()
		for _, name in ipairs({ "fzf-lua", "snacks" }) do
			saved[name] = { loaded = package.loaded[name], preload = package.preload[name] }
		end
		config.setup({})
		notifications = {}
		saved.notify = vim.notify
		vim.notify = function(message, level)
			table.insert(notifications, { message = message, level = level })
		end
	end)

	after_each(function()
		for _, name in ipairs({ "fzf-lua", "snacks" }) do
			package.loaded[name] = saved[name].loaded
			package.preload[name] = saved[name].preload
		end
		vim.notify = saved.notify
	end)

	describe("resolve", function()
		it("defaults to auto", function()
			assert.are.equal("auto", config.defaults.picker)
			assert.are.equal("auto", config.options.picker)
		end)

		it("auto prefers fzf-lua when both are installed", function()
			set_module("fzf-lua", {})
			set_module("snacks", {})
			assert.are.equal("fzf", picker.resolve())
		end)

		it("auto falls back to snacks when fzf-lua is missing", function()
			set_module("fzf-lua", nil)
			set_module("snacks", {})
			assert.are.equal("snacks", picker.resolve())
		end)

		it("auto notifies when no backend is installed", function()
			set_module("fzf-lua", nil)
			set_module("snacks", nil)
			assert.is_nil(picker.resolve())
			assert.are.equal(vim.log.levels.ERROR, notifications[1].level)
		end)

		it("uses snacks when configured even if fzf-lua is installed", function()
			set_module("fzf-lua", {})
			set_module("snacks", {})
			config.setup({ picker = "snacks" })
			assert.are.equal("snacks", picker.resolve())
		end)

		it("names the missing plugin when the configured backend is not installed", function()
			set_module("snacks", nil)
			config.setup({ picker = "snacks" })
			assert.is_nil(picker.resolve())
			assert.is_not_nil(notifications[1].message:find("snacks.nvim", 1, true))

			set_module("fzf-lua", nil)
			config.setup({ picker = "fzf" })
			assert.is_nil(picker.resolve())
			assert.is_not_nil(notifications[2].message:find("fzf-lua", 1, true))
		end)

		it("rejects unknown backends", function()
			config.setup({ picker = "telescope" })
			assert.is_nil(picker.resolve())
			assert.is_not_nil(notifications[1].message:find("telescope", 1, true))
		end)

		it("reads the global option, not the workspace config", function()
			set_module("fzf-lua", {})
			set_module("snacks", {})
			config.setup({ picker = "snacks" })
			config.setup_workspace("work", { vault_path = "/work" })
			assert.are.equal("snacks", picker.resolve())
		end)
	end)

	describe("fzf backend", function()
		local calls

		before_each(function()
			calls = {}
			set_module("fzf-lua", {
				files = function(opts)
					table.insert(calls, { fn = "files", opts = opts })
				end,
				grep = function(opts)
					table.insert(calls, { fn = "grep", opts = opts })
				end,
				fzf_exec = function(items, opts)
					table.insert(calls, { fn = "fzf_exec", items = items, opts = opts })
				end,
			})
			config.setup({ picker = "fzf" })
		end)

		it("files scopes to cwd, excludes hidden paths and previews", function()
			picker.files({ title = "Find", cwd = "/vault" })
			local opts = calls[1].opts
			assert.are.equal("files", calls[1].fn)
			assert.are.equal("Find> ", opts.prompt)
			assert.are.equal("/vault", opts.cwd)
			assert.are.equal("builtin", opts.previewer)
			assert.is_not_nil(opts.cmd:find("-not -path '*/.*'", 1, true))
			assert.is_nil(opts.actions)
		end)

		it("files passes the first selected entry to actions", function()
			local got
			picker.files({
				title = "Link",
				cwd = "/vault",
				actions = {
					["ctrl-l"] = function(entry)
						got = entry
					end,
				},
			})
			local opts = calls[1].opts
			assert.is_false(opts.file_icons)
			opts.actions["ctrl-l"]({ "notes/a.md", "notes/b.md" })
			assert.are.equal("notes/a.md", got)
		end)

		it("grep scopes to cwd with preview", function()
			picker.grep({ title = "Search", cwd = "/vault" })
			assert.are.equal("grep", calls[1].fn)
			assert.are.equal("/vault", calls[1].opts.cwd)
			assert.are.equal("builtin", calls[1].opts.previewer)
		end)

		it("list previews only when asked", function()
			local noop = { default = function() end }
			picker.list({ "a" }, { title = "Plain", actions = noop })
			picker.list({ "a.md" }, { title = "Files", cwd = "/vault", preview = true, actions = noop })
			assert.is_nil(calls[1].opts.previewer)
			assert.are.equal("builtin", calls[2].opts.previewer)
			assert.are.equal("/vault", calls[2].opts.cwd)
		end)
	end)

	describe("snacks backend", function()
		local calls

		-- Minimal stand-in for a snacks picker instance
		local function fake_picker(item)
			return {
				closed = false,
				selected = function()
					return { item }
				end,
				close = function(self)
					self.closed = true
				end,
			}
		end

		before_each(function()
			calls = {}
			local function record(fn)
				return function(opts)
					table.insert(calls, { fn = fn, opts = opts })
				end
			end
			set_module("snacks", { picker = { files = record("files"), grep = record("grep"), pick = record("pick") } })
			config.setup({ picker = "snacks" })
		end)

		it("files uses find for *.md under cwd without hidden paths", function()
			picker.files({ title = "Find", cwd = "/vault" })
			local opts = calls[1].opts
			assert.are.equal("files", calls[1].fn)
			assert.are.equal("Find", opts.title)
			assert.are.equal("/vault", opts.cwd)
			assert.are.equal("find", opts.cmd)
			assert.are.equal("md", opts.ft)
			assert.is_false(opts.hidden)
			assert.is_nil(opts.actions)
		end)

		it("maps default to confirm and ctrl-l to <c-l>, closing before the callback", function()
			local got = {}
			picker.files({
				title = "Link",
				cwd = "/vault",
				actions = {
					default = function(entry)
						got.default = entry
					end,
					["ctrl-l"] = function(entry)
						got.link = entry
					end,
				},
			})
			local opts = calls[1].opts
			assert.is_function(opts.actions.confirm)
			local key = opts.win.input.keys["<c-l>"]
			assert.is_not_nil(key)
			assert.is_function(opts.actions[key[1]])

			local p = fake_picker({ file = "./notes/a.md", text = "./notes/a.md" })
			opts.actions.confirm(p)
			assert.is_true(p.closed)
			-- callback runs on the next tick, after the picker has closed
			assert.is_nil(got.default)
			vim.wait(100, function()
				return got.default ~= nil
			end)
			assert.are.equal("notes/a.md", got.default)

			opts.actions[key[1]](fake_picker({ file = "b.md", text = "b.md" }))
			vim.wait(100, function()
				return got.link ~= nil
			end)
			assert.are.equal("b.md", got.link)
		end)

		it("grep scopes to cwd", function()
			picker.grep({ title = "Search", cwd = "/vault" })
			assert.are.equal("grep", calls[1].fn)
			assert.are.equal("/vault", calls[1].opts.cwd)
		end)

		it("list builds file items with preview, or text items without", function()
			local noop = { default = function() end }
			picker.list({ "a.md" }, { title = "Files", cwd = "/vault", preview = true, actions = noop })
			picker.list({ "tag (1 files)" }, { title = "Tags", actions = noop })

			local files = calls[1].opts
			assert.are.equal("pick", calls[1].fn)
			assert.are.equal("file", files.preview)
			assert.are.equal("a.md", files.items[1].file)
			assert.are.equal("/vault", files.items[1].cwd)

			local tags = calls[2].opts
			assert.are.equal("none", tags.preview)
			assert.is_nil(tags.items[1].file)
			assert.are.equal("tag (1 files)", tags.items[1].text)
		end)
	end)
end)
