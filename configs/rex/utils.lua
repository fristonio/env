local M = {
	TERMINAL = "com.superlogical.terminal",
	SHELL = "com.superlogical.terminal.shell",
}

-- Available rex icons: https://www.superlogical.com/rex/docs/customize/custom-ui#icons

-- Convert rex file URL to absolute path
-- file://host/home/me/dir => /home/me/dir
function M.url_to_path(url)
	if type(url) ~= "string" or url == "" then
		return nil
	end
	return url:match("^file://[^/]*(/.*)$") or url
end

-- Helper to convert /home/me/dir => ~/dir
function M.user_path(path)
	local home = os.getenv("HOME")
	if path and home and path:sub(1, #home) == home then
		path = "~" .. path:sub(#home + 1)
	end
	return path
end

function M.pretty_file_path(url)
	return M.user_path(M.url_to_path(url))
end

-- Returns the working directory of a terminal block or nil.
-- Prefers the directory the shell last reported, the foreground processe's cwd.
function M.block_cwd(block_id)
	local p = rex.block.call(M.TERMINAL, "pwd", { block_id = block_id })
	local cwd = p and M.url_to_path(p.pwd)

	if cwd then
		return cwd
	end
	local pinfo = rex.block.call(M.TERMINAL, "process", { block_id = block_id })
	local proc = pinfo and (pinfo.foreground or pinfo.child)
	return proc and proc.cwd or nil
end

-- Pretty print info for programs: binary => {Program, rex icon name}
local PROGRAMS = {
	claude = { "Claude Code", "agent" },
	codex = { "Codex", "agent" },
	pi = { "Pi", "agent" },
	nvim = { "Neovim", "code" },
	vim = { "Vim", "code" },
	hx = { "Helix", "code" },
	lazygit = { "Lazygit", "branch" },
	btop = { "btop", "gear" },
	ssh = { "SSH", "server" },
	bash = { "Bash", "terminal" },
	nu = { "Nushell", "terminal" },
}

local function pretty_program_name(process)
	if not process then
		return nil
	end

	-- Simplify program info: /bin/bash, -bash => "bash"
	local name = process:match("[^/]+$"):gsub("^%-", "")
	local info = PROGRAMS[name]
	if info then
		return info[1], info[2]
	end
	return name, "terminal"
end

local function pretty_pane_name(block_id)
	local s = rex.block.call(M.TERMINAL, "program_status", { block_id = block_id })
	local r = s and type(s.records) == "table" and s.records[1]

	if r and (r.effective_app or r.app) then
		return pretty_program_name(r.effective_app or r.app)
	end

	local proc = rex.block.call(M.TERMINAL, "process", { block_id = block_id })
	local fg = proc and proc.foreground
	if fg and fg.name then
		return pretty_program_name(fg.name)
	end
	return "Shell", "terminal"
end

-- List panes in the current rex session
function M.list_panes(ctx)
	local view, err = rex.session.view({})
	if view == nil then
		rex.log("error", "session.view failed: " .. tostring(err))
		return {}
	end

	local panes = {}
	for index, w in ipairs(view.windows or {}) do
		local window = {
			id = w.window_id,
			label = w.label,
			index = index,
			is_active = w.window_id == view.active_window_id,
		}

		for _, layer in ipairs(w.layers or {}) do
			for _, b in ipairs(layer.blocks or {}) do
				local pane = {
					block_id = b.block_id,
					label = b.label,
					window = window,
					is_terminal = b.creator_name == M.TERMINAL,
					is_focused = b.block_id == w.focused_block_id,
					is_current = b.block_id == ctx.block_id,
				}

				if pane.is_terminal then
					local t = rex.block.call(M.TERMINAL, "title", { block_id = b.block_id })

					pane.title = title and t.title ~= "" and t.title or nil
					pane.cwd = M.user_path(M.block_cwd(b.block_id))
					pane.name, pane.icon = pretty_pane_name(b.block_id)
				else
					pane.name = b.label
				end

				table.insert(panes, pane)
			end
		end
	end

	return panes
end

return M
