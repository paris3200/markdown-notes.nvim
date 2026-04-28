local config = require("markdown-notes.config")

local function normalize(key)
	-- Normalize to lowercase for prefix comparison since <Leader> vs <leader> etc.
	-- but preserve the structure — only collapse modifier case
	return key:gsub("<[Ll]eader>", "<leader>"):gsub("<[Cc][Rr]>", "<CR>")
end

local function is_prefix(shorter, longer)
	return shorter ~= longer and longer:sub(1, #shorter) == shorter
end

describe("keybindings", function()
	it("default mappings have no prefix conflicts", function()
		local mappings = config.defaults.mappings
		local bindings = {}

		for action, key in pairs(mappings) do
			table.insert(bindings, { action = action, key = normalize(key) })
		end

		local conflicts = {}
		for i = 1, #bindings do
			for j = i + 1, #bindings do
				local a, b = bindings[i], bindings[j]
				if is_prefix(a.key, b.key) then
					table.insert(conflicts, string.format("'%s' (%s) is a prefix of '%s' (%s)", a.key, a.action, b.key, b.action))
				elseif is_prefix(b.key, a.key) then
					table.insert(conflicts, string.format("'%s' (%s) is a prefix of '%s' (%s)", b.key, b.action, a.key, a.action))
				end
			end
		end

		assert.are.equal(0, #conflicts, "Keybinding prefix conflicts detected:\n  " .. table.concat(conflicts, "\n  "))
	end)
end)
