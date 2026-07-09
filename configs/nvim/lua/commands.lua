-- Toggle list chars. See options.lua for the characters configured.
vim.api.nvim_create_user_command("ToggleLcs", function()
	vim.opt.list = not vim.opt.list._value
end, { nargs = 0, desc = "Toggle Vim ListChars" })

-- Toggle Ruler at 80 and 120 columns for indications.
vim.api.nvim_create_user_command("ToggleRuler", function()
	if vim.opt.colorcolumn._value == "" then
		vim.opt.colorcolumn = "80,120"
	else
		vim.opt.colorcolumn = ""
	end
end, { nargs = 0, desc = "Toggle colored columns at 80 and 120 column length" })

vim.api.nvim_create_user_command("ToggleCompletion", function()
	vim.b.completion = not vim.b.completion
end, { nargs = 0, desc = "Toggle vim global completion(applied to the buffer)" })

vim.api.nvim_create_user_command("Term", function()
	vim.cmd.new()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, math.floor(vim.o.lines * 0.25))
	vim.wo.winfixheight = true
	vim.cmd.term()
end, { nargs = 0, desc = "Open a terminal in vertical split" })

vim.api.nvim_create_user_command("TermV", function()
	vim.cmd.new()
	vim.cmd.wincmd("L")
	vim.api.nvim_win_set_width(0, math.floor(vim.o.columns * 0.3))
	vim.wo.winfixwidth = true
	vim.cmd.term()
end, { nargs = 0, desc = "Open a terminal in vertical split" })

-- nvim pack user commands

-- 1. Command to install/load a plugin temporarily from the command line
-- Usage: :PackAdd https://github.com/nvim-mini/mini.nvim
vim.api.nvim_create_user_command("PackAdd", function(opts)
	if opts.args == "" then
		vim.notify("Please provide a plugin URL", vim.log.levels.ERROR)
		return
	end
	vim.pack.add({ opts.args })
end, { nargs = 1 })

-- 2. Command to open the interactive plugin updater buffer
-- Usage: :PackUpdate (or :PackUpdate plugin-name)
vim.api.nvim_create_user_command("PackUpdate", function(opts)
	local args = vim.split(opts.args, "%s+", { trimempty = true })
	vim.pack.update(args)
end, {
	nargs = "*",
	complete = function(ArgLead, CmdLine, CursorPos)
		-- Autocomplete with currently installed plugins
		local installed = vim.pack.get()
		local names = {}
		for _, plugin in ipairs(installed) do
			if plugin.spec.name:find(ArgLead, 1, true) then
				table.insert(names, plugin.spec.name)
			end
		end
		return names
	end,
})

-- 3. Command to delete a managed plugin
-- Usage: :PackDelete plugin-name
vim.api.nvim_create_user_command("PackDelete", function(opts)
	if opts.args == "" then
		vim.notify("Please provide a plugin name to delete", vim.log.levels.ERROR)
		return
	end
	vim.pack.del({ opts.args })
end, {
	nargs = 1,
	complete = function(ArgLead, CmdLine, CursorPos)
		local installed = vim.pack.get()
		local names = {}
		for _, plugin in ipairs(installed) do
			if plugin.spec.name:find(ArgLead, 1, true) then
				table.insert(names, plugin.spec.name)
			end
		end
		return names
	end,
})

-- 4. Command to list all managed plugins and their status
-- Usage: :PackStatus
vim.api.nvim_create_user_command("PackStatus", function()
	local plugins = vim.pack.get()
	if #plugins == 0 then
		print("No plugins managed by vim.pack yet.")
		return
	end

	print("--- Managed Plugins ---")
	for _, plugin in ipairs(plugins) do
		local status = plugin.active and " [Loaded]" or " [Not Loaded]"
		print(string.format("- %s (%s)%s", plugin.spec.name, plugin.spec.src, status))
	end
end, {})
