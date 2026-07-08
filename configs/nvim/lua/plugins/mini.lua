-- Setup mini plugins for neovim.
-- See :help mini.nvim for more details.
vim.pack.add({ "https://github.com/nvim-mini/mini.nvim" })

-- Setup mini file explorer(maybe neo-tree someday)
require("mini.files").setup({
	mappings = {
		close = "<Esc>",
		go_in_plus = "<Enter>",
		reset = "<BS>",
		reveal_cwd = "@",
		show_help = "g?",
		synchronize = "=",
	},
	options = {
		use_as_default_explorer = false,
	},
})

vim.keymap.set("n", "<leader>E", function()
	require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
end, { desc = "Open File [E]xplorer (current file directory)" })

vim.keymap.set("n", "<leader>e", function()
	require("mini.files").open(vim.uv.cwd(), true)
end, { desc = "Open File [E]xplorer (cwd)" })

require("mini.hipatterns").setup({
	highlighters = {
		-- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
	},
})

require("mini.notify").setup()
vim.g.mininotify_disable = true -- Disable by default
vim.api.nvim_create_user_command("ToggleNotify", function()
	vim.g.mininotify_disable = not vim.g.mininotify_disable
end, { desc = "Toggle mini.notify" })

-- Only show tabline when there are atleast two tabs
require("mini.tabline").setup()
vim.opt.showtabline = 1

-- Other useful plugins
require("mini.surround").setup()
require("mini.pairs").setup()
require("mini.ai").setup()

-- Extra stuff to explore
--
-- require("mini.indentscope").setup()
