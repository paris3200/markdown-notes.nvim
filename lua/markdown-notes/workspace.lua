local config = require("markdown-notes.config")

local M = {}

function M.show_current_workspace()
	local options, current_workspace = config.get_current_config()
	local default_workspace = config.get_default_workspace()

	if current_workspace then
		local default_indicator = (current_workspace == default_workspace) and " (default)" or ""
		vim.notify(
			"Current workspace: " .. current_workspace .. default_indicator ..
			" (" .. options.vault_path .. ")",
			vim.log.levels.INFO
		)
	else
		vim.notify("Using fallback configuration (no workspace detected)", vim.log.levels.INFO)
	end
end

function M.set_default_workspace(workspace_name)
	if config.set_default_workspace(workspace_name) then
		vim.notify("Set default workspace to: " .. workspace_name, vim.log.levels.INFO)
	end
end

function M.set_active_workspace(workspace_name)
	if config.set_active_workspace(workspace_name) then
		local workspace = config.get_workspaces()[workspace_name]
		local vault_path = vim.fn.expand(workspace.vault_path)
		vim.cmd("cd " .. vim.fn.fnameescape(vault_path))
		vim.notify("Switched to workspace: " .. workspace_name, vim.log.levels.INFO)
	end
end

function M.show_default_workspace()
	local default_workspace = config.get_default_workspace()
	if default_workspace then
		vim.notify("Default workspace: " .. default_workspace, vim.log.levels.INFO)
	else
		vim.notify("No default workspace set", vim.log.levels.INFO)
	end
end

function M.switch_to_workspace(workspace_name)
	local workspaces = config.get_workspaces()

	if not workspaces[workspace_name] then
		vim.notify("Workspace '" .. workspace_name .. "' not found", vim.log.levels.ERROR)
		return
	end

	local workspace = workspaces[workspace_name]
	local vault_path = vim.fn.expand(workspace.vault_path)

	if vim.fn.isdirectory(vault_path) == 0 then
		vim.notify("Workspace directory does not exist: " .. vault_path, vim.log.levels.ERROR)
		return
	end

	-- Set as active workspace and change directory
	M.set_active_workspace(workspace_name)
end

function M.pick_workspace()
	local workspaces = config.get_workspaces()

	if vim.tbl_isempty(workspaces) then
		vim.notify("No workspaces configured", vim.log.levels.INFO)
		return
	end

	local ok, fzf = pcall(require, "fzf-lua")
	if not ok then
		vim.notify("fzf-lua not available", vim.log.levels.ERROR)
		return
	end

	local workspace_list = {}
	for name, workspace in pairs(workspaces) do
		table.insert(workspace_list, name .. " - " .. workspace.vault_path)
	end

	fzf.fzf_exec(workspace_list, {
		prompt = "Select Workspace> ",
		actions = {
			["default"] = function(selected)
				if selected and #selected > 0 then
					local workspace_name = selected[1]:match("^([^%-]+)")
					workspace_name = workspace_name:gsub("%s+$", "") -- trim trailing whitespace
					M.switch_to_workspace(workspace_name)
				end
			end,
		},
	})
end

return M
