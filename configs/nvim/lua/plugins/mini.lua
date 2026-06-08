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

-- Other useful plugins
require("mini.surround").setup()
require("mini.pairs").setup()
require("mini.notify").setup()

-- Extra stuff to explore
--
-- require("mini.ai").setup()
-- require("mini.indentscope").setup()
