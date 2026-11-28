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

return M
