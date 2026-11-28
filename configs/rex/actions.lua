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

