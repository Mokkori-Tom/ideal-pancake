" --- plugins ---  
call plug#begin('~/.vim/plugged')  
  Plug 'prabirshrestha/async.vim'  
  Plug 'prabirshrestha/vim-lsp'  
  Plug 'mattn/vim-lsp-settings'  
  
  Plug 'prabirshrestha/asyncomplete.vim'  
  Plug 'prabirshrestha/asyncomplete-lsp.vim'   " LSP 補完  
  Plug 'prabirshrestha/asyncomplete-file.vim'  " パス補完  
call plug#end()  
  
" 外部更新の自動読み直し  
set autoread  
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * checktime  
set updatetime=1000  
  
" ============================  
" asyncomplete 基本設定  
" ここでは自動ポップは使わず、LSP 用にだけ残す  
" ============================  
let g:asyncomplete_auto_popup        = 0      " 自動ポップアップはオフ  
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
" PUM の基本設定  
" ============================  
" バッファ中心でキーワード補完  
set complete=.,w,b,u,t  
  
" PUM の見え方  
set completeopt=menuone,noinsert,noselect  
  
" PUM 操作  
inoremap <expr> <Tab>    pumvisible() ? "\<C-n>" : "\<Tab>"  
inoremap <expr> <S-Tab>  pumvisible() ? "\<C-p>" : "\<S-Tab>"  
" 補完メニュー表示中は <CR> で確定、そうでなければ改行  
inoremap <expr> <CR>     pumvisible() ? "\<C-y>" : "\<CR>"  
  
" 手動でバッファ内キーワード補完したいとき  
inoremap <C-Space> <C-x><C-n>  
  
" ============================  
" キーワード / パス補完の自動ポップアップ  
" ============================  
  
" 何文字以上でキーワード補完を始めるか  
let g:kw_complete_minlen = 2  
  
function! s:SmartComplete() abort  
  " 念のため：挿入モード以外・特殊バッファでは何もしない  
  if mode() !=# 'i' || &buftype !=# ''  
    return  
  endif  
  
  " すでに補完メニューが出ていたら何もしない  
  if pumvisible()  
    return  
  endif  
  
  let l:col  = col('.')  
  if l:col <= 1  
    return  
  endif  
  
  let l:line = getline('.')  
  let l:prev = l:line[l:col - 2]  
  
  " 直前の「単語」っぽいかたまりを取得（空白までさかのぼる）  
  let l:start = l:col - 1  
  while l:start > 0 && l:line[l:start - 1] !~# '\s'  
    let l:start -= 1  
  endwhile  
  let l:token = l:line[l:start : l:col - 2]  
  
  " ------- パスっぽいかどうかを判定 -------  
  " 例: "/", "./", "../foo", "~/foo", "src/main.c" など  
  let l:is_path = 0  
  if l:prev ==# '/'  
    let l:is_path = 1  
  elseif l:token =~# '^\.\./\|^\./\|^\~/\|/'  
    let l:is_path = 1  
  endif  
  
  if l:is_path  
    " パス補完 (C-x C-f) … 改行は入らない  
    call feedkeys("\<C-x>\<C-f>", 'n')  
    return  
  endif  
  
  " ------- それ以外はキーワード補完 (C-x C-n) -------  
  
  " 単語の先頭までさかのぼって長さを見る（\k = iskeyword 対象）  
  let l:kw_start = l:col - 1  
  while l:kw_start > 0 && l:line[l:kw_start - 1] =~# '\k'  
    let l:kw_start -= 1  
  endwhile  
  
  if l:col - l:kw_start < g:kw_complete_minlen  
    return  
  endif  
  
  " バッファ内キーワード補完  
  call feedkeys("\<C-x>\<C-n>", 'n')  
endfunction  
  
augroup AutoSmartComplete  
  autocmd!  
  " 挿入モードで文字が変わるたびにチェック  
  autocmd TextChangedI * call s:SmartComplete()  
augroup END