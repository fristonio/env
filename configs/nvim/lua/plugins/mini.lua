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

-- Open mini.files in the directory of the current active file
vim.keymap.set("n", "<leader>E", function()
	require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
end, { desc = "Open mini.files (current file directory)" })

-- Open mini.files in the current working directory (cwd)
vim.keymap.set("n", "<leader>e", function()
	require("mini.files").open(vim.uv.cwd(), true)
end, { desc = "Open mini.files (cwd)" })

-- Other useful plugins
require("mini.surround").setup()
require("mini.pairs").setup()
