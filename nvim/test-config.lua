-- Run with -u NONE -l so an init.lua error cannot be hidden by a later +qa.
-- The Makefile selects this checkout's config, independently of Stow links.
local config_dir = vim.fn.stdpath("config")
vim.opt.rtp:prepend(config_dir)
-- -u NONE disables this option, but lazy.nvim requires normal startup semantics.
vim.opt.loadplugins = true

local failures = {}
local notify = vim.notify
vim.notify = function(message, level, opts)
	-- Plugin managers can catch configuration errors and notify instead of
	-- throwing them, so those errors must also fail the configuration check.
	if level and level >= vim.log.levels.ERROR then
		table.insert(failures, tostring(message))
	end
	notify(message, level, opts)
end

local ok, err = xpcall(function()
	dofile(config_dir .. "/init.lua")
end, debug.traceback)
if not ok then
	table.insert(failures, err)
else
	-- Successful plugins may use silent! commands that still set v:errmsg
	-- (for example, removing a nonexistent autocommand group). Synchronous
	-- failures are captured above; only inspect new errors from callbacks.
	vim.v.errmsg = ""
	-- Give startup's scheduled callbacks/notifications a bounded chance to run.
	-- This is a startup smoke test, not a wait for background package installs.
	vim.wait(100, function()
		return false
	end)
end

if vim.v.errmsg ~= "" then
	table.insert(failures, vim.v.errmsg)
end
if #failures > 0 then
	io.stderr:write(table.concat(failures, "\n") .. "\n")
	vim.cmd("cquit 1")
end
