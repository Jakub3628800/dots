return {
	"supermaven-inc/supermaven-nvim",
	event = "InsertEnter",
	config = function()
		require("supermaven-nvim").setup({
			keymaps = {
				accept_suggestion = "<Tab>",
				clear_suggestion = "<C-]>",
				accept_word = "<C-j>",
			},
			ignore_filetypes = { "markdown" }, -- consistent with your copilot config
			color = {
				suggestion_color = "#ffffff",
				cterm = 244,
			},
		})
	end,
}
