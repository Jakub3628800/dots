return {
	"github/copilot.vim",
	lazy = false,
	config = function()
		vim.g.copilot_filetypes = {
			["markdown"] = false,
			["*"] = true,
		}
		-- Default Tab to accept suggestions
		vim.keymap.set("i", "<Tab>", 'copilot#Accept("\\<CR>")', {
			expr = true,
			replace_keycodes = false,
		})
		vim.g.copilot_no_tab_map = true
	end,
}
