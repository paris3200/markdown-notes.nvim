-- Fuzzy picker adapter: routes the plugin's pickers to fzf-lua or snacks.nvim.
--
-- Every picker takes `opts`:
--   title    (string) picker title
--   cwd      (string) directory entries are relative to
--   preview  (boolean, list only) entries are files under cwd; show a preview
--   actions  (table, optional) { default = fn(entry), ["ctrl-l"] = fn(entry) }
--            `entry` is the selected string (a path relative to cwd for files).
--            Without actions, file pickers use the backend's default file open.
local config = require("markdown-notes.config")

local M = {}

local backends = {
	fzf = { module = "fzf-lua", plugin = "fzf-lua" },
	snacks = { module = "snacks", plugin = "snacks.nvim" },
}

-- Matches *.md files below cwd, skipping hidden files and directories
local FIND_MD = "find . -name '*.md' -type f -not -path '*/.*' -printf '%P\\n'"

local function load(name)
	local ok, mod = pcall(require, backends[name].module)
	if ok then
		return mod
	end
end

-- Resolve the configured backend. Returns name, module or nil when unavailable.
function M.resolve()
	local choice = (config.options and config.options.picker) or config.defaults.picker

	if choice == "auto" then
		for _, name in ipairs({ "fzf", "snacks" }) do
			local mod = load(name)
			if mod then
				return name, mod
			end
		end
		vim.notify("markdown-notes: no picker found, install fzf-lua or snacks.nvim", vim.log.levels.ERROR)
		return nil
	end

	if not backends[choice] then
		vim.notify(
			"markdown-notes: unknown picker '" .. tostring(choice) .. "' (expected \"fzf\", \"snacks\" or \"auto\")",
			vim.log.levels.ERROR
		)
		return nil
	end

	local mod = load(choice)
	if not mod then
		vim.notify(
			"markdown-notes: picker '" .. choice .. "' requires " .. backends[choice].plugin .. ", which is not installed",
			vim.log.levels.ERROR
		)
		return nil
	end
	return choice, mod
end

-- fzf-lua ------------------------------------------------------------------

local function fzf_actions(actions)
	if not actions then
		return nil
	end
	local ret = {}
	for key, fn in pairs(actions) do
		ret[key] = function(selected)
			if selected and #selected > 0 then
				fn(selected[1])
			end
		end
	end
	return ret
end

local fzf = {}

function fzf.files(lib, opts)
	local fzf_opts = {
		prompt = opts.title .. "> ",
		cwd = opts.cwd,
		cmd = FIND_MD,
		previewer = "builtin",
	}
	if opts.actions then
		-- Plain entries so action callbacks receive bare paths
		fzf_opts.file_icons = false
		fzf_opts.path_shorten = false
		fzf_opts.actions = fzf_actions(opts.actions)
	end
	lib.files(fzf_opts)
end

function fzf.grep(lib, opts)
	lib.grep({
		prompt = opts.title .. "> ",
		cwd = opts.cwd,
		previewer = "builtin",
	})
end

function fzf.list(lib, items, opts)
	lib.fzf_exec(items, {
		prompt = opts.title .. "> ",
		cwd = opts.cwd,
		previewer = opts.preview and "builtin" or nil,
		actions = fzf_actions(opts.actions),
	})
end

-- snacks.nvim --------------------------------------------------------------

-- Convert snacks action specs: close the picker, then run the callback on the
-- next tick so it acts on the original window (and can open another picker).
local function snacks_actions(actions, get_entry)
	if not actions then
		return {}
	end
	local spec = { actions = {}, keys = {} }
	for key, fn in pairs(actions) do
		local name = key == "default" and "confirm" or ("markdown_notes_" .. key:gsub("%W", "_"))
		spec.actions[name] = function(p)
			local item = p:selected({ fallback = true })[1]
			p:close()
			if item then
				local entry = get_entry(item)
				vim.schedule(function()
					fn(entry)
				end)
			end
		end
		local ctrl = key:match("^ctrl%-(%w)$")
		if ctrl then
			spec.keys["<c-" .. ctrl .. ">"] = { name, mode = { "n", "i" } }
		end
	end
	return spec
end

local function snacks_opts(base, actions, get_entry)
	local spec = snacks_actions(actions, get_entry)
	if spec.actions then
		base.actions = spec.actions
		if next(spec.keys) then
			base.win = { input = { keys = spec.keys }, list = { keys = spec.keys } }
		end
	end
	return base
end

local function file_entry(item)
	return (item.file:gsub("^%./", ""))
end

local snacks = {}

function snacks.files(lib, opts)
	lib.picker.files(snacks_opts({
		title = opts.title,
		cwd = opts.cwd,
		-- find matches the fzf backend: no .gitignore filtering, skip hidden paths
		cmd = "find",
		ft = "md",
		hidden = false,
	}, opts.actions, file_entry))
end

function snacks.grep(lib, opts)
	lib.picker.grep({
		title = opts.title,
		cwd = opts.cwd,
	})
end

function snacks.list(lib, items, opts)
	local entries = {}
	for i, text in ipairs(items) do
		entries[i] = { idx = i, text = text, file = opts.preview and text or nil, cwd = opts.cwd }
	end
	lib.picker.pick(snacks_opts({
		title = opts.title,
		items = entries,
		cwd = opts.cwd,
		format = opts.preview and "file" or "text",
		preview = opts.preview and "file" or "none",
		layout = not opts.preview and { preview = false } or nil,
	}, opts.actions, function(item)
		return item.text
	end))
end

local impl = { fzf = fzf, snacks = snacks }

--- Pick a markdown file under opts.cwd (hidden paths excluded), with preview.
function M.files(opts)
	local name, lib = M.resolve()
	if name then
		impl[name].files(lib, opts)
	end
end

--- Grep file contents under opts.cwd, with preview.
function M.grep(opts)
	local name, lib = M.resolve()
	if name then
		impl[name].grep(lib, opts)
	end
end

--- Pick from a list of strings.
function M.list(items, opts)
	local name, lib = M.resolve()
	if name then
		impl[name].list(lib, items, opts)
	end
end

return M
