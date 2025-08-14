" need -> git nodejs npm
" === Leader ===
" ※ Leaderは全マップ定義より前に
let mapleader = " "

" — XDG固定（Cocが使う場所を明示） —
let g:coc_config_home = expand(‘~/.config/coc’)
let g:coc_data_home = expand(‘~/.local/share/coc’)
let g:coc_cache_home = expand(‘~/.cache/coc’)

" — 新レイアウト対応：パッケージ直下をrtpへ —
set rtp+=~/.local/share/coc/extensions/node_modules/coc-explorer

" ~/.vimrc or init.vim
" curl -fLo /.vim/autoload/plug.vim –create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
call plug#begin(’/.vim/plugged’)

" ← release ならビルド不要
" Plug ‘neoclide/coc.nvim’, {‘branch’: ‘release’}

" ソース版を使うなら “npm ci” に固定（Yarn混用を避ける）
" cd ~/.vim/plugged/coc.nvim # or ~/.local/share/nvim/plugged/coc.nvim
" npm ci
" test -f build/index.js && echo “OK: build/index.js generated”
Plug ‘neoclide/coc.nvim’, {‘do’: ‘npm ci’}
Plug ‘vim-skk/skk.vim’
Plug ‘crusoexia/vim-monokai’
Plug ‘vimwiki/vimwiki’

call plug#end()

" === 基本文字コード設定 ===
set encoding=utf-8
scriptencoding utf-8

" === 基本エディタ設定 ===
filetype plugin indent on
syntax enable
colorscheme monokai
set t_Co=256

" — 表示系 —
set number
set relativenumber
set cursorline

" — インデント/タブ —
set expandtab
set tabstop=4
set shiftwidth=4
set autoindent
set smartindent
set backspace=indent,eol,start

" — 編集/検索 —
set clipboard=unnamed
set showmatch
set wildmenu
set ignorecase
set smartcase
set incsearch
set hlsearch
set laststatus=2
set updatetime=300
set completeopt=menuone,noinsert,noselect

" == gf ==
set path+=**
" set path+=//server/share/**
" e scp://user@host//path/to/file.txt
" au FileType markdown setlocal isfname+=@-@
" nnoremap gu :!xdg-open
" set path-=/usr/include
" set suffixesadd+=.md,.txt,.py,.go

" === vimwiki 設定 ===
let g:vimwiki_list = [{‘path’: ‘~/vimwiki/’, ‘syntax’: ‘markdown’, ‘ext’: ‘md’}]

" === coc.nvim: Finder/Tree/Terminal ===
" CocList（files/grep）
nnoremap f :CocList files
nnoremap r :CocList grep
" coc-explorer（要: :CocInstall coc-explorer）
nnoremap e :CocCommand explorer –toggle
" Terminal
nnoremap t :terminal

" === coc.nvim: LSP操作 ===
" classic ‘gd/gy/gi/gr’ も残しつつ、上書きは へ委譲
nmap gd (coc-definition)
nmap gy (coc-type-definition)
nmap gi (coc-implementation)
nmap gr (coc-references)

" Leader系（元の d/y/i/R パターンに準拠）
nnoremap d (coc-definition)
nnoremap y (coc-type-definition)
nnoremap i (coc-implementation)
nnoremap R (coc-references)

" 診断移動・Hover
nnoremap [g (coc-diagnostic-prev)
nnoremap ]g (coc-diagnostic-next)
nnoremap K :call CocActionAsync(‘doHover’)

" === Vimwiki ===
nnoremap w :VimwikiIndex

" === coc.nvim: 補完ポップアップ操作 ===
" PUM visible? → coc#pum#visible()
" next/prev → coc#pum#next(1) / coc#pum#prev(1)
" confirm → coc#pum#confirm()
" refresh → coc#refresh()
inoremap coc#pum#visible() ? coc#pum#next(1) : “<Tab>”
inoremap coc#pum#visible() ? coc#pum#prev(1) : “<S-Tab>”
inoremap coc#pum#visible() ? coc#pum#confirm() : “<CR>”
inoremap coc#refresh()
inoremap coc#pum#visible() ? coc#pum#next(1) : “<C-n>”
inoremap coc#pum#visible() ? coc#pum#prev(1) : “<C-p>”

" === coc-snippets（UltiSnips相当のC-j/C-k運用） ===
" 要: :CocInstall coc-snippets
imap coc#pum#visible() ? coc#pum#confirm() : “(coc-snippets-expand-jump)”
smap (coc-snippets-expand-jump)
imap (coc-snippets-jump-prev)
smap (coc-snippets-jump-prev)

" === skk.vim ===
" wget http://openlab.jp/skk/dic/SKK-JISYO.L.gz
" gzip -d SKK-JISYO.L.gz
let g:skk_jisyo = expand(‘~/.skk-jisyo’)
let g:skk_large_jisyo = ‘~/.skk/SKK-JISYO.L’
let g:skk_control_j_key = ‘’
let g:skk_auto_save_jisyo = 1
let g:skk_egg_like_newline = 1
let g:skk_kutouten_type = ‘jp’
let &statusline .= ‘%{SkkGetModeStr()}’