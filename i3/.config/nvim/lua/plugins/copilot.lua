return {
	"github/copilot.vim",
	cmd = "Copilot",
	event = "InsertEnter",
	-- Lazy load on insert mode
	init = function()
		vim.g.copilot_filetypes = {
			["markdown"] = false,
			["*"] = true,
		}
	end,
}
