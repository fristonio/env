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

-- View git merge conflicts inline.
vim.pack.add({"https://github.com/akinsho/git-conflict.nvim"})
require('git-conflict').setup({})

vim.pack.add({ "https://github.com/esmuellert/codediff.nvim" })

local mini_icons = require("mini.icons")
local mini_prefix = function(ctx, category)
	local icon, icon_hl = mini_icons.get(category, ctx.path)
	local segments = {
		{ text = ctx.indent, hl = ctx.indent_hl },
	}

	if category == "directory" then
		segments[#segments + 1] = {
			text = ctx.expanded and " " or " ",
			hl = "Comment",
		}
	end

	segments[#segments + 1] = {
		text = icon .. " ",
		hl = icon_hl,
	}
	return segments
end

-- Git status letter -> icon + gitsigns highlight group.
local status_icons = {
	A = { icon = "✚", hl = "GitSignsAdd" }, -- Added
	M = { icon = "●", hl = "GitSignsChange" }, -- Modified
	D = { icon = "✖", hl = "GitSignsDelete" }, -- Deleted
	["??"] = { icon = "✱", hl = "GitSignsUntracked" }, -- Untracked
	["!"] = { icon = "‼", hl = "GitSignsChangedelete" }, -- Conflict
}

local function status_icon(status)
	return status_icons[status] or { icon = status, hl = "Comment" }
end

local file_count = function(count)
	return count .. (count == 1 and " file" or " files")
end

local explorer_formatters = {
	file = function(ctx)
		local status = status_icon(ctx.status)
		return {
			left = {
				{ segments = mini_prefix(ctx, "file") },
				{
					segments = { { text = ctx.filename, hl = "Normal" } },
					truncate_priority = 1,
				},
			},
			right = {
				{
					segments = {
						{ text = status.icon, hl = status.hl },
						{ text = " ", hl = "Normal" },
					},
				},
			},
		}
	end,
	folder = function(ctx)
		return {
			left = {
				{ segments = mini_prefix(ctx, "directory") },
				{
					segments = { { text = ctx.name, hl = "Directory" } },
					truncate_priority = 1,
				},
			},
			right = {
				{
					segments = {
						{ text = file_count(ctx.file_count), hl = "Comment" },
						{ text = " ", hl = "Normal" },
					},
				},
			},
		}
	end,
	group = function(ctx)
		return {
			left = {
				{
					segments = { { text = " ◆ " .. ctx.label, hl = "VirtualTextHint" } },
					truncate_priority = 1,
				},
			},
			right = {
				{
					segments = {
						{ text = file_count(ctx.file_count), hl = "Comment" },
						{ text = " ", hl = "Normal" },
					},
				},
			},
		}
	end,
}

require("codediff").setup({
	diff = {
		layout = "side-by-side",
		cycle_hunks_across_files = true,
		jump_to_first_change = false,
		gutter_signs = false,
		compact_context_lines = 5,
		compact = true,
		max_computation_time_ms = 2000,
	},

	explorer = {
		position = "left",
		hidden = false,
		auto_refresh = true,
		indent_markers = false,
		initial_focus = "explorer",
		view_mode = "tree",
		flatten_dirs = true,
		focus_on_select = true,
		line_stats = {
			enabled = true,
			count_untracked = true,
		},
		formatters = explorer_formatters,
	},

	history = {
		position = "bottom",
		view_mode = "list",
	},

	keymaps = {
		view = {
			toggle_stage = "<leader>s",
		},
	},
})

vim.keymap.set("n", "<leader>ct", "<cmd>CodeDiff<CR>", { desc = "Toggle CodeDiff" })
vim.keymap.set("n", "<leader>cd", "<cmd>CodeDiff<CR>", { desc = "Toggle CodeDiff" })

-- Git history
vim.keymap.set("n", "<leader>cf", "<cmd>CodeDiff history %<CR>", { desc = "CodeDiff Git history for current file" })
vim.keymap.set("n", "<leader>ch", "<cmd>CodeDiff history<CR>", { desc = "CodeDiff Git history" })

-- Visual mode: history for selection
vim.keymap.set("v", "<leader>ch", "<Esc><cmd>'<,'>CodeDiff history<CR>", { desc = "Git range history" })

-- Single line history
vim.keymap.set("n", "<leader>cl", "<cmd>.CodeDiff history<CR>", { desc = "Git Line history" })

-- Diff against main/master branch (useful before merging)
vim.keymap.set("n", "<leader>cm", function()
	-- Try main first, fall back to master
	local result = vim.fn.systemlist({ "git", "rev-parse", "--verify", "main" })
	local ok = vim.v.shell_error == 0 and result[1] ~= nil and result[1] ~= ""
	local branch = ok and "main" or "master"
	vim.cmd("CodeDiff " .. branch)
end, { desc = "Git Diff against main/master branch" })

-- Snacks integration with Git
local has_snacks, snacks = pcall(require, "snacks")
if has_snacks then
	local select_layout = {
		preset = "ivy",
		hidden = { "preview" },
	}

	-- Diff against a branch selected via Snacks Picker
	vim.keymap.set("n", "<leader>cb", function()
		snacks.picker.git_branches({
			layout = select_layout,
			confirm = function(picker, item)
				picker:close()
				if item then
					local branch = item.branch or item.text
					vim.cmd("CodeDiff " .. branch)
				end
			end,
		})
	end, { desc = "Diffview branch" })

	-- Diff a single commit against its parent, selected via Snacks Picker
	vim.keymap.set("n", "<leader>cc", function()
		snacks.picker.git_log({
			layout = select_layout,
			confirm = function(picker, item)
				picker:close()
				if item and item.commit then
					vim.cmd("CodeDiff " .. item.commit .. "^ " .. item.commit)
				end
			end,
		})
	end, { desc = "Diffview commit" })

	-- Open commit range <selected-commit>..HEAD in CodeDiff
	vim.keymap.set("n", "<leader>cr", function()
		snacks.picker.git_log({
			layout = select_layout,
			confirm = function(picker, item)
				picker:close()
				if item and item.commit then
					vim.cmd("CodeDiff " .. item.commit .. " HEAD")
				end
			end,
		})
	end, { desc = "Diffview commit range" })
end
