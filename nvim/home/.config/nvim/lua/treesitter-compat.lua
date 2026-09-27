local M = {}

function M.setup()
	if vim.fn.has("nvim-0.12") == 0 then
		return
	end

	-- The pinned nvim-treesitter master still registers all=false handlers.
	-- Neovim 0.12 removed that adapter: captures are now lists of TSNodes.
	-- Restore the old last-node semantics only while registering this plugin's
	-- predicates/directives, leaving Neovim's API and other plugins untouched.
	local query = vim.treesitter.query
	local originals = { add_predicate = query.add_predicate, add_directive = query.add_directive }
	for name, register in pairs(originals) do
		query[name] = function(predicate, handler, opts)
			if type(opts) == "table" and opts.all == false then
				local legacy_handler = handler
				handler = function(match, ...)
					local nodes = {}
					for id, captures in pairs(match) do
						if type(id) == "number" then
							nodes[id] = captures[#captures]
						end
					end
					return legacy_handler(nodes, ...)
				end
			end
			return register(predicate, handler, opts)
		end
	end

	-- lazy.nvim may already have sourced the plugin's runtime script.
	package.loaded["nvim-treesitter.query_predicates"] = nil
	local ok, err = pcall(require, "nvim-treesitter.query_predicates")
	for name, register in pairs(originals) do
		query[name] = register
	end
	if not ok then
		error(err)
	end
end

return M
