-- See `:help gitsigns` to understand what each configuration key does.
-- Adds git related signs to the gutter, as well as utilities for managing changes

vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
require("gitsigns").setup({
	-- Highlight line numbers with git signs.
	-- numhl = true,
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Navigation
		-- ]c and [c are default diff view navigation keymappings.
		map("n", "<leader>hn", function()
			gitsigns.nav_hunk("next")
		end, { desc = "Next Git Hunk" })
		map("n", "]c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "]c", bang = true })
			else
				gitsigns.nav_hunk("next")
			end
		end)

		map("n", "<leader>hp", function()
			gitsigns.nav_hunk("prev")
		end, { desc = "Previous Git Hunk" })
		map("n", "[c", function()
			if vim.wo.diff then
				vim.cmd.normal({ "[c", bang = true })
			else
				gitsigns.nav_hunk("prev")
			end
		end)

		-- Actions
		map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Stage Git Hunk" })
		map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Reset Git Hunk" })

		map("v", "<leader>ghs", function()
			gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { desc = "Stage Git Hunk" })

		map("v", "<leader>ghr", function()
			gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { desc = "Reset Git Hunk" })

		map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "Stage all hunks in the buffer" })
		map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "Reset all hunks in the buffer" })

		map("n", "<leader>hI", gitsigns.preview_hunk, { desc = "Inspect Hunk" })
		map("n", "<leader>hi", gitsigns.preview_hunk_inline, { desc = "Inspect Hunk(inline)" })

		map("n", "<leader>hb", function()
			gitsigns.blame_line({ full = true })
		end, { desc = "Blame the current line" })
		map("n", "<leader>hB", gitsigns.blame, { desc = "Blame the current buffer" })

		-- Toggles
		map("n", "<leader>htb", gitsigns.toggle_current_line_blame, { desc = "Toggle git blame for active lines" })
		map("n", "<leader>htw", gitsigns.toggle_word_diff, { desc = "Toggle word diff for the buffer" })

		map("n", "<leader>hQ", function()
			gitsigns.setqflist("all")
		end, { desc = "Explore hunks as list" })
		map("n", "<leader>hq", gitsigns.setqflist, { desc = "Explore hunks as list for buffer" })

		-- Text object
		map({ "o", "x" }, "ih", gitsigns.select_hunk, { desc = "Select the hunk" })
	end,
})

-- Experimental code diffview
vim.pack.add({ "https://github.com/dlyongemallo/diffview-plus.nvim" })
require("diffview").setup({
	enhanced_diff_hl = true,
	use_icons = true,

	-- For PR reviews.
	-- imply-local makes the right side buffer editable during reviews
	default_args = {
		DiffviewOpen = { "--imply-local" },
	},
	file_panel = {
		show_branch_name = true,
		always_show_sections = true,
	},

	hooks = {
		diff_buf_read = function(bufnr)
			vim.opt_local.wrap = false
		end,
	},

	-- Persist review progress.
	-- persist_selections = { enabled = true },
})

-- Toggle diffview open/close
vim.keymap.set("n", "<leader>dv", "<cmd>DiffviewToggle<cr>", { desc = "Git Diffview toggle" })

-- Diff working directory
vim.keymap.set("n", "<leader>do", "<cmd>DiffviewOpen<cr>", { desc = "Git Diffview open" })
vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "Git Diffview close" })

-- File history
vim.keymap.set("n", "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Git file history (current file)" })
vim.keymap.set("n", "<leader>dH", "<cmd>DiffviewFileHistory<cr>", { desc = "Git file history (repo)" })

-- Visual mode: history for selection
vim.keymap.set("v", "<leader>dh", "<Esc><cmd>'<,'>DiffviewFileHistory --follow<CR>", { desc = "Git range history" })

-- Single line history
vim.keymap.set("n", "<leader>dl", "<cmd>.DiffviewFileHistory --follow<CR>", { desc = "Git Line history" })

-- Diff against main/master branch (useful before merging)
vim.keymap.set("n", "<leader>dm", function()
	-- Try main first, fall back to master
	local result = vim.fn.systemlist({ "git", "rev-parse", "--verify", "main" })
	local ok = vim.v.shell_error == 0 and result[1] ~= nil and result[1] ~= ""
	local branch = ok and "main" or "master"
	vim.cmd("DiffviewOpen " .. branch)
end, { desc = "Git Diff against main/master" })
