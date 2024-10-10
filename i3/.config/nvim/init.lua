-- Bootstrap lazy.nvim
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
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {},
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.nvim', -- if you use the mini.nvim suite
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
})

-- Basic Neovim settings
vim.opt.number = true  -- Show line numbers
vim.opt.expandtab = true  -- Use spaces instead of tabs
vim.opt.shiftwidth = 2  -- Size of an indent
vim.opt.softtabstop = 2  -- Number of spaces tabs count for in insert mode
vim.opt.smartindent = true  -- Insert indents automatically
vim.opt.termguicolors = true -- Enable 24-bit RGB color in the TUI

-- Key mappings
vim.g.mapleader = " "  -- Set leader key to space

-- Define the custom command
vim.api.nvim_create_user_command('Tabn', 'tabnew | Ex', {})

-- Map Ctrl+Enter to the custom command
vim.api.nvim_set_keymap('n', '<C-CR>', ':Tabn<CR>', { noremap = true, silent = true })

-- Define a new command Exh
 vim.api.nvim_create_user_command('Hh', function()
    local current_file = vim.fn.expand('%:p')
    local current_dir = vim.fn.fnamemodify(current_file, ':h')
    vim.cmd('edit ' .. vim.fn.fnameescape(current_dir))
end, {})



vim.api.nvim_create_user_command('Cc', function()
    -- Get the current line
    local line = vim.api.nvim_get_current_line()
    
    -- Check if the line contains a checkbox (checked or unchecked)
    local new_line
    if line:match('%[[ x]%]') then
        -- Toggle the checkbox state
        new_line = line:gsub('%[[ x]%]', function(match)
            return match == '[ ]' and '[x]' or '[ ]'
        end, 1)
        
        -- Get the current cursor position
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        
        -- Replace the current line with the new line
        vim.api.nvim_set_current_line(new_line)
        
        -- Set the cursor position to the same column
        vim.api.nvim_win_set_cursor(0, {row, col})
    end
end, {})
