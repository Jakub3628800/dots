-- Disabled by default; the active theme is plugins/onehalfdark.lua.
-- To switch back to Gruvbox, set `enabled = true` here and set
-- `enabled = false` in plugins/onehalfdark.lua.
return {
	"ellisonleao/gruvbox.nvim",
	enabled = false,
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function()
		-- Load the colorscheme here
		vim.o.background = "dark" -- or "light" for light mode
		vim.cmd([[colorscheme gruvbox]])
	end,
}
