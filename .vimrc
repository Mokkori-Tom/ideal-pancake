"==================================================
" 基本
"==================================================
set shell=/usr/bin/fish
set encoding=utf-8
scriptencoding utf-8

let mapleader = " "

"==================================================
" 外部変更の自動反映
"==================================================
set autoread
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * checktime

"==================================================
" プラグイン
"==================================================
call plug#begin('~/.vim/plugged')
  Plug 'crusoexia/vim-monokai'
  Plug 'ojroques/vim-oscyank', { 'branch': 'main' }
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  Plug 'prabirshrestha/async.vim'
  Plug 'prabirshrestha/vim-lsp'
  Plug 'mattn/vim-lsp-settings'

  Plug 'prabirshrestha/asyncomplete.vim'
  Plug 'prabirshrestha/asyncomplete-lsp.vim'
  Plug 'prabirshrestha/asyncomplete-file.vim'
  Plug 'prabirshrestha/asyncomplete-buffer.vim'

  " SKK (skk-cli + asyncomplete-skk)
  Plug 'mattn/asyncomplete-skk.vim'
call plug#end()

"==================================================
" 画面 / 基本設定
"==================================================
set hidden
filetype plugin indent on
syntax enable

set t_Co=256
colorscheme monokai

set number
set relativenumber
set cursorline

set expandtab
set tabstop=4
set shiftwidth=4
set autoindent
set smartindent
set backspace=indent,eol,start

set clipboard=unnamedplus
set showmatch
set wildmenu

set ignorecase
set smartcase
set incsearch
set hlsearch

set laststatus=2
set updatetime=300

set completeopt=menuone,noinsert,noselect

" gf 用
set path+=**

"==================================================
" FZF / ripgrep
"==================================================
nnoremap <silent> <Space>ff :Files<CR>
nnoremap <silent> <Space>fg :GFiles<CR>
nnoremap <silent> <Space>fb :Buffers<CR>
nnoremap <silent> <Space>fl :Lines<CR>
nnoremap <silent> <Space>fr :Rg<CR>

if executable('fd')
  let $FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
elseif executable('rg')
  let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow -g \"!{.git,node_modules}\"'
endif

let g:rg_command = 'rg --vimgrep --hidden -g \"!{.git,node_modules}\"'
let g:fzf_layout = { 'down': '80%' }
let g:fzf_preview_window = ['right:60%']
let g:fzf_files_options =
      \ '--preview "/usr/bin/bash ''~/.vim/plugged/fzf.vim/bin/preview.sh'' {}"'

"==================================================
" ターミナル (<Space>t)
"==================================================
tnoremap <Esc> <C-\><C-n>

function! s:TermOpenOrInsert() abort
  if &buftype ==# 'terminal'
    startinsert
  else
    terminal ++curwin
  endif
endfunction

nnoremap <silent> <leader>t :call <SID>TermOpenOrInsert()<CR>
tnoremap <silent> <leader>t <C-\><C-n>

nnoremap <Tab>   :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <silent> <Space>q :bdelete<CR>

"==================================================
" LSP (vim-lsp / vim-lsp-settings)
"==================================================
nmap <silent> gd <Plug>(lsp-definition)
nmap <silent> gr <Plug>(lsp-references)
nmap <silent> K  <Plug>(lsp-hover)

nmap <silent> [g <Plug>(lsp-previous-diagnostic)
nmap <silent> ]g <Plug>(lsp-next-diagnostic)

"==================================================
" asyncomplete
"==================================================
let g:asyncomplete_auto_popup   = 1
let g:asyncomplete_min_chars    = 1
let g:asyncomplete_popup_delay  = 200

augroup AsyncompleteEnable
  autocmd!
  autocmd BufEnter * call asyncomplete#enable_for_buffer()
augroup END

augroup AsyncompleteSources
  autocmd!
  autocmd User asyncomplete_setup call asyncomplete#register_source(
        \ asyncomplete#sources#buffer#get_source_options({
        \   'name': 'buffer',
        \   'whitelist': ['*'],
        \   'completor': function('asyncomplete#sources#buffer#completor'),
        \ }))
  autocmd User asyncomplete_setup call asyncomplete#register_source(
        \ asyncomplete#sources#file#get_source_options({
        \   'name': 'file',
        \   'whitelist': ['*'],
        \   'priority': 10,
        \   'completor': function('asyncomplete#sources#file#completor'),
        \ }))
augroup END

inoremap <expr> <Tab>    pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab>  pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>     pumvisible() ? "\<C-y>" : "\<CR>"

inoremap <silent> <C-Space> <Plug>(asyncomplete_force_refresh)

"==================================================
" SKK (asyncomplete-skk + skk-cli)
"==================================================
" 挿入モードで C-j で SKK ON/OFF
imap <silent> <C-j> <Plug>(asyncomplete-skk-toggle)

"==================================================
" OSC52 Yank (vim-oscyank)
"==================================================
nmap <leader>c  <Plug>OSCYankOperator
nmap <leader>cc <leader>c_
vmap <leader>c  <Plug>OSCYankVisual

if exists(':OSCYankRegister')
  augroup osc52_yank
    autocmd!
    autocmd TextYankPost *
          \ if v:event.operator ==# 'y' && v:event.regname ==# '' |
          \   execute 'OSCYankRegister "' |
          \ endif
  augroup END
endif
