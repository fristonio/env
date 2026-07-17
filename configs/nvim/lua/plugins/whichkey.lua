vim.pack.add({ "https://github.com/folke/which-key.nvim" })

require("which-key").setup({
	-- Automatically trigger which key on key presses(disabled in visual mode).
	triggers = { "<auto>", mode = "nisotc" },
	-- Delay between pressing a key and opening which-key (milliseconds)
	delay = 250,
	preset = "helix", -- helix, modern, classic
	icons = { mappings = vim.g.have_nerd_font },
	-- Document existing key chains
	spec = {
		{ "<leader>w", group = "Window Actions", mode = { "n", "v" }, proxy = "<C-w>" },
		{ "<leader>l", group = "LSP Actions", mode = { "n" } },
		{ "<leader>h", group = "Git Hunks Actions", mode = { "n" } },
		{ "<leader>f", group = "Finder Actions", mode = { "n", "v" } },
		{ "<leader>p", group = "Picker Actions", mode = { "n" } },
		{ "<leader>c", group = "Copy Actions", mode = { "n" } },
		{ "<leader>v", group = "DiffView Actions", mode = { "n" } },
	},
	filter = function(mapping)
		return mapping.desc ~= "diffview_ignore"
	end,
})

vim.keymap.set("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "WhichKey all keymaps" })
vim.keymap.set("n", "<leader>wk", function()
	vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "WhichKey query lookup" })
vim.keymap.set("n", "<leader>?", function()
	require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
