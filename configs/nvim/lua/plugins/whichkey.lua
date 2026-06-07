vim.pack.add({ "https://github.com/folke/which-key.nvim" })

require("which-key").setup({
	triggers = { "<auto>", mode = "nisotc" },
	-- Delay between pressing a key and opening which-key (milliseconds)
	delay = 100,
	preset = "helix", -- helix, modern, classic
	icons = { mappings = vim.g.have_nerd_font },
	-- icons = { mappings = false },
	-- Document existing key chains
	spec = {
		{ "<leader>w", group = "[W]indow", mode = { "n", "v" }, proxy = "<C-w>" },
		{ "<leader>f", group = "[F]inder", mode = { "n", "v" } },
	},
})

vim.keymap.set("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "WhichKey all keymaps" })
vim.keymap.set("n", "<leader>wk", function()
	vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "WhichKey query lookup" })
vim.keymap.set("n", "<leader>?", function()
	require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
