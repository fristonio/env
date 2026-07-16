-- Telescope configuration.
local telescope_plugins = {
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/nvim-telescope/telescope-ui-select.nvim",
	"https://github.com/nvim-telescope/telescope-live-grep-args.nvim",
}

if vim.fn.executable("make") == 1 then
	table.insert(telescope_plugins, "https://github.com/nvim-telescope/telescope-fzf-native.nvim")

	local function run_build(name, cmd, cwd)
		local result = vim.system(cmd, { cwd = cwd }):wait()
		if result.code ~= 0 then
			local stderr = result.stderr or ""
			local stdout = result.stdout or ""
			local output = stderr ~= "" and stderr or stdout
			if output == "" then
				output = "No output from build command."
			end
			vim.notify(("Build failed for %s:\n%s"):format(name, output), vim.log.levels.ERROR)
		end
	end

	vim.api.nvim_create_autocmd("PackChanged", {
		callback = function(ev)
			local kind = ev.data.kind
			if kind ~= "install" and kind ~= "update" then
				return
			end

			local name = ev.data.spec.name
			if name == "telescope-fzf-native.nvim" then
				run_build(name, { "make" }, ev.data.path)
				return
			end
		end,
	})
end

-- See `:help telescope` and `:help telescope.setup()`
vim.pack.add(telescope_plugins)

local telescope = require("telescope")
local themes = require("telescope.themes")

local live_grep_args_actions = require("telescope-live-grep-args.actions")

telescope.setup({
	defaults = {
		layout_strategy = "horizontal",
		layout_config = {
			horizontal = {
				prompt_position = "top",
			},
		},
		sorting_strategy = "ascending",
		file_ignore_patterns = {
			"^node_modules/",
			"^%.git/",
			"^vendor/",
		},
		prompt_prefix = "   ",
		selection_caret = "  ",
	},
	pickers = {
		-- picker configuration for builtin.builtin picker.
		-- This picker lets us choose between the pickers available in telescope.
		builtin = {
			previewer = false,
			layout_config = {
				width = 0.4,
				height = 0.4,
			},
		},
		diagnostics = {
			wrap_results = true,
			line_width = "full",
			layout_config = {
				preview_width = 0.4,
			},
			sort_by = "severity",
		},
		find_files = {
			-- Make hidden file searchable, but still ignore gitignored files.
			hidden = true,
			no_ignore = false, -- Respect .gitignore
			previewer = false,
			layout_config = {
				width = 0.5,
				height = 0.5,
				preview_width = 0.6,
			},
		},
		buffers = {
			theme = "ivy",
			layout_config = {
				preview_width = 0.6,
			},
			-- ignore_current_buffer = true,
		},
		commands = { theme = "ivy" },
		colorscheme = {
			layout_config = {
				width = 0.4,
				height = 0.4,
			},
		},
		help_tags = {
			layout_config = {
				height = 0.75,
			},
		},
	},
	extensions = {
		["ui-select"] = { themes.get_dropdown() },
		live_grep_args = {
			auto_quoting = true,
			hidden = true,
			mappings = {
				i = {
					["<C-k>"] = live_grep_args_actions.quote_prompt(),
					["<C-i>"] = live_grep_args_actions.quote_prompt({ postfix = " --iglob " }),
					["<C-t>"] = live_grep_args_actions.quote_prompt({ postfix = " -t" }),
					-- Freeze the current list and start a fuzzy search in the frozen list
					["<C-space>"] = live_grep_args_actions.to_fuzzy_refine,
				},
			},
		},
	},
})

-- Enable Telescope extensions if they are installed
telescope.load_extension("fzf")
telescope.load_extension("ui-select")
telescope.load_extension("live_grep_args")

-- See `:help telescope.builtin`
local builtin = require("telescope.builtin")
local utils = require("telescope.utils")

local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
vim.keymap.set("n", "<leader>fF", function()
	builtin.find_files({
		cwd = utils.buffer_dir(),
		prompt_title = "Find Files in current buffer dir",
	})
end, { desc = "[F]ind files in current buffer directory" })

vim.keymap.set("n", "<leader>fb", function()
	builtin.buffers({ sort_lastused = true })
end, { desc = "[F]ind [B]uffers" })

vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[F]ind [R]esume" })

vim.keymap.set(
	"n",
	"<leader>fw",
	live_grep_args_shortcuts.grep_word_under_cursor,
	{ desc = "[F]ind current [W]ord with args" }
)
vim.keymap.set(
	"v",
	"<leader>fv",
	live_grep_args_shortcuts.grep_visual_selection,
	{ desc = "[F]ind current [V]isual selection" }
)

vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Fuzzily search in current buffer" })
vim.keymap.set(
	"n",
	"<leader>f/",
	require("telescope").extensions.live_grep_args.live_grep_args,
	{ desc = "Live Grep in workspace root" }
)
vim.keymap.set("n", "<leader>f.", function()
	require("telescope").extensions.live_grep_args.live_grep_args({
		cwd = utils.buffer_dir(),
		prompt_title = "Live Grep in current buffer directory",
	})
end, { desc = "Live Grep in current buffer directory" })
vim.keymap.set("n", "<leader>fg", function()
	require("telescope").extensions.live_grep_args.live_grep_args({
		grep_open_files = true,
		prompt_title = "Live Grep in Open Files",
	})
end, { desc = "Live Grep in Open Files" })

vim.keymap.set("n", "<leader>fd", function()
	builtin.diagnostics({ bufnr = 0 })
end, { desc = "[F]ind [D]iagnostic in current file" })
vim.keymap.set("n", "<leader>fD", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })

vim.keymap.set("n", "<leader>fs", builtin.builtin, { desc = "[F]ind [S]elect Telescope" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "[F]ind [C]ommands" })

vim.keymap.set("n", "<leader>pt", builtin.colorscheme, { desc = "Pick [TH]eme" })
vim.keymap.set("n", "<leader>pr", builtin.resume, { desc = "Telescope [P]icker [R]esume" })

-- Shortcut for searching Neovim configuration files
vim.keymap.set("n", "<leader>fn", function()
	builtin.find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Search [N]eovim files" })

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

		map("<leader>ls", function()
			builtin.lsp_document_symbols({
				symbol_width = 0.7,
				symbol_type_width = 0.3,
			})
		end, "Explore current document symbols")
		map("<leader>lS", function()
			builtin.lsp_dynamic_workspace_symbols({
				symbol_width = 0.7,
				symbol_type_width = 0.3,
			})
		end, "Explore current document symbols")
	end,
})

local has_diffview = pcall(require, "diffview")
if has_diffview then
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	-- Diff against a branch selected via Telescope
	vim.keymap.set("n", "<leader>db", function()
		telescope.git_branches({
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd("DiffviewOpen " .. selection.value)
				end)
				return true
			end,
		})
	end, { desc = "Diffview branch" })

	-- File history for a commit selected via Telescope
	vim.keymap.set("n", "<leader>dc", function()
		telescope.git_commits({
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd("DiffviewOpen " .. selection.value .. "^!")
				end)
				return true
			end,
		})
	end, { desc = "Diffview commit" })

	-- Open commit range <selected-commit>..HEAD in diffview
	vim.keymap.set("n", "<leader>dr", function()
		telescope.git_commits({
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd("DiffviewOpen " .. selection.value .. "..HEAD")
				end)
				return true
			end,
		})
	end, { desc = "Diffview commit" })
end
