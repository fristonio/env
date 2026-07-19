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

-- DAP experience is not very smooth yet. Use EnableDAP when required.
-- require("plugins.dap")

require("plugins.snacks")

require("plugins.git")
require("plugins.completion")

require("plugins.whichkey")
require("plugins.ui")
