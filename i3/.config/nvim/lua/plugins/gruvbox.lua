return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function()
		-- Load the colorscheme here
		vim.o.background = "dark" -- or "light" for light mode
		vim.cmd([[colorscheme gruvbox]])
	end,
}
