require("options")
require("keymap")
require("autocmds")
require("commands")

require("vim._core.ui2").enable()

if vim.fn.executable("tree-sitter") == 1 then
	require("plugins.treesitter")
end

require("plugins.lsp")
require("plugins.telescope")

require("plugins.mini")
require("plugins.git")
require("plugins.completion")
require("plugins.whichkey")

require("plugins.ui")
