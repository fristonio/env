-- Minimal migration from tmux configuration

local LEADER = "ctrl+a"

local function bind_key(key, action, args)
	rex.bind(LEADER .. ">" .. key, action, args)
end

bind_key(";", "client.palette.toggle")

rex.bind("cmd+e", "client.sidebar.toggle")
rex.bind("cmd+shift+n", "session.new.on_host")
rex.bind("cmd+/", "session.switch")

-- Move around panes in a window with: Alt+hljk
rex.bind("alt+h", "pane.focus", { direction = "left" })
rex.bind("alt+l", "pane.focus", { direction = "right" })
rex.bind("alt+j", "pane.focus", { direction = "down" })
rex.bind("alt+k", "pane.focus", { direction = "up" })

-- Pane splitting
bind_key("s", "pane.split", { direction = "down" })
bind_key("shift+s", "pane.split", { direction = "up" })
bind_key("v", "pane.split", { direction = "right" })
bind_key("shift+v", "pane.split", { direction = "left" })

-- Pane resizing
bind_key("shift+h", "pane.resize", { direction = "left" })
bind_key("shift+l", "pane.resize", { direction = "right" })
bind_key("shift+j", "pane.resize", { direction = "down" })
bind_key("shift+k", "pane.resize", { direction = "up" })

-- Pane management
bind_key("x", "pane.close")
bind_key("z", "pane.zoom")

-- Open/Close new tabs(windows)
bind_key("c", "client.tab.new")
bind_key("w", "client.tab.close")

bind_key(".", "client.tab.rename")

-- Move around tabs
bind_key("ctrl+a", "client.tab.previous")

bind_key("p", "client.tab.previous")
bind_key("ctrl+p", "client.tab.previous")
bind_key("n", "client.tab.next")
bind_key("ctrl+n", "client.tab.next")

-- Session management
bind_key("ctrl+c", "session.new")
bind_key(",", "session.rename")

bind_key("space", "session.switch")

-- Copy mode configuration
bind_key("ctrl+v", "pane.copy_mode.enter")

-- Custom Actions
bind_key("g", "display_popup", { command = { "lazygit" } })
