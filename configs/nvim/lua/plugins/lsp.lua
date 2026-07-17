-- Setup LSPs and other language diagnostic settings.

-- Diagnostic Config & Keymaps
--  See `:help vim.diagnostic.Opts`
vim.diagnostic.config({
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = { min = vim.diagnostic.severity.WARN } },

	-- Text shows up at the end of the line
	virtual_text = {
		current_line = true,
	},
	virtual_lines = false, -- Text shows up underneath the line, with virtual lines

	-- Auto open the float to easily read the errors when jumping with `[d` and `]d`
	jump = {
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({
				bufnr = bufnr,
				scope = "cursor",
				focus = false,
			})
		end,
	},

	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.HINT] = "󰌵",
			[vim.diagnostic.severity.INFO] = "",
		},
	},
})

vim.api.nvim_create_user_command("ToggleDiagSigns", function()
	local current_value = vim.diagnostic.config().signs
	vim.diagnostic.config({ signs = not current_value })
end, { desc = "Toggle diagnostic gutter signs" })

vim.api.nvim_create_user_command("ToggleDiag", function()
	if vim.diagnostic.is_enabled() then
		vim.diagnostic.disable()
	else
		vim.diagnostic.enable()
	end
end, { desc = "Toggle all diagnostics" })

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("nvim-lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
		end

		-- Shorthand keymappings
		map("K", vim.lsp.buf.hover, "Show type definition")
		map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
		map("gD", vim.lsp.buf.declaration, "[G]oto [D]ecleration")
		map("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
		map("gR", vim.lsp.buf.references, "[G]oto [R]eferences")

		-- LSP actions keymappings.
		map("<leader>ld", vim.lsp.buf.definition, "Goto [L]SP [D]efinition")
		map("<leader>lD", vim.lsp.buf.declaration, "Goto [L]SP [D]ecleration")
		map("<leader>li", vim.lsp.buf.hover, "Show [L]SP [I]nfo")
		map("<leader>lI", vim.lsp.buf.implementation, "Goto [L]SP [I]mplementation")
		map("<leader>lR", vim.lsp.buf.references, "Goto [L]SP [R]eferences")
		map("<leader>lrn", vim.lsp.buf.rename, "[L]SP [R]e[n]ame")
		map("<leader>la", vim.lsp.buf.code_action, "Goto [L]SP Code [A]ction", { "n", "x" })

		-- The following two autocommands are used to highlight references of the
		-- word under your cursor when your cursor rests there for a little while.
		--    See `:help CursorHold` for information about when this is executed
		local client = vim.lsp.get_client_by_id(event.data.client_id)

		if vim.fn.executable("tree-sitter") == 1 and client then
			-- Disable LSP highlighting, rely on treesitter instead when available.
			client.server_capabilities.semanticTokensProvider = nil
		end

		if client and client:supports_method("textDocument/documentHighlight", event.buf) then
			local highlight_augroup = vim.api.nvim_create_augroup("nvim-lsp-highlight", { clear = false })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})

			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})

			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("nvim-lsp-detach", { clear = true }),
				callback = function(event2)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = "nvim-lsp-highlight", buffer = event2.buf })
				end,
			})
		end
	end,
})

-- Enable the following language servers
--  See `:help lsp-config` for information about keys and how to configure
local servers = {
	clangd = {},

	gopls = {
		settings = {
			gopls = {
				analyses = {
					unusedparams = true,
				},
				staticcheck = true,
				gofumpt = true,
			},
		},
	},

	nushell = {},
	nil_ls = {}, -- Nix language server.

	-- Special Lua Config, as recommended by neovim help docs
	lua_ls = {
		on_init = function(client)
			client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

			if client.workspace_folders then
				local path = client.workspace_folders[1].name
				if
					path ~= vim.fn.stdpath("config")
					and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
				then
					return
				end
			end

			client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
				runtime = {
					version = "LuaJIT",
					path = { "lua/?.lua", "lua/?/init.lua" },
				},
				workspace = {
					checkThirdParty = false,
					-- NOTE: this is a lot slower and will cause issues when working on your own configuration.
					--  See https://github.com/neovim/nvim-lspconfig/issues/3189
					library = vim.tbl_extend("force", vim.api.nvim_get_runtime_file("", true), {
						"${3rd}/luv/library",
						"${3rd}/busted/library",
					}),
				},
			})
		end,
		settings = {
			Lua = {
				format = { enable = false }, -- Disable formatting (formatting is done by stylua)
			},
		},
	},
}

-- Install nvim-lspconfig plugin. A data only repository with LSP configurations.
vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })
for name, server in pairs(servers) do
	vim.lsp.config(name, server)
	vim.lsp.enable(name)
end

-- Conform.nvim setup
vim.pack.add({ "https://github.com/stevearc/conform.nvim" })
require("conform").setup({
	notify_on_error = false,
	format_on_save = function(bufnr)
		local enabled_filetypes = {
			lua = true,
		}
		if enabled_filetypes[vim.bo[bufnr].filetype] then
			return { timeout_ms = 500 }
		else
			return nil
		end
	end,
	default_format_opts = {
		lsp_format = "fallback", -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
	},
	-- External formatters.
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "goimports", "gofumpt" },
		nu = { "nufmt" },
		nix = { "nixfmt" },
	},
})
vim.keymap.set({ "n", "v" }, "<leader>fmt", function()
	require("conform").format({ async = true })
end, { desc = "[F]ormat buffer" })

-- Outline panel configuration
vim.pack.add({ "https://github.com/hedyhli/outline.nvim" })
require("outline").setup({
	outline_window = {
		auto_jump = true,
		hide_cursor = false,
		jump_highlight_duration = 1000,
	},
	providers = {
		priority = { "lsp", "markdown", "norg", "man" },
		lsp = {
			-- Lsp client names to ignore
			blacklist_clients = {},
		},
	},
})
vim.keymap.set("n", "<leader>to", "<cmd>Outline<CR>", { desc = "Toggle Outline" })
