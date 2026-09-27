if vim.fn.has("nvim-0.12") == 0 then
	return
end

local query = vim.treesitter.query
local compat = require("treesitter-compat")
local registered = {}
local module = "nvim-treesitter.query_predicates"
local originals = { add_predicate = query.add_predicate, add_directive = query.add_directive }
local function register(name, handler, opts)
	assert(opts.force, "Registration options were lost")
	registered[name] = handler
end
query.add_predicate = register
query.add_directive = register

local first, last = {}, {}
local captures = { [1] = { first, last }, [2] = {}, label = "not a capture" }
local metadata = {}
local calls = 0
package.preload[module] = function()
	calls = calls + 1
	for _, name in ipairs({ "add_predicate", "add_directive" }) do
		query[name](name .. "-legacy", function(match, pattern, source, predicate, data)
			assert(match[1] == last, "Legacy handlers must receive the last TSNode")
			assert(match[2] == nil, "Empty captures must be omitted")
			assert(match.label == nil, "Non-capture keys must be omitted")
			assert(pattern == 7 and source == "source" and predicate == "predicate")
			assert(data == metadata, "Metadata must not be copied")
			data.checked = true
			return "result"
		end, { force = true, all = false })
		for _, all in ipairs({ true, "default" }) do
			query[name](name .. tostring(all), function(match)
				assert(match == captures, "Modern handlers must receive the original match")
			end, { force = true, all = all == true and true or nil })
		end
	end
end

-- Simulate lazy.nvim having loaded the predicates before the plugin config.
package.loaded[module] = true
for _ = 1, 2 do
	compat.setup()
	assert(query.add_predicate == register and query.add_directive == register, "API was not restored")
	for _, name in ipairs({ "add_predicate", "add_directive" }) do
		assert(registered[name .. "-legacy"](captures, 7, "source", "predicate", metadata) == "result")
		assert(metadata.checked)
		registered[name .. "true"](captures)
		registered[name .. "default"](captures)
	end
	assert(captures[1][1] == first and captures[1][2] == last, "Original match was mutated")
end
assert(calls == 2, "Predicates must be re-registered even when the module was cached")

package.preload[module] = function()
	error("intentional registration failure")
end
local ok, err = pcall(compat.setup)
assert(not ok and tostring(err):find("intentional registration failure", 1, true))
assert(query.add_predicate == register and query.add_directive == register, "API was not restored on error")

for name, original in pairs(originals) do
	query[name] = original
end
package.loaded[module] = nil
package.preload[module] = nil
