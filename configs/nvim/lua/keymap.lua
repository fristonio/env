local map = vim.keymap.set

-- Execute line under the cursor.
map("n", "<leader><leader>x", "<cmd>.lua<CR>")

-- Remap Esc to clear highlight and C-c to do double Esc
-- Useful to close completion menu and return to normal mode directly.
map("n", "<Esc>", "<cmd>noh<CR>")
map({ "n", "v", "i" }, "<C-c>", "<Esc><Esc>")

-- Commands & Navigation
map({ "n", "v" }, "gh", "0", { desc = "Move cursor to absolute start of line" })
map({ "n", "v" }, "gl", "$", { desc = "Move cursor to absolute end of line" })
map({ "n", "v" }, "gs", "^", { desc = "Move cursor to first non-whitespace character" })
map({ "n", "v" }, "ge", "G", { desc = "Jump straight to last line of file" })

map("i", "<C-b>", "<ESC>^i", { desc = "Move to beginning of line" })
map("i", "<C-e>", "<End>", { desc = "Move to end of line" })
map("i", "<C-h>", "<Left>", { desc = "Move left" })
map("i", "<C-l>", "<Right>", { desc = "Move right" })
map("i", "<C-j>", "<Down>", { desc = "Move down" })
map("i", "<C-k>", "<Up>", { desc = "Move up" })

-- View adjustments
map({ "n", "v" }, "zt", "zt", { desc = "Scroll current line to top of viewport" })
map({ "n", "v" }, "zb", "zb", { desc = "Scroll current line to bottom of viewport" })
map({ "n", "v" }, "zj", "<C-e>", { desc = "Scroll viewport down one line" })
map({ "n", "v" }, "zk", "<C-y>", { desc = "Scroll viewport up one line" })

map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Editing & Matching
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected block down, and auto-indent" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected block up, and auto-indent" })

map("n", "<", "<<", { desc = "Shift current line left one indent level" })
map("n", ">", ">>", { desc = "Shift current line right one indent level" })
map("x", ">", ">gv", { desc = "Shift selection left one indent level" })
map("x", "<", "<gv", { desc = "Shift selection right one indent level" })

map({ "n", "x" }, "mm", "%", { desc = "Jump between matching brackets" })
map({ "n", "x" }, "U", "<C-r>", { desc = "Redo last undone change" })

-- Splits, Windows and buffers.
map({ "n", "x" }, "<leader>w", "<C-w>", { desc = "Window command prefix" })
map({ "n", "x" }, "<C-w>v", ":vsplit<CR>", { desc = "Split current window vertically" })
map({ "n", "x" }, "<C-w>s", ":split<CR>", { desc = "Split current window horizontally" })

map({ "n", "x" }, "<C-h>", "<C-w>h", { desc = "Focus split pane to the left" })
map({ "n", "x" }, "<C-j>", "<C-w>j", { desc = "Focus split pane below" })
map({ "n", "x" }, "<C-k>", "<C-w>k", { desc = "Focus split pane above" })
map({ "n", "x" }, "<C-l>", "<C-w>l", { desc = "Focus split pane to the right" })

map({ "n", "x" }, "<leader>x", "<cmd>bp|bd #<CR>", { desc = "Unload/delete current buffer" }) -- Does not close the split
map({ "n", "x" }, "<leader>q", ":q<CR>", { desc = "Close current split window" })

-- Search
map({ "n", "x" }, "n", "nzzzv", { desc = "Find next search result and center screen" })
map({ "n", "x" }, "N", "Nzzzv", { desc = "Find previous search result and center screen" })
map({ "n", "x" }, ",", ":noh<CR>", { desc = "Clear residual search text highlights" })

-- Selections
map("n", "x", "V", { desc = "Enter Visual Line mode to select current row" })
map("n", "X", "V", { desc = "Enter Visual Line mode to select current row" })
map("x", "x", "j", { desc = "Extend visual selection down one line" })
map("x", "X", "k", { desc = "Extend visual selection up one line" })

-- Toggle line wrapping
map("n", "<leader>lw", "<cmd>set wrap!<CR>", { desc = "Toggle line wraps" })

-- Terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal insert mode back to normal mode" })

-- Resize splits with Shift + arrows
map("n", "<S-Up>", ":resize +2<CR>", { desc = "Resize split up" })
map("n", "<S-Down>", ":resize -2<CR>", { desc = "Resize split down" })
map("n", "<S-Left>", ":vertical resize +2<CR>", { desc = "Resize split left" })
map("n", "<S-Right>", ":vertical resize -2<CR>", { desc = "Resize split right" })

-- Extras...
map("v", "p", '"_dP') -- Keep last yanked text when pasting.
map("n", "gc", "gcc")

-- Copy file name and path
map("n", "<leader>cp", '<cmd>let @+ = expand("%")<CR>', { desc = "Copy File Name(relative path)" })
map("n", "<leader>cP", '<cmd>let @+ = expand("%:p")<CR>', { desc = "Copy File Path(absolute path)" })

-- Search for current visual selection globally using '//'
map("v", "//", [[y/\V<C-R>=escape(@", '/\')<CR><CR>]], { desc = "Search for visual selection" })
