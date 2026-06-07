local map = vim.keymap.set

map("n", "<Esc>", "<cmd>noh<CR>")
map({ "n", "v", "i" }, "<C-c>", "<Esc><Esc>")

map("i", "jk", "<ESC>")

-- Commands & Navigation
map({ "n", "x" }, ";", ":", { desc = "Open command line prompt" })
map({ "n", "x" }, "gh", "0", { desc = "Move cursor to absolute start of line" })
map({ "n", "x" }, "gl", "$", { desc = "Move cursor to absolute end of line" })
map({ "n", "x" }, "gs", "^", { desc = "Move cursor to first non-whitespace character" })
map({ "n", "x" }, "ge", "G", { desc = "Jump straight to last line of file" })

map({ "n", "x" }, "gn", "gt", { desc = "Cycle forward to next tab" })
map({ "n", "x" }, "gp", "gT", { desc = "Cycle backward to previous tab" })

map("i", "<C-b>", "<ESC>^i", { desc = "Move to beginning of line" })
map("i", "<C-e>", "<End>", { desc = "Move to end of line" })
map("i", "<C-h>", "<Left>", { desc = "Move left" })
map("i", "<C-l>", "<Right>", { desc = "Move right" })
map("i", "<C-j>", "<Down>", { desc = "Move down" })
map("i", "<C-k>", "<Up>", { desc = "Move up" })

-- View adjustments
map({ "n", "x" }, "zc", "zz", { desc = "Center current line vertically" })
map({ "n", "x" }, "zt", "zt", { desc = "Scroll current line to top of viewport" })
map({ "n", "x" }, "zb", "zb", { desc = "Scroll current line to bottom of viewport" })
map({ "n", "x" }, "zj", "<C-e>", { desc = "Scroll viewport down one line" })
map({ "n", "x" }, "zk", "<C-y>", { desc = "Scroll viewport up one line" })

-- Editing & Matching
map({ "n", "x" }, "<", "<<", { desc = "Shift current line left one indent level" })
map({ "n", "x" }, ">", ">>", { desc = "Shift current line right one indent level" })
map({ "n", "x" }, "mm", "%", { desc = "Jump between matching brackets" })
map({ "n", "x" }, "U", "<C-r>", { desc = "Redo last undone change" })

map("n", "<leader>d", ":m+1<CR>", { desc = "Move current line down" })
map("n", "<leader>u", ":m-2<CR>", { desc = "Move current line up" })
map("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected block down, and auto-indent" })
map("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected block up, and auto-indent" })

-- Splits & Windows
map({ "n", "x" }, "<leader>w", "<C-w>", { desc = "Window command prefix" })
map({ "n", "x" }, "<C-w>v", ":vsplit<CR>", { desc = "Split current window vertically" })
map({ "n", "x" }, "<C-w>s", ":split<CR>", { desc = "Split current window horizontally" })

map({ "n", "x" }, "<C-h>", "<C-w>h", { desc = "Focus split pane to the left" })
map({ "n", "x" }, "<C-j>", "<C-w>j", { desc = "Focus split pane below" })
map({ "n", "x" }, "<C-k>", "<C-w>k", { desc = "Focus split pane above" })
map({ "n", "x" }, "<C-l>", "<C-w>l", { desc = "Focus split pane to the right" })

-- Tabs & Buffers
map("n", "<leader>to", "<cmd>:tabnew<CR>", { desc = "[O]pen new tab" })
map("n", "<leader>tb", "<cmd> enew <CR>", { desc = "Open new [b]uffer" })
map("n", "<leader>x", ":bd<CR>", { desc = "Unload/delete current buffer" })
map("n", "<leader>q", ":q<CR>", { desc = "Close current split window" })

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

-- Keep last yanked when pasting
map("v", "p", '"_dP')

-- Terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal insert mode back to normal mode" })

-- Resize splits with Shift + arrows
map("n", "<S-Up>", ":resize +2<CR>", { desc = "Resize split up" })
map("n", "<S-Down>", ":resize -2<CR>", { desc = "Resize split down" })
map("n", "<S-Left>", ":vertical resize +2<CR>", { desc = "Resize split left" })
map("n", "<S-Right>", ":vertical resize -2<CR>", { desc = "Resize split right" })
