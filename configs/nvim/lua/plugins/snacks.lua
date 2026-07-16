vim.pack.add({
	"https://github.com/folke/snacks.nvim",
})

local snacks = require("snacks")

snacks.setup({
	picker = {
		enabled = true,
		ui_select = true, -- vim.ui.select using snacks
		sources = {
			files = {
				hidden = true,
				ignored = false,
				layout = "select",
			},
			buffers = {
				layout = "select",
				format = function(item, picker)
					-- Disable buffer index and column number in list.
					item.idx = nil
					if item.pos then
						item.pos[2] = 0
					end
					return Snacks.picker.format.file(item, picker)
				end,
			},
			colorschemes = {
				layout = "select",
			},
			pickers = {
				layout = "select",
			},
			keymaps = {
				layout = {
					preset = "ivy",
					hidden = { "preview" },
				},
			},
			command_history = {
				layout = {
					preset = "select",
				},
			},
			commands = {
				layout = "select",
			},
		},
	},
})

-- Helper to get current buffer's directory
local function buffer_dir()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname == "" then
		return vim.fn.getcwd()
	end
	return vim.fs.dirname(bufname)
end

vim.keymap.set("n", "<leader>fe", snacks.picker.explorer, { desc = "Open file explorer" })

vim.keymap.set("n", "<leader>ff", snacks.picker.files, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fF", function()
	snacks.picker.files({
		cwd = buffer_dir(),
		title = "Files (Current buffer dir)",
	})
end, { desc = "Find files in current buffer directory" })

vim.keymap.set("n", "<leader>fo", snacks.picker.smart, { desc = "Smart finder" })

vim.keymap.set("n", "<leader>fb", function()
	snacks.picker.buffers({ sort_mru = true })
end, { desc = "Find Buffers" })

vim.keymap.set("n", "<leader>fr", snacks.picker.resume, { desc = "Find Resume" })

vim.keymap.set({ "n", "v" }, "<leader>fw", snacks.picker.grep_word, { desc = "Find current Word with args" })
vim.keymap.set("v", "<leader>fv", snacks.picker.grep_word, { desc = "Find current visual selction" })

vim.keymap.set("n", "<leader>/", snacks.picker.lines, { desc = "Fuzzily search in current buffer" })
vim.keymap.set("n", "<leader>f/", function()
	snacks.picker.grep({
		-- Passing ripgrep args works natively in prompt (e.g. type: foo -- -g "*.lua")
		hidden = true,
		ignored = false,
	})
end, { desc = "Live Grep in workspace root" })

vim.keymap.set("n", "<leader>f.", function()
	snacks.picker.grep({
		cwd = buffer_dir(),
		hidden = true,
		title = "Live Grep in current buffer directory",
	})
end, { desc = "Live Grep in current buffer directory" })

vim.keymap.set("n", "<leader>fg", snacks.picker.grep_buffers, { desc = "Live Grep in Open Files" })

vim.keymap.set("n", "<leader>fd", snacks.picker.diagnostics_buffer, { desc = "Find Diagnostic in current file" })
vim.keymap.set("n", "<leader>fD", snacks.picker.diagnostics, { desc = "Find Diagnostics" })

vim.keymap.set("n", "<leader>fs", snacks.picker.pickers, { desc = "Select finder" })

vim.keymap.set("n", "<leader>fh", snacks.picker.help, { desc = "Find neovim help" })

vim.keymap.set("n", "<leader>fk", snacks.picker.keymaps, { desc = "Find keymaps" })

vim.keymap.set("n", "<leader>f;", snacks.picker.command_history, { desc = "Command History" })
vim.keymap.set("n", "<leader>fc", snacks.picker.commands, { desc = "Command Panel" })

vim.keymap.set("n", "<leader>pt", snacks.picker.colorschemes, { desc = "Pick Theme" })
vim.keymap.set("n", "<leader>pr", snacks.picker.resume, { desc = "Resume Picker" })

vim.keymap.set("n", "<leader>fn", function()
	snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Search Neovim files" })

-- LSP Attach mappings
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("snacks-lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
		end

		map("gd", snacks.picker.lsp_definitions, "[G]oto [D]efinition")
		map("gI", snacks.picker.lsp_implementations, "[G]oto [I]mplementation")
		map("gR", snacks.picker.lsp_references, "[G]oto [R]eferences")

		map("<leader>ld", snacks.picker.lsp_definitions, "Goto [L]SP [D]efinition")
		map("<leader>lI", snacks.picker.lsp_implementations, "Goto [L]SP [I]mplementation")
		map("<leader>lR", snacks.picker.lsp_references, "Goto [R]eferences")
		map("<leader>lt", snacks.picker.lsp_type_definitions, "Goto [L]SP [T]ype definitions")

		map("<leader>ls", snacks.picker.lsp_symbols, "Explore current document symbols")
		map("<leader>lS", snacks.picker.lsp_workspace_symbols, "Explore workspace symbols")
	end,
})
