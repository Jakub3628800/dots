return {
	"sonph/onehalf",
	lazy = false,
	priority = 1000,
	config = function(plugin)
		-- The colorscheme lives under the vim/ subdirectory of this repo.
		vim.opt.rtp:append(plugin.dir .. "/vim")
		vim.o.background = "dark"
		vim.cmd.colorscheme("onehalfdark")
	end,
}
