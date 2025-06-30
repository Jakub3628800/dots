return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("nvim-tree").setup({
			view = {
				side = "left",
			},
			git = {
				ignore = false, -- This will show gitignored files
			},
			tab = {
				sync = {
					open = true, -- Open tree when new tab is opened
					close = true, -- Close tree when tab is closed
					ignore = {}, -- List of buffers to ignore
				},
			},
			on_attach = function(bufnr)
				local api = require("nvim-tree.api")

				api.config.mappings.default_on_attach(bufnr)

				vim.keymap.set("n", "t", api.node.open.tab, { buffer = bufnr })
			end,
		})
		vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })
		vim.keymap.set("n", "<leader>a", function()
			local nvim_tree = require("nvim-tree.api")
			local current_win = vim.api.nvim_get_current_win()
			local current_buf = vim.api.nvim_win_get_buf(current_win)
			local buf_name = vim.api.nvim_buf_get_name(current_buf)

			if buf_name:match("NvimTree_") then
				vim.cmd("wincmd p") -- Go to previous window
			else
				nvim_tree.tree.focus()
			end
		end, { silent = true })
	end,
}
