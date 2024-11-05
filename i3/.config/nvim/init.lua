-- Bootstrap lazy.nvim
-- Key mappings
vim.g.mapleader = " " -- Set leader key to space

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Set up plugins
require("lazy").setup({
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {},
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"echasnovski/mini.nvim", -- if you use the mini.nvim suite
			-- 'echasnovski/mini.icons', -- if you use standalone mini plugins
			-- 'nvim-tree/nvim-web-devicons', -- if you prefer nvim-web-devicons
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "markdown", "markdown_inline" },
				auto_install = true,
				highlight = { enable = true },
			})
		end,
	},
	-- Add Gruvbox theme
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			-- Load the colorscheme here
			vim.o.background = "dark" -- or "light" for light mode
			vim.cmd([[colorscheme gruvbox]])
		end,
	},
	-- Add other plugins here as needed
	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("nvim-tree").setup({
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
	},
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		-- or                              , branch = '0.1.x',
		dependencies = { "nvim-lua/plenary.nvim" },
	},
	{
		"williamboman/mason.nvim",
	},
	{
		"williamboman/mason-lspconfig.nvim",
	},
	{
		"neovim/nvim-lspconfig",
	},
})

require("mason").setup()
require("mason-lspconfig").setup({
	ensure_installed = { "pyright" },
})

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "Live Grep" })
vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "Help Tags" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "Live Grep" })

local on_attach = function(_, bufnr)
	vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, {})
	vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, {})

	vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
	vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, {})
	vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
	vim.keymap.set("n", "gd", require("lspsaga.definition").preview_definition, {
		buffer = bufnr,
		desc = "Preview definition",
	})
end

require("lspconfig").pyright.setup({})

-- vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
-- vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
-- vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

-- Basic Neovim settings
vim.opt.number = true -- Show line numbers
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.shiftwidth = 2 -- Size of an indent
vim.opt.softtabstop = 2 -- Number of spaces tabs count for in insert mode
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.termguicolors = true -- Enable 24-bit RGB color in the TUI
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>")
-- Define the custom command
vim.api.nvim_create_user_command("Tabn", "tabnew | Ex", {})

-- Map Ctrl+Enter to the custom command
vim.api.nvim_set_keymap("n", "<C-CR>", ":Tabn<CR>", { noremap = true, silent = true })

-- Define a new command Exh
vim.api.nvim_create_user_command("Hh", function()
	local current_file = vim.fn.expand("%:p")
	local current_dir = vim.fn.fnamemodify(current_file, ":h")
	vim.cmd("edit " .. vim.fn.fnameescape(current_dir))
end, {})

vim.api.nvim_create_user_command("Cc", function()
	-- Get the current line
	local line = vim.api.nvim_get_current_line()

	-- Check if the line contains a checkbox (checked or unchecked)
	local new_line
	if line:match("%[[ x]%]") then
		-- Toggle the checkbox state
		new_line = line:gsub("%[[ x]%]", function(match)
			return match == "[ ]" and "[x]" or "[ ]"
		end, 1)

		-- Get the current cursor position
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))

		-- Replace the current line with the new line
		vim.api.nvim_set_current_line(new_line)

		-- Set the cursor position to the same column
		vim.api.nvim_win_set_cursor(0, { row, col })
	end
end, {})
