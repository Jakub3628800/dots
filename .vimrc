
set number "Display line numbers
syntax on "Highlight syntax

set autoindent "Use same indentation when entering a new line
set noerrorbells "No sound please
set tabstop=4 softtabstop=4

" plugins
" https://github.com/junegunn/vim-plug
call plug#begin('~/.vim/plugged')

Plug 'https://github.com/gruvbox-community/gruvbox' "For color scheme

call plug#end()

colorscheme gruvbox
