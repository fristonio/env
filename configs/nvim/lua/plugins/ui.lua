vim.pack.add({
	-- Themes
	"https://github.com/catppuccin/nvim",
	"https://github.com/neanias/everforest-nvim",
	"https://github.com/navarasu/onedark.nvim",
	"https://github.com/mellow-theme/mellow.nvim",

	-- Statusline
	"https://github.com/nvim-lualine/lualine.nvim",
})

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

-- OneDark theme
require("onedark").setup({
	style = "warmer",
})

-- Everforest theme
require("everforest").setup({
	-- TODO: Dimming doesn't work correctly.
	-- dim_inactive_windows = true,
	background = "medium",
	on_highlights = function(hl, palette)
		hl.DiffText = { fg = palette.bg_purple }
	end,
})

-- Set default colorscheme.
vim.cmd.colorscheme("everforest")
