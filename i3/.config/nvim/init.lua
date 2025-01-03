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
	require("plugins.copilot"),
	require("plugins.copilotchat"),
	require("plugins.markdown"),
	require("plugins.treesitter"),
	require("plugins.gruvbox"),
	require("plugins.nvim-tree"),
	require("plugins.telescope"),
	require("plugins.gp"),
	require("plugins.gp"),
	require("plugins.git-blame"),
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
-- require("telescope").setup({
-- 	defaults = {
-- 		file_ignore_patterns = {
-- 			".git",
-- 			".venv",
-- 			"node_modules",
-- 			"__pycache__",
-- 			".mypy_cache",
-- 			".pytest_cache",
-- 			".ruff_cache",
-- 		},
-- 		hidden = true,
-- 		mappings = {
-- 			i = {
-- 				["<C-j>"] = "move_selection_next",
-- 				["<C-k>"] = "move_selection_previous",
-- 				["<C-n>"] = false,
-- 				["<C-p>"] = false,
-- 			},
-- 			n = {
-- 				["<C-j>"] = "move_selection_next",
-- 				["<C-k>"] = "move_selection_previous",
-- 				["<C-n>"] = false,
-- 				["<C-p>"] = false,
-- 			},
-- 		},
-- 	},
-- 	pickers = {
-- 		find_files = {
-- 			hidden = true,
-- 			no_ignore = true,
-- 		},
-- 	},
-- })

vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "Live Grep" })
vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "Help Tags" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "Live Grep" })

local on_attach = function(_, bufnr)
	-- Function to open definition in new tab
	local function goto_definition_in_tab()
		vim.cmd("tab split") -- Open new tab
		vim.lsp.buf.definition() -- Go to definition
	end

	vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, { buffer = bufnr })
	vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action, { buffer = bufnr })
	-- vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
	vim.keymap.set("n", "gi", goto_definition_in_tab, { buffer = bufnr })
	vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, { buffer = bufnr })
	vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr })
end

require("lspconfig").pyright.setup({
	on_attach = on_attach,
})

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

-- vim.opt.clipboard = 'unnamedplus,unnamed'
vim.keymap.set("v", "<space>y", '"*y', { noremap = true, silent = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "ssh-config" },
	callback = function()
		vim.bo.filetype = "sshconfig"
	end,
})

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
