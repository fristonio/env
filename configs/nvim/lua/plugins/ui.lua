vim.pack.add({
	-- Themes
	"https://github.com/catppuccin/nvim",
	"https://github.com/sainnhe/everforest",
	"https://github.com/navarasu/onedark.nvim",

	-- Statusline
	"https://github.com/nvim-lualine/lualine.nvim",
})

-- TODO: Maybe migrate to mini.icons?
if vim.g.have_nerd_font then
	vim.pack.add({ "https://github.com/nvim-tree/nvim-web-devicons" })
end

-- Setup statusline
require("lualine").setup({
	options = {
		icons_enabled = vim.g.have_nerd_font,
		theme = "auto",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { { "filename", path = 1, shorting_target = 0 } },
		lualine_x = { "lsp_status", "fileformat", "filetype" },
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

-- Setup colorschemes.
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

-- OneDark theme
require("onedark").setup({
	style = "warm",
})

-- Everforest theme
-- vim.g.everforest_dim_inactive_windows = 1

local configuration = vim.fn["everforest#get_configuration"]()
local palette = vim.fn["everforest#get_palette"](configuration.background, configuration.colors_override)

vim.api.nvim_set_hl(0, "DiffText", { bg = palette.bg_purple[1] })
vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = palette.bg3[1] })

-- Set colorscheme
vim.cmd.colorscheme("everforest")
