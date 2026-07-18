vim.pack.add({
	"https://github.com/folke/snacks.nvim",
})

local snacks = require("snacks")

local layouts = {
	select = function(width, height)
		return {
			hidden = { "preview" },
			layout = {
				backdrop = {
					transparent = true,
					blend = 95,
				},
				width = width or 0.5,
				min_width = 80,
				max_width = 100,
				height = height or 0.4,
				min_height = 2,
				box = "vertical",
				border = true,
				title = "{title}",
				title_pos = "center",
				{ win = "input", height = 1, border = "bottom" },
				{ win = "list", border = "none" },
				{ win = "preview", title = "{preview}", height = 0.4, border = "top" },
			},
		}
	end,
	ivy = function()
		return {
			layout = {
				box = "vertical",
				backdrop = {
					transparent = true,
					blend = 95,
				},
				row = -1,
				width = 0,
				height = 0.4,
				border = "top",
				title = " {title} {live} {flags}",
				title_pos = "left",
				{ win = "input", height = 1, border = "bottom" },
				{
					box = "horizontal",
					{ win = "list", border = "none" },
					{ win = "preview", title = "{preview}", width = 0.6, border = "left" },
				},
			},
		}
	end,
}

snacks.setup({
	explorer = {
		enabled = false,
		replace_netrw = true,
		trash = false,
	},
	picker = {
		enabled = true,
		ui_select = true, -- vim.ui.select using snacks
		layouts = {
			custom_ivy = layouts.ivy(),
			custom_select = layouts.select(),
			custom_select_small = layouts.select(0.25),
			custom_select_medium = layouts.select(0.6),
		},
		sources = {
			files = {
				layout = "custom_select",
				hidden = true,
				ignored = false,
				exclude = { "**/vendor/**" },
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
				layout = "custom_select_small",
			},
			pickers = {
				layout = "custom_select_small",
			},
			keymaps = {
				layout = {
					preset = "custom_ivy",
					hidden = { "preview" },
				},
			},
			command_history = {
				layout = {
					preset = "custom_select_medium",
				},
			},
			commands = {
				layout = "custom_select",
			},
		},
	},
	gitbrowse = {
		notify = false,
		open = function(url)
			-- Copy permalink to clipboard(useful when running neovim remotely)
			vim.fn.setreg("+", { url, "c" })
			if vim.ui.open then
				vim.ui.open(url)
			end
		end,
		what = "permalink",
	},
	indent = {
		-- Enable using Snacks.indent.enable() whenever required.
		enabled = false,
		animate = {
			enabled = false,
		},
	},
	input = {
		win = {
			border = "rounded",
			minimal = true,
			backdrop = {
				transparent = true,
				blend = 95,
			},
		},
	},
	statuscolumn = {
		enabled = true,
		folds = {
			open = true, -- show open fold icons
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

vim.keymap.set("n", "<leader>fh", function()
	snacks.picker.help({
		confirm = function(picker, item)
			picker:close()
			if not item or not item.file then
				return
			end

			snacks.win({
				file = item.file,
				style = "float",
				width = 0.85,
				height = 0.85,
				border = "rounded",
				focusable = true,
				wo = {
					conceallevel = 3,
					cursorline = true,
				},
			})

			-- Automatically jump to the specific help tag anchor
			if item.text then
				vim.fn.search([[\*]] .. item.text .. [[\*]])
				vim.cmd("normal! zt")
			end
		end,
	})
end, { desc = "Find neovim help" })

vim.keymap.set("n", "<leader>fk", snacks.picker.keymaps, { desc = "Find keymaps" })

vim.keymap.set("n", "<leader>f;", snacks.picker.command_history, { desc = "Command History" })
vim.keymap.set("n", "<leader>fc", snacks.picker.commands, { desc = "Command Panel" })

vim.keymap.set("n", "<leader>pt", snacks.picker.colorschemes, { desc = "Pick Theme" })
vim.keymap.set("n", "<leader>pr", snacks.picker.resume, { desc = "Resume Picker" })

vim.keymap.set("n", "<leader>fn", function()
	snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Search Neovim files" })

vim.keymap.set({ "n", "v" }, "<leader>gp", function()
	snacks.gitbrowse.open()
end, { desc = "Copy and open git repo permalink" })

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

local utils = require("plugins.utils")
local function pick_filetype()
	local ft_items = {}
	local all_fts = {}

	local function add_ft(ft)
		if not all_fts[ft] then
			local icon, hl = utils.get_ft_icon(ft)
			table.insert(ft_items, {
				text = ft,
				value = ft,
				icon = icon,
				icon_hl = hl,
			})
			all_fts[ft] = true
		end
	end

	-- Filetypes for which treesitter parsers are installed
	local has_ts, ts = pcall(require, "nvim-treesitter")
	if has_ts and ts.get_installed then
		local status, installed = pcall(ts.get_installed)
		if status and type(installed) == "table" then
			for _, lang in ipairs(installed) do
				add_ft(lang)
			end
		end
	end

	-- Gather default Vim filetypes
	for _, ft in ipairs(vim.fn.getcompletion("", "filetype")) do
		if ft ~= "" then
			add_ft(ft)
		end
	end

	-- Filetypes for which parsers are available.
	if has_ts and ts.get_available then
		local status, available = pcall(ts.get_available)
		if status and type(available) == "table" then
			for _, lang in ipairs(available) do
				add_ft(lang)
			end
		end
	end

	snacks.picker.pick({
		title = "File Types",
		items = ft_items,
		layout = {
			layout = {
				box = "vertical",
				position = "float",
				backdrop = 95,
				width = 0.25,
				height = 0.4,
				border = "rounded",
				{ win = "input", height = 1, border = "bottom" },
				{ win = "list", border = "none" },
			},
		},
		format = function(item)
			return {
				{ item.icon .. " ", item.icon_hl },
				{ item.text, "SnacksPickerText" },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				vim.bo.filetype = item.value
			end
		end,
	})
end
vim.keymap.set("n", "<leader>ft", pick_filetype, { desc = "Pick Filetype / TS Parser" })

-- Message viewer
vim.keymap.set("n", "<leader>om", function()
	-- Capture the output of the :messages command
	local messages = vim.fn.execute("messages")
	local lines = vim.split(messages, "\n")

	-- Open a floating window using Snacks
	local win = snacks.win({
		position = "float",
		width = 0.75,
		height = 0.75,
		backdrop = {
			transparent = true,
			blend = 95,
		},
		border = "single",
		wo = { wrap = true },
		bo = { filetype = "messages", buftype = "nofile" },
	})

	-- Set the lines in the window's buffer and lock editing
	vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, lines)
	vim.bo[win.buf].modifiable = false
end, { desc = "Open messages" })
