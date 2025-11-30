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

" asyncomplete.vim 推奨の completeopt
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
" 端末モード Esc → ノーマル
tnoremap <Esc> <C-\><C-n>

function! s:TermOpenOrInsert() abort
  if &buftype ==# 'terminal'
    " 既存ターミナルならジョブモードに戻る
    startinsert
  else
    " 現在のウィンドウでターミナルを開く
    terminal ++curwin
  endif
endfunction

" ノーマル: <Space>t → ターミナルを開く or 端末モードへ
nnoremap <silent> <leader>t :call <SID>TermOpenOrInsert()<CR>
" 端末モード: <Space>t → ノーマルモードへ
tnoremap <silent> <leader>t <C-\><C-n>

" バッファ切り替え / 閉じる
nnoremap <Tab>   :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <silent> <Space>q :bdelete<CR>

"==================================================
" LSP (vim-lsp / vim-lsp-settings)
"==================================================
" Plug マッピング（README や記事の例に沿った形）
nmap <silent> gd <Plug>(lsp-definition)
nmap <silent> gr <Plug>(lsp-references)
nmap <silent> K  <Plug>(lsp-hover)

nmap <silent> [g <Plug>(lsp-previous-diagnostic)
nmap <silent> ]g <Plug>(lsp-next-diagnostic)

"==================================================
" asyncomplete（自動ポップアップ）
"==================================================
" README / doc にある基本オプションに限定しています
let g:asyncomplete_auto_popup   = 1     " 入力中に自動ポップアップ
let g:asyncomplete_min_chars    = 1     " 1文字から候補を出す
let g:asyncomplete_popup_delay  = 200   " 200ms 待ってから表示

" すべてのバッファで有効化（公式の例と同じパターン）
augroup AsyncompleteEnable
  autocmd!
  autocmd BufEnter * call asyncomplete#enable_for_buffer()
augroup END

" ソース登録（buffer / file / LSP）
augroup AsyncompleteSources
  autocmd!

  " バッファ内の単語
  autocmd User asyncomplete_setup call asyncomplete#register_source(
        \ asyncomplete#sources#buffer#get_source_options({
        \   'name': 'buffer',
        \   'whitelist': ['*'],
        \   'completor': function('asyncomplete#sources#buffer#completor'),
        \ }))

  " ファイルパス
  autocmd User asyncomplete_setup call asyncomplete#register_source(
        \ asyncomplete#sources#file#get_source_options({
        \   'name': 'file',
        \   'whitelist': ['*'],
        \   'priority': 10,
        \   'completor': function('asyncomplete#sources#file#completor'),
        \ }))

  " LSP 補完（asyncomplete-lsp.vim）
  autocmd User asyncomplete_setup call asyncomplete#register_source(
        \ asyncomplete#sources#lsp#get_source_options({
        \   'name': 'lsp',
        \   'whitelist': ['*'],
        \   'priority': 15,
        \ }))
augroup END

" PUM 操作（README でもよく紹介される形）
inoremap <expr> <Tab>    pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab>  pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>     pumvisible() ? "\<C-y>" : "\<CR>"

" 手動補完トリガー（README 記載の <C-Space>）
inoremap <silent> <C-Space> <Plug>(asyncomplete_force_refresh)

"==================================================
" OSC52 Yank (vim-oscyank)
"==================================================
" README 推奨のマッピング
nmap <leader>c  <Plug>OSCYankOperator
nmap <leader>cc <leader>c_
vmap <leader>c  <Plug>OSCYankVisual

" yank したテキストを自動で OSC52 でコピー（README の :OSCYankRegister に沿った簡易版）
if exists(':OSCYankRegister')
  augroup osc52_yank
    autocmd!
    autocmd TextYankPost *
          \ if v:event.operator ==# 'y' && v:event.regname ==# '' |
          \   execute 'OSCYankRegister "' |
          \ endif
  augroup END
endif
