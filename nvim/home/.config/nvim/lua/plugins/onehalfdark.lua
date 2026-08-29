return {
	"sonph/onehalf",
	enabled = true, -- disable here and enable plugins/gruvbox.lua to switch back
	lazy = false,
	priority = 1000,
	config = function(plugin)
		-- The colorscheme lives under the vim/ subdirectory of this repo.
		vim.opt.rtp:append(plugin.dir .. "/vim")
		vim.o.background = "dark"
		vim.cmd.colorscheme("onehalfdark")
	end,
}
