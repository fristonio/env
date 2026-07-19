vim.pack.add({
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/igorlfs/nvim-dap-view",

	-- Language specific adapters.
	"https://github.com/leoluz/nvim-dap-go",
})

local dap = require("dap")

local signs = {
	DapBreakpoint = { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" },
	DapBreakpointCondition = { text = "", texthl = "DapBreakpointCondition", linehl = "", numhl = "" },
	DapLogPoint = { text = "", texthl = "DapLogPoint", linehl = "", numhl = "" },
	DapStopped = { text = "", texthl = "DapStopped", linehl = "Visual", numhl = "Visual" },
	DapBreakpointRejected = { text = "", texthl = "DapBreakpointRejected", linehl = "", numhl = "" },
}
for sign_name, sign_desc in pairs(signs) do
	vim.fn.sign_define(sign_name, sign_desc)
end

local links = {
	DapBreakpoint = "DiagnosticError",
	DapBreakpointCondition = "DiagnosticError",
	DapLogPoint = "DiagnosticInfo",
	DapStopped = "DiagnosticHint",
	DapBreakpointRejected = "DiagnosticWarn",
}
for hl, link in pairs(links) do
	vim.api.nvim_set_hl(0, hl, { link = link })
end

-- Core DAP Keymaps
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP: Continue" })
vim.keymap.set("n", "<leader>ds", dap.continue, { desc = "DAP: Start" })
vim.keymap.set("n", "<leader>dn", dap.step_over, { desc = "DAP: Step Over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP: Step Into" })
vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "DAP: Step Out" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "DAP: Open REPL" })

local dapui = require("dap-view")
dapui.setup({
	winbar = {
		default_section = "scopes",
	},
	windows = {
		size = 0.3,
		position = "below",
	},
	keymaps = {
		base = {
			next_view = "gn",
			prev_view = "gp",
			jump_to_first = "gs",
			jump_to_last = "gl",
			help = "g?",
		},
	},
	auto_toggle = true,
})
vim.keymap.set("n", "<leader>dv", dapui.toggle, { desc = "DAP: Toggle UI" })

local dap_go = require("dap-go")
dap_go.setup({
	delve = {
		path = "dlv", -- Path to Delve executable
		initialize_timeout_sec = 20,
		port = "${port}", -- Run Delve on a random available port
		args = {},
		build_flags = "",
	},
})

vim.pack.add({
	"https://github.com/nvim-neotest/neotest",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/nvim-lua/plenary.nvim",

	-- Language specific adapters.
	"https://github.com/fredrikaverpil/neotest-golang",
})

local neotest = require("neotest")
neotest.setup({
	adapters = {
		require("neotest-golang")({
			go_test_args = { "-v", "-count=1" },
			dap_mode = "dap-go",
			runner = "gotestsum",
		}),
	},
})

local group = vim.api.nvim_create_augroup("NeotestConfig", {})
vim.api.nvim_create_autocmd("FileType", {
	pattern = "neotest-output",
	group = group,
	callback = function(opts)
		vim.keymap.set("n", "q", function()
			pcall(vim.api.nvim_win_close, 0, true)
		end, {
			buffer = opts.buf,
		})
	end,
})

-- Neotest Keymaps
vim.keymap.set("n", "<leader>tr", neotest.run.run, { desc = "Run nearest test" })
vim.keymap.set("n", "<leader>tt", neotest.run.stop, { desc = "Terminate test" })
vim.keymap.set("n", "<leader>tf", function()
	neotest.run.run(vim.fn.expand("%"))
end, { desc = "Run current file" })

vim.keymap.set("n", "<leader>ts", neotest.summary.toggle, { desc = "Toggle test summary" })

vim.keymap.set("n", "<leader>to", function()
	neotest.output.open({ enter = true, auto_close = true })
end, { desc = "Open output preview" })
vim.keymap.set("n", "<leader>tO", neotest.output_panel.toggle, { desc = "Toggle output panel" })

vim.keymap.set("n", "<leader>td", function()
	neotest.run.run({ suite = false, strategy = "dap" })
end, { desc = "Debug nearest test" })
