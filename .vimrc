set shell=/usr/bin/bash        

let mapleader = " "

" ~/.vimrc or init.vim
call plug#begin('~/.vim/plugged')

" カラースキーム・Wiki・クリップボードなど
Plug 'crusoexia/vim-monokai'
Plug 'vimwiki/vimwiki'
Plug 'ojroques/vim-oscyank'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" LSP + 補完まわり
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'prabirshrestha/asyncomplete-file.vim'

call plug#end()

" === 基本文字コード設定 ===
set encoding=utf-8
scriptencoding utf-8

" === 基本エディタ設定 ===
filetype plugin indent on
syntax enable
colorscheme monokai
set t_Co=256

" --- 表示系 ---
set number
set relativenumber
set cursorline

" --- インデント/タブ ---
set expandtab
set tabstop=4
set shiftwidth=4
set autoindent
set smartindent
set backspace=indent,eol,start

" --- 編集/検索 ---
set clipboard=unnamedplus
set showmatch
set wildmenu
set ignorecase
set smartcase
set incsearch
set hlsearch
set laststatus=2
set updatetime=300

" PUM の見え方
set completeopt=menuone,noinsert,noselect

" == gf ==
set path+=**
" set path+=//server/share/**
" e scp://user@host//path/to/file.txt
" au FileType markdown setlocal isfname+=@-@
" nnoremap <leader>gu :!xdg-open <cfile><CR>
" set path-=/usr/include
" set suffixesadd+=.md,.txt,.py,.go

" === vimwiki 設定 ===
let g:vimwiki_list = [{'path': '~/vimwiki/', 'syntax': 'markdown', 'ext': 'md'}]

" === LSP 操作 (vim-lsp) ===
" classic ‘gd/gy/gi/gr’ を vim-lsp 版に
nmap <silent> gd <Plug>(lsp-definition)
nmap <silent> gy <Plug>(lsp-type-definition)
nmap <silent> gi <Plug>(lsp-implementation)
nmap <silent> gr <Plug>(lsp-references)

" Leader 系ショートカット
nnoremap <silent> <leader>d <Plug>(lsp-definition)
nnoremap <silent> <leader>y <Plug>(lsp-type-definition)
nnoremap <silent> <leader>i <Plug>(lsp-implementation)
nnoremap <silent> <leader>R <Plug>(lsp-references)

" 診断移動・Hover
nmap <silent> [g <Plug>(lsp-previous-diagnostic)
nmap <silent> ]g <Plug>(lsp-next-diagnostic)
nmap <silent> K  <Plug>(lsp-hover)

" === Vimwiki ===
nnoremap <silent> <leader>w :VimwikiIndex<CR>

" === Terminal ===
nnoremap <silent> <leader>t :terminal<CR>

" ============================
" asyncomplete 基本設定
" ============================
let g:asyncomplete_auto_popup        = 0      " 補完はすべて手動トリガー
let g:asyncomplete_auto_completeopt  = 1
let g:asyncomplete_smart_completion  = 0
let g:asyncomplete_remove_duplicates = 0
unlet! g:asyncomplete_preprocessor             " 余計な絞り込みを無効化

" asyncomplete-file の登録（必要なら使えるようにだけしておく）
augroup AsyncompleteSources
  autocmd!
  autocmd User asyncomplete_setup call asyncomplete#register_source(
        \ asyncomplete#sources#file#get_source_options({
        \   'name': 'file',
        \   'allowlist': ['*'],
        \   'priority': 10,
        \   'completor': function('asyncomplete#sources#file#completor'),
        \ }))
augroup END

" ============================
" PUM の基本設定・操作キー
" ============================
" バッファ中心でキーワード補完
set complete=.,w,b,u,t

" PUM 操作（PUM 表示時だけ効かせる）
inoremap <expr> <Tab>    pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab>  pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>     pumvisible() ? "\<C-y>" : "\<CR>"

" ============================
" 手動補完トリガ
" ============================

" LSP / asyncomplete の補完を出す（LSP 用）
inoremap <silent> <C-Space> <Plug>(asyncomplete_force_refresh)

" Vim 標準の補完もそのまま利用可能:
"   Ctrl-x Ctrl-n : バッファ内キーワード補完
"   Ctrl-x Ctrl-f : パス補完

" ============================
" ヤンク時に自動でシステムクリップへ送る (OSC52)
" ============================
augroup osc52_yank
  autocmd!
  autocmd TextYankPost *
        \ if v:event.operator ==# 'y'
        \   && v:event.regname ==# ''
        \   && exists(':OSCYankReg') == 2 |
        \   execute 'OSCYankReg "' |
        \ endif
augroup END

" 検索ソース: fd 優先→rg
if executable('fd')
  let $FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
elseif executable('rg')
  let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow -g "!{.git,node_modules}"'
endif

" キーマップ (Leader を <Space> と仮定)
nnoremap <silent> <Space>ff :Files<CR>
nnoremap <silent> <Space>fg :GFiles<CR>
nnoremap <silent> <Space>fb :Buffers<CR>
nnoremap <silent> <Space>fl :Lines<CR>
nnoremap <silent> <Space>fr :Rg<CR>

" ripgrep 既定 (必要に応じ調整)
let g:rg_command = 'rg --vimgrep --hidden -g "!{.git,node_modules}"'

let g:fzf_layout = { 'down': '80%' }
let g:fzf_preview_window = ['right:60%']
" let g:fzf_preview_window = ['right:60%', 'ctrl-/:toggle']
let g:fzf_files_options = '--preview "/usr/bin/bash ''~/.vim/plugged/fzf.vim/bin/preview.sh'' {}"'
