require("options")
require("keymap")
require("autocmds")
require("commands")

require("vim._core.ui2").enable()
require("plugins.mini")

if vim.fn.executable("tree-sitter") == 1 then
	require("plugins.treesitter")
end

require("plugins.lsp")

require("plugins.snacks")

require("plugins.git")
require("plugins.completion")

require("plugins.whichkey")
require("plugins.ui")

vim.api.nvim_create_user_command("EnableNext", function()
	require("plugins.next")
end, { desc = "Enable test plugins in lua/plugins/next.lua" })
