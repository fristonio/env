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
