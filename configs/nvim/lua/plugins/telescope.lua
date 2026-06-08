-- Telescope configuration.
local telescope_plugins = {
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/nvim-telescope/telescope-ui-select.nvim",

	-- Complementry plugin to navigate buffer symbols.
	"https://github.com/stevearc/aerial.nvim",
}
if vim.fn.executable("make") == 1 then
	table.insert(telescope_plugins, "https://github.com/nvim-telescope/telescope-fzf-native.nvim")
end

-- See `:help telescope` and `:help telescope.setup()`
vim.pack.add(telescope_plugins)
require("telescope").setup({
	defaults = {
		layout_strategy = "horizontal",
		layout_config = {
			horizontal = {
				prompt_position = "top",
			},
		},
		sorting_strategy = "ascending",
	},
	pickers = {
		-- picker configuration for builtin.builtin picker.
		-- This picker lets us choose between the pickers available in telescope.
		builtin = {
			previewer = false,
			theme = "ivy",
		},
		diagnostics = {
			wrap_results = true,
			line_width = "full",
			layout_config = {
				preview_width = 0.4,
			},
		},
		buffers = { theme = "ivy" },
		commands = { theme = "ivy" },
		colorscheme = { theme = "ivy" },
	},
	extensions = {
		["ui-select"] = { require("telescope.themes").get_dropdown() },
	},
})

-- Configure plugin for buffer symbol outlines(similar to zed outline panel)
-- require("aerial").setup({})

-- Enable Telescope extensions if they are installed
pcall(require("telescope").load_extension, "fzf")
pcall(require("telescope").load_extension, "ui-select")
pcall(require("telescope").load_extension, "aerial")

-- See `:help telescope.builtin`
local builtin = require("telescope.builtin")
local utils = require("telescope.utils")
local themes = require("telescope.themes")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "[F]ind [B]uffers" })
vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[F]ind [R]esume" })
vim.keymap.set("n", "<leader>pr", builtin.resume, { desc = "Telescope [P]icker [R]esume" })

vim.keymap.set({ "n", "v" }, "<leader>fw", builtin.grep_string, { desc = "[F]ind current [W]ord" })

vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
vim.keymap.set("n", "<leader>fs", builtin.builtin, { desc = "[F]ind [S]elect Telescope" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind by [G]rep" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
vim.keymap.set("n", "<leader>f.", builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "[F]ind [C]ommands" })

vim.keymap.set("n", "<leader>pt", builtin.colorscheme, { desc = "Pick [TH]eme" })

-- Override default behavior and theme when searching
vim.keymap.set("n", "<leader>/", function()
	-- You can pass additional configuration to Telescope to change the theme, layout, etc.
	builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "Fuzzily search in current buffer" })

-- It's also possible to pass additional configuration options.
--  See `:help telescope.builtin.live_grep()` for information about particular keys
vim.keymap.set("n", "<leader>f/", function()
	builtin.live_grep({
		grep_open_files = true,
		prompt_title = "Live Grep in Open Files",
	})
end, { desc = "Search in Open Files" })

vim.keymap.set("n", "<leader>fe", function()
	builtin.find_files({
		cwd = utils.buffer_dir(),
		prompt_title = "Find Files in current buffer dir",
	})
end, { desc = "[F]ind files in current buffer directory" })

-- Shortcut for searching Neovim configuration files
vim.keymap.set("n", "<leader>fn", function()
	builtin.find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "[S]earch [N]eovim files" })

-- Telescope LSP
-- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
		end

		-- Shorthand keymappings
		map("gd", builtin.lsp_definitions, "[G]oto [D]efinition")
		map("gI", builtin.lsp_implementations, "[G]oto [I]mplementation")
		map("gR", builtin.lsp_references, "[G]oto [R]eferences")

		-- LSP actions keymappings.
		map("<leader>ld", builtin.lsp_definitions, "Goto [L]SP [D]efinition")
		map("<leader>lI", builtin.lsp_implementations, "Goto [L]SP [I]mplementation")
		map("<leader>lR", builtin.lsp_references, "Goto [L]SP [R]eferences")
		map("<leader>lt", builtin.lsp_type_definitions, "Goto [L]SP [T]ype definitions")

		map("<leader>ls", builtin.lsp_document_symbols, "Explore current document symbols")
		map("<leader>lS", builtin.lsp_dynamic_workspace_symbols, "Explore current workspace symbols")
	end,
})
