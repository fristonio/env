vim.pack.add({
	"https://github.com/catppuccin/nvim",
	"https://github.com/sainnhe/everforest",
	"https://github.com/nvim-lualine/lualine.nvim",
})

-- TODO: Maybe migrate to mini.icons?
if vim.g.have_nerd_font then
	vim.pack.add({ "https://github.com/nvim-tree/nvim-web-devicons" })
end

-- Setup colorscheme
require("catppuccin").setup({
	flavour = "frappe",
	no_underline = true,
	dim_inactive = {
		enabled = true, -- dims the background color of inactive window
		shade = "light",
		percentage = 0.25, -- percentage of the shade to apply to the inactive window
	},
})

-- vim.cmd.colorscheme("catppuccin-nvim")
vim.cmd.colorscheme("everforest")

-- Setup statusline
require("lualine").setup({
	options = {
		icons_enabled = vim.g.have_nerd_font,
		theme = "auto",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { "filename" },
		lualine_x = { "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
})
