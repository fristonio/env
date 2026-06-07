-- Setup completion engine(blink.cmp)

local disabled_completions = {
	"markdown",
}

vim.pack.add({ "https://github.com/saghen/blink.lib", "https://github.com/saghen/blink.cmp" })
local cmp = require("blink.cmp")
cmp.build():pwait()
cmp.setup({
	enabled = function()
		return not vim.tbl_contains(disabled_completions)
	end,
	cmdline = { enabled = true },
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
	completion = {
		menu = {
			auto_show = false,
			auto_show_delay_ms = 500,
		},
		documentation = {
			auto_show = false,
			auto_show_delay_ms = 1000,
		},
		-- Display a preview of the selected item on the current line.
		ghost_text = { enabled = false },
	},
	keymap = {
		preset = "default",

		["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
		["<CR>"] = { "select_and_accept", "fallback" },
	},
})

vim.api.nvim_create_user_command("ToggleCmpAutoShow", function()
	local config = require("blink.cmp.config")

	config.completion.menu.auto_show = not config.completion.menu.auto_show
	config.completion.documentation.auto_show = not config.completion.documentation.auto_show
	config.completion.ghost_text.enabled = not config.completion.ghost_text.enabled
end, { nargs = 0, desc = "Toggle auto completion suggestion auto show. Use <C-Space> to trigger" })
