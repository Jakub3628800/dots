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
	require("plugins.markdown"),
	require("plugins.treesitter"),
	require("plugins.gruvbox"),
	require("plugins.nvim-tree"),
	require("plugins.telescope"),
	require("plugins.gp"),
	require("plugins.git-blame"),
	require("plugins.orgmode"),
	require("plugins.navic"),
	{
		"hrsh7th/nvim-cmp",
	},
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "pyright" },
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "williamboman/mason-lspconfig.nvim" },
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns
					vim.keymap.set("n", "<leader>hj", function()
						gs.next_hunk()
					end, { buffer = bufnr, desc = "Next git hunk" })
					vim.keymap.set("n", "<leader>hk", function()
						gs.prev_hunk()
					end, { buffer = bufnr, desc = "Previous git hunk" })
				end,
			})
		end,
	},
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
vim.keymap.set("n", "<C-h>", require("telescope.builtin").git_status, { desc = "Git status" })

local on_attach = function(client, bufnr)
	-- Attach navic if available
	if client.server_capabilities.documentSymbolProvider then
		require("nvim-navic").attach(client, bufnr)
	end

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
local capabilities = require("cmp_nvim_lsp").default_capabilities()
require("lspconfig").pyright.setup({
	on_attach = on_attach,
	capabilities = capabilities,
})
require("lspconfig").gopls.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
		},
	},
})
require("cmp").setup({
	mapping = {
		["<C-Space>"] = require("cmp").mapping.complete(),
		["<CR>"] = require("cmp").mapping.confirm({ select = true }),
		["<Tab>"] = require("cmp").mapping.select_next_item(),
		["<S-Tab>"] = require("cmp").mapping.select_prev_item(),
	},
	sources = {
		{ name = "nvim_lsp" },
		{ name = "buffer" },
	},
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

-- Yank code block content
vim.keymap.set("n", "<space>yc", function()
	-- Find the current position
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor_pos[1]
	local current_buffer = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(current_buffer, 0, -1, false)

	-- Find the start of the code block (```)
	local start_line = nil
	for i = current_line, 1, -1 do
		if lines[i] and lines[i]:match("^```") then
			start_line = i
			break
		end
	end

	-- Find the end of the code block (```)
	local end_line = nil
	for i = current_line, #lines do
		if lines[i] and lines[i]:match("^```") and i ~= start_line then
			end_line = i
			break
		end
	end

	-- If we found a complete code block
	if start_line and end_line then
		-- Extract the code content (skip the first line with ```)
		local code_content = table.concat(
			vim.api.nvim_buf_get_lines(
				current_buffer,
				start_line, -- Start line (inclusive, 0-indexed)
				end_line, -- End line (exclusive, 0-indexed)
				false
			),
			"\n"
		)

		-- Remove the first line (language specifier)
		code_content = code_content:gsub("^```.-\n", "")

		-- Remove the last line (```)
		code_content = code_content:gsub("\n```$", "")

		-- Copy to system clipboard
		vim.fn.setreg("+", code_content)

		-- Provide feedback
		vim.api.nvim_echo({ { "Code block copied to clipboard", "Normal" } }, true, {})
	else
		vim.api.nvim_echo({ { "No code block found", "ErrorMsg" } }, true, {})
	end
end, { noremap = true, silent = true, desc = "Yank code block content" })

-- Tmux integration configuration
local TMUX_SESSION = "test"
local TMUX_CAPTURE_LINES = 1000
local MAX_OUTPUT_LINES = 50

-- Helper: Find code block boundaries around cursor
local function find_code_block_bounds()
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- Find start of code block
	local start_line = nil
	for i = cursor_line, 1, -1 do
		if lines[i] and lines[i]:match("^```") then
			start_line = i
			break
		end
	end

	if not start_line then
		return nil, nil
	end

	-- Find end of code block
	for i = cursor_line, #lines do
		if lines[i] and lines[i]:match("^```") and i ~= start_line then
			return start_line, i
		end
	end

	return nil, nil
end

-- Helper: Extract code content from block
local function extract_code_content(start_line, end_line)
	local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line - 1, false)
	return table.concat(lines, "\n")
end

-- Send code block to tmux session
vim.keymap.set("n", "<space>yt", function()
	local start_line, end_line = find_code_block_bounds()

	if not start_line or not end_line then
		vim.api.nvim_echo({ { "No code block found at cursor position", "ErrorMsg" } }, true, {})
		return
	end

	local code_content = extract_code_content(start_line, end_line)

	-- Check if tmux session exists
	local check_cmd = string.format("tmux has-session -t %s 2>/dev/null", TMUX_SESSION)
	vim.fn.system(check_cmd)

	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{
				string.format(
					"Tmux session '%s' not found. Create it with: tmux new -s %s",
					TMUX_SESSION,
					TMUX_SESSION
				),
				"ErrorMsg",
			},
		}, true, {})
		return
	end

	-- Send code to tmux
	local escaped_content = vim.fn.shellescape(code_content)
	local send_cmd = string.format("tmux send-keys -t %s %s Enter", TMUX_SESSION, escaped_content)
	local result = vim.fn.system(send_cmd)

	if vim.v.shell_error == 0 then
		vim.api.nvim_echo(
			{ {
				string.format("Code sent to tmux session '%s'", TMUX_SESSION),
				"Normal",
			} },
			true,
			{}
		)
	else
		vim.api.nvim_echo({ {
			"Failed to send to tmux: " .. result,
			"ErrorMsg",
		} }, true, {})
	end
end, { noremap = true, silent = true, desc = "Send code block to tmux test session" })

-- Helper: Detect shell prompt lines
local function is_prompt_line(line, hostname, username)
	-- Common prompt patterns
	return line:match(hostname)
		or line:match("@" .. hostname)
		or line:match(username .. "@")
		or line:match("^%$")
		or line:match("^#")
		or line:match("^>")
		or line:match("^%%%s")
end

-- Helper: Find prompt indices in output
local function find_prompt_indices(lines, hostname, username)
	local last_prompt = nil
	local second_last_prompt = nil

	for i = #lines, 1, -1 do
		if is_prompt_line(lines[i], hostname, username) then
			if not last_prompt then
				last_prompt = i
			elseif not second_last_prompt then
				second_last_prompt = i
				break
			end
		end
	end

	return second_last_prompt, last_prompt
end

-- Helper: Extract command output between prompts
local function extract_command_output(lines, second_last_idx, last_idx)
	local output_lines = {}

	if second_last_idx and last_idx then
		-- Get lines between prompts (the command output)
		for i = second_last_idx + 1, last_idx - 1 do
			if lines[i] then
				table.insert(output_lines, lines[i])
			end
		end
	elseif last_idx then
		-- Only one prompt found, get everything after it
		for i = last_idx + 1, #lines do
			if lines[i] then
				table.insert(output_lines, lines[i])
			end
		end
	else
		-- No prompt found, get last non-empty lines
		local found_content = false
		for i = #lines, 1, -1 do
			if lines[i] ~= "" or found_content then
				found_content = true
				table.insert(output_lines, 1, lines[i])
				if #output_lines > MAX_OUTPUT_LINES then
					break
				end
			end
		end
	end

	-- Trim trailing empty lines
	while #output_lines > 0 and output_lines[#output_lines] == "" do
		table.remove(output_lines)
	end

	return output_lines
end

-- Capture tmux session output and insert as code block
vim.keymap.set("n", "<space>yo", function()
	-- Check if tmux session exists
	local check_cmd = string.format("tmux has-session -t %s 2>/dev/null", TMUX_SESSION)
	vim.fn.system(check_cmd)

	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo(
			{ {
				string.format("Tmux session '%s' not found", TMUX_SESSION),
				"ErrorMsg",
			} },
			true,
			{}
		)
		return
	end

	-- Capture output from tmux pane
	local capture_cmd = string.format("tmux capture-pane -t %s -p -S -%d", TMUX_SESSION, TMUX_CAPTURE_LINES)
	local output = vim.fn.system(capture_cmd)

	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({ {
			"Failed to capture tmux output: " .. output,
			"ErrorMsg",
		} }, true, {})
		return
	end

	-- Get system info for prompt detection
	local hostname = vim.fn.system("hostname"):gsub("\n", "")
	local username = vim.fn.system("whoami"):gsub("\n", "")

	-- Process captured output
	local lines = vim.split(output, "\n")
	local second_last_idx, last_idx = find_prompt_indices(lines, hostname, username)
	local output_lines = extract_command_output(lines, second_last_idx, last_idx)

	if #output_lines > 0 then
		-- Build code block
		local code_block = { "", "```output" }
		vim.list_extend(code_block, output_lines)
		table.insert(code_block, "```")
		table.insert(code_block, "")

		-- Insert at cursor position
		local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
		vim.api.nvim_buf_set_lines(0, cursor_line, cursor_line, false, code_block)

		-- Move cursor after inserted block
		vim.api.nvim_win_set_cursor(0, { cursor_line + #code_block, 0 })

		vim.api.nvim_echo({ {
			"Command output captured and inserted",
			"Normal",
		} }, true, {})
	else
		vim.api.nvim_echo({ {
			"No output captured from last command",
			"WarningMsg",
		} }, true, {})
	end
end, { noremap = true, silent = true, desc = "Capture last command output from tmux test session" })

-- vim.opt.clipboard = "unnamedplus,unnamed"
vim.keymap.set("v", "<space>y", function()
	-- Use vim.fn.getreg to store the original visual selection
	local sel = vim.fn.getreg("v")

	-- Yank to both registers
	vim.cmd('normal! "+y')

	-- Optional: Restore the visual selection
	vim.fn.setreg("v", sel)
end, { noremap = true, silent = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "ssh-config" },
	callback = function()
		vim.bo.filetype = "sshconfig"
	end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "*.jenkinsfile" },
	callback = function()
		vim.bo.filetype = "groovy"
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

-- Function to open current line on GitHub
function OpenGithubLine()
	-- Get the remote URL
	local handle = io.popen("git remote get-url origin")
	if not handle then
		return
	end
	local remote = handle:read("*a")
	handle:close()

	-- Clean up the remote URL to get the base GitHub URL
	-- Convert SSH URL to HTTPS if necessary
	remote = remote:gsub("^git@github.com:", "https://github.com/")
	remote = remote:gsub("%.git\n$", "")

	-- Get current branch (falls back to master/main if not in a branch)
	handle = io.popen("git rev-parse --abbrev-ref HEAD")
	if not handle then
		return
	end
	local branch = handle:read("*a"):gsub("\n$", "")
	handle:close()

	-- Get relative file path from git root
	handle = io.popen("git rev-parse --show-toplevel")
	if not handle then
		return
	end
	local git_root = handle:read("*a"):gsub("\n$", "")
	handle:close()

	-- Get current file path relative to git root
	local current_file = vim.fn.expand("%:p")
	local relative_path = current_file:sub(#git_root + 2)

	-- Get current line number
	local line_num = vim.api.nvim_win_get_cursor(0)[1]

	-- Construct the GitHub URL
	local url = string.format("%s/blob/%s/%s#L%d", remote, branch, relative_path, line_num)

	-- Open URL in default browser
	local open_cmd
	if vim.fn.has("unix") == 1 then
		open_cmd = "xdg-open"
	else
		open_cmd = "start"
	end

	-- os.execute(open_cmd .. ' "' .. url .. '"')
	os.execute(open_cmd .. ' "' .. url .. '" > /dev/null 2>&1')
end

-- Create command
vim.api.nvim_create_user_command("GHline", OpenGithubLine, {})
