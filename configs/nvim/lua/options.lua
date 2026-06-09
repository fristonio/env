-- Enable faster startup by caching compiled Lua modules
vim.loader.enable()

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Enable true color support
vim.opt.termguicolors = true
vim.opt.laststatus = 3

-- [[ Setting options ]]
--  See `:help vim.o`
--  For more options, you can see `:help option-list`

-- Enable line numbering
vim.o.number = true
vim.o.relativenumber = true

-- Enable mouse mode.
vim.o.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- Enable wrapped lines to repeat the indent.
vim.o.breakindent = true

-- Enable undo/redo changes even after closing and reopening a file
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250

-- Wait time for mapped sequence
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
vim.opt.whichwrap:append("<>[]hl")

-- Sets how neovim will display certain whitespace characters in the editor.
-- See `:help 'list'` and `:help 'listchars'`
--
-- A more complete VIM List Chars:
-- vim.opt.listchars = { tab = '»', space = '·', nbsp = '␣', extends = '⟩', precedes = '⟨' }
vim.opt.listchars = { tab = "» ", space = "·" }
vim.opt.list = false

vim.opt.fillchars:append({ eob = " " })

-- Max number of entries to show in completion popups.
vim.opt.pumheight = 16

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Include last character in selection
-- vim.opt.selection = "inclusive"

vim.o.winborder = "rounded"

-- Set default shift and tab width to 4 spaces.
vim.o.shiftwidth = 4
vim.o.tabstop = 4

-- Folds configuration
vim.o.foldcolumn = "1" -- Shows fold column on the left side.
vim.o.foldlevel = 99 -- Disable code folding by default
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.opt.fillchars:append({ fold = " ", foldopen = "", foldclose = "", foldsep = " ", foldinner = " " })
vim.opt.foldmethod = "indent" -- Defaults to indent, overridden in treesitter config
