" $ apk add fd ripgrep
" $ apk add vim git curl
" $ apk add deno
" $ curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" $ mkdir -p ~/.skk
" $ curl -o ~/.skk/SKK-JISYO.L https://skk-dev.github.io/dict/SKK-JISYO.L
" ~/.vimrc
" vim-plugの初期化
call plug#begin('~/.vim/plugged')
" 1. Git連携を便利にするプラグイン（例: vim-fugitive）
Plug 'tpope/vim-fugitive'
" 2. 自動保存を行うプラグイン（例: vim-auto-save）
Plug '907th/vim-auto-save'
Plug 'vim-denops/denops.vim'
Plug 'vim-skk/skkeleton'

call plug#end()

" Ctrl-j でSKKモードON
inoremap <C-j> <Plug>(skkeleton-enable)
" l:SKKモード中の「英字（latin）モード」へ
" ESC:Vim本体の挿入モード脱出

" SKK辞書設定（任意、下で詳述）
autocmd User skkeleton-initialize-pre call skkeleton#config({'globalDictionaries': ['~/.skk/SKK-JISYO.L']})

" vim-auto-saveの設定
let g:auto_save = 1                               " 自動保存を有効化
let g:auto_save_events = ["InsertLeave", "TextChanged"] " 特定のイベントで保存
let g:auto_save_silent = 1     

" 行番号(相対表示)
set number
set relativenumber