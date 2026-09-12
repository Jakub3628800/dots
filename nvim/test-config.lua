-- Run with -u NONE -l so an init.lua error cannot be hidden by a later +qa.
-- run-test.sh supplies a disposable config/home and a copy of dedicated test data.
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
	local lockfile = config_dir .. "/lazy-lock.json"
	local lock = vim.fn.filereadable(lockfile) == 1 and vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
	local lazy_root = vim.fn.stdpath("data") .. "/lazy/"
	local preparing = vim.env.DOTS_NVIM_TEST_MODE == "prepare"
	local function verify_plugins()
		for name, entry in pairs(lock or {}) do
			local commit = vim.fn.system({ "git", "-C", lazy_root .. name, "rev-parse", "HEAD" }):gsub("%s+$", "")
			assert(
				vim.v.shell_error == 0 and commit == entry.commit,
				"Missing or mismatched test plugin " .. name .. "; run make -C nvim prepare-test"
			)
		end
	end
	if lock and next(lock) and not preparing then
		verify_plugins()
		vim.opt.rtp:prepend(lazy_root .. "lazy.nvim")
		local lazy = require("lazy")
		local setup = lazy.setup
		lazy.setup = function(spec, opts)
			-- Configuration checks must not silently install missing dependencies.
			opts = vim.tbl_deep_extend("force", opts or {}, { install = { missing = false } })
			return setup(spec, opts)
		end
	end

	dofile(config_dir .. "/init.lua")
	if lock and next(lock) then
		-- Exercise deferred plugin configs too, before checking prepared assets.
		require("lazy").load({ plugins = vim.tbl_keys(lock) })
	end
	if lock then
		verify_plugins()
		-- Lazy may refresh descriptive branch names; only plugin identities and
		-- commit pins determine the test inputs.
		local updated_lock = vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
		for name, entry in pairs(updated_lock) do
			assert(lock[name] and lock[name].commit == entry.commit, "Unpinned test plugin: " .. name)
		end
		for name in pairs(lock) do
			assert(updated_lock[name], "Obsolete test plugin in lazy-lock.json: " .. name)
		end
	end
	if preparing then
		-- Initial startup schedules parser builds and registry downloads. Do not
		-- publish a half-prepared seed when the short smoke-test wait expires.
		local function dependencies_ready()
			local configs = package.loaded["nvim-treesitter.configs"]
			if configs then
				for _, language in ipairs(configs.get_ensure_installed_parsers()) do
					local parser = configs.get_parser_install_dir() .. "/" .. language .. ".so"
					if vim.fn.filereadable(parser) == 0 then
						return false
					end
				end
			end
			local org_installer = package.loaded["orgmode.utils.treesitter.install"]
			if org_installer then
				local version = org_installer.get_version_info()
				if not version.installed or version.outdated or version.version_mismatch then
					return false
				end
			end
			local registry = package.loaded["mason-registry"]
			return not registry or #registry.get_all_package_names() > 0
		end
		assert(vim.wait(120000, dependencies_ready, 50), "Timed out preparing parsers or the Mason registry")
	end
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
