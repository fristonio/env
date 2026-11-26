local utils = require("utils")

rex.action({
	name = "display_popup",
	title = "Open command in Popup…",
	category = "Panes",
	keywords = "popup float floating display-popup command",
	args = { command = "array", width = "number?", height = "number?" },
	run = function(ctx, args)
		opts = args or {}

		local command = opts.command or nil
		if not command then
			rex.log("error", "Command is required for popup display")
			return
		end

		local w, h = opts.width or 0.8, opts.height or 0.8
		local cwd = opts.cwd or (ctx.block_id and utils.block_cwd(ctx.block_id))
		rex.log("info", "DISPLAY_POPUP:  " .. cwd)

		local res, err = rex.session.new_layer({
			bounds = { (1 - w) / 2, (1 - h) / 2, w, h },
			focus = true,
			layout = rex.layout.block({
				flavor = utils.SHELL,
				label = opts.label or command[1],
				options = { command = command, cwd = cwd },
			}),
		})
		if res == nil then
			rex.log("error", "Popup failed: " .. tostring(err))
		end
		return res
	end,
})

rex.action({
	name = "goto_pane",
	title = "Go to Pane…",
	category = "Panes",
	keywords = "pane find pick jump switch search",
	run = function(ctx)
		local items = {}
		for _, p in ipairs(utils.list_panes(ctx)) do
			local tab = ("󰘳 %d"):format(p.window.index)
			local name = p.name or p.label or "Pane"
			if p.is_current then
				name = name .. "  (here)"
			end

			table.insert(items, {
				id = p.block_id,
				title = name,
				subtitle = p.cwd,
				detail = p.window.label,
				icon = p.icon,
			})
		end

		local block_id = rex.ui.pick({
			title = "Go to pane",
			placeholder = "Filter by name, tab, or directory…",
			confirm = "Go to pane",
			items = items,
		})

		if block_id then
			local _, err = rex.session.focus_block({ block_id = block_id })
			if err then
				rex.log("error", "Failed to focus on block: " .. tostring(err))
			end
		end
	end,
})
rex.bind("cmd+shift+/", "goto_pane")
