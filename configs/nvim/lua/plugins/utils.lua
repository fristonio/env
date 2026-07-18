local M = {}

function M.get_ft_icon(ft)
	local has_mini, mini_icons = pcall(require, "mini.icons")
	if has_mini then
		local icon, hl = mini_icons.get("filetype", ft)
		if icon then
			return icon, hl
		end
	end

	return "󰈔", "Normal"
end

return M
