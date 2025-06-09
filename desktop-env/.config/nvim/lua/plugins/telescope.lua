return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("telescope").setup({
			defaults = {
				file_ignore_patterns = {
					".git",
					".venv",
					"node_modules",
					"__pycache__",
					".mypy_cache",
					".pytest_cache",
					".ruff_cache",
				},
				hidden = true,
				mappings = {
					i = {
						["<C-j>"] = "move_selection_next",
						["<C-k>"] = "move_selection_previous",
						["<C-n>"] = false,
						["<C-p>"] = false,
					},
					n = {
						["<C-j>"] = "move_selection_next",
						["<C-k>"] = "move_selection_previous",
						["<C-n>"] = false,
						["<C-p>"] = false,
					},
				},
			},
			pickers = {
				find_files = {
					hidden = true,
				},
				live_grep = {
					additional_args = function()
						return { "--hidden" }
					end,
				},
			},
		})

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Telescope find files" })
		vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
	end,
}
