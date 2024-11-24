chcp 65001

:: Git for WindowsのPortableバージョンをダウンロード
curl --ssl-no-revoke -L -o "%cd%\PortableGit-2.47.0.2-64-bit.7z.exe" "https://github.com/git-for-windows/git/releases/download/v2.47.0.windows.2/PortableGit-2.47.0.2-64-bit.7z.exe"

echo "現在のディレクトリを選択してください。"
:: PortableGitのインストーラーを実行
"%cd%\PortableGit-2.47.0.2-64-bit.7z.exe"

"%cd%\PortableGit\bin\git.exe" config --global htp.ss|Verify false

:: 環境変数PATHの設定
:: setxを使用する場合は永続的に設定され、他のアプリケーションにも影響するため注意
set PATH=%PATH%;%cd%\PortableGit\bin
for /f "tokens=2,*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set oldpath=%%b
set newpath=;%cd%\PortableGit\bin
setx PATH "%oldpath%%newpath%"

:: 必要な設定ファイルを作成
mkdir "%cd%\.local\share"
mkdir "%cd%\.local\cache"
mkdir "%cd%\.local\state"
mkdir "%cd%\localappdata"
mkdir "%cd%\tree-1.5.2.2-bin"
::mkdir "%cd%\nvim"
type nul > "%cd%\.pythonrc.py"
type nul > "%cd%\.bash_history"
type nul > "%cd%\.bashrc"
::type nul > "%cd%\nvim\init.lua"

:: bash.bashrcにGit Bashの設定を追加
:: ユーザーのホームディレクトリとエンコーディングを設定
echo source '%cd%\.bashrc' >> "%cd%\PortableGit\etc\bash.bashrc"
echo export HOME='%cd%' >> "%cd%\.bashrc"
echo export XDG_CONFIG_HOME=$HOME >> "%cd%\.bashrc"
echo export XDG_DATA_HOME=$HOME'\.local\share' >> "%cd%\.bashrc"
echo export XDG_CACHE_HOME=$HOME'\.local\cache' >> "%cd%\.bashrc"
echo export XDG_STATE_HOME=$HOME'\.local\state' >> "%cd%\.bashrc"
echo export LOCALAPPDATA=$HOME'\localappdata' >> "%cd%\.bashrc"
echo export LANG=ja_JP.UTF-8 >> "%cd%\PortableGit\etc\bash.bashrc"
echo export LANGUAGE=ja_JP.ja >> "%cd%\PortableGit\etc\bash.bashrc"

:: コマンド履歴の設定
echo export HISTTIMEFORMAT='%%F %%T ' >> "%cd%\PortableGit\etc\bash.bashrc"
echo export HISTFILE="$HOME\.bash_history" >> "%cd%\PortableGit\etc\bash.bashrc"

:: プロンプトに日時と色を追加
echo export PS1='\[\e[32m\][\D{%%Y-%%m-%%d %%H:%%M:%%S}]\[\e[0m\] \[\e[34m\]\u@\h\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]\$ ' >> "%cd%\PortableGit\etc\bash.bashrc"

:: Python関連設定を追加
echo export PYTHONSTARTUP="$HOME\.pythonrc.py" >> "%cd%\PortableGit\etc\bash.bashrc"

:: エイリアスの設定を追加
echo alias ll='ls -la' >> "%cd%\PortableGit\etc\bash.bashrc"
echo alias edge='"C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"' >> "%cd%\PortableGit\etc\bash.bashrc"
echo alias exp='"C:\Windows\explorer.exe"' >> "%cd%\PortableGit\etc\bash.bashrc"

:: 履歴保存設定
echo shopt -s histappend >> "%cd%\PortableGit\etc\bash.bashrc"
echo PROMPT_COMMAND="history -a; history -n" >> "%cd%\PortableGit\etc\bash.bashrc"

:::: Neovim ::::
:: Neovimのダウンロードと解凍、PATH設定
curl --ssl-no-revoke -L -o "%cd%\nvim-win64.zip"  "https://github.com/neovim/neovim/releases/download/v0.10.2/nvim-win64.zip"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\nvim-win64.zip"
echo export PATH=$HOME'\nvim-win64\bin':$PATH >> "%cd%\.bashrc"

:::: Python ::::
:: Pythonのダウンロードと解凍、環境設定
curl --ssl-no-revoke -L -o "%cd%\python-3.13.0-embed-amd64.zip"  "https://www.python.org/ftp/python/3.13.0/python-3.13.0-embed-amd64.zip"
mkdir "%cd%\python-313"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\python-3.13.0-embed-amd64.zip" -d "%cd%\python-313"
echo export PATH=$HOME'\python-313':$PATH >> "%cd%\.bashrc"

:: Python import siteを有効化
setlocal enabledel /Qayedexpansion

echo python313.zip > "%cd%\python-313\python313_temp._pth"
echo . >> "%cd%\python-313\python313_temp._pth"
echo. >> "%cd%\python-313\python313_temp._pth"
echo # Uncomment to run site.main() automatically >> "%cd%\python-313\python313_temp._pth"
echo import site >> "%cd%\python-313\python313_temp._pth"

move /y "%cd%\python-313\python313_temp._pth" "%cd%\python-313\python313._pth"

endlocal

:: pipをダウンロードしてインストール
curl --ssl-no-revoke -L -o "%cd%\python-313\get-pip.py"  "https://bootstrap.pypa.io/pip/get-pip.py"
"%cd%\python-313\python.exe" "%cd%\python-313\get-pip.py"
echo export PATH=$HOME'\python-313\Scripts':$PATH >> "%cd%\.bashrc"

::::Deno_JS ::::
:: Deno_jsのダウンロードと解凍、PATH設定
curl --ssl-no-revoke -L -o "%cd%\deno-x86_64-pc-windows-msvc.zip"  "https://github.com/denoland/deno/releases/download/v2.0.6/deno-x86_64-pc-windows-msvc.zip"
mkdir "%cd%\deno-206"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\deno-x86_64-pc-windows-msvc.zip" -d "%cd%\deno-206"
echo export PATH=$HOME'\deno-206':$PATH >> "%cd%\.bashrc"

:::: NodeJS ::::
:: Node.jsのダウンロードと解凍、PATH設定
curl --ssl-no-revoke -L -o "%cd%\node-v22.11.0-win-x64.zip"  "https://nodejs.org/dist/v22.11.0/node-v22.11.0-win-x64.zip"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\node-v22.11.0-win-x64.zip"
echo export PATH=$HOME'\node-v22.11.0-win-x64':$PATH >> "%cd%\.bashrc"

:::: Clang ::::
:: Clangのダウンロードと解凍、PATH設定
::curl --ssl-no-revoke -L -o "%cd%\clang+llvm-18.1.8-x86_64-pc-windows-msvc.tar.xz"  "https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-pc-windows-msvc.tar.xz"
::tar -xf "%cd%\clang+llvm-18.1.8-x86_64-pc-windows-msvc.tar.xz"
::echo export PATH=$HOME'\clang+llvm-18.1.8-x86_64-pc-windows-msvc\bin':$PATH >> "%cd%\.bashrc"

::repgrep::
curl --ssl-no-revoke -L -o "%cd%\ripgrep-14.1.0-x86_64-pc-windows-gnu.zip"  "https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-pc-windows-gnu.zip"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\ripgrep-14.1.0-x86_64-pc-windows-gnu.zip"
echo export PATH=$HOME'\ripgrep-14.1.0-x86_64-pc-windows-gnu':$PATH >> "%cd%\.bashrc"

::bashtree::
curl --ssl-no-revoke -L -o "%cd%\tree-1.5.2.2-bin.zip"  "http://downloads.sourceforge.net/gnuwin32/tree-1.5.2.2-bin.zip"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\tree-1.5.2.2-bin.zip" -d "%cd%\tree-1.5.2.2-bin"
echo export PATH=$HOME'\tree-1.5.2.2-bin\bin':$PATH >> "%cd%\.bashrc"

::fd::
curl --ssl-no-revoke -L -o "%cd%\fd-v10.2.0-x86_64-pc-windows-msvc.zip"  "https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-pc-windows-msvc.zip"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\fd-v10.2.0-x86_64-pc-windows-msvc.zip"
echo export PATH=$HOME'\fd-v10.2.0-x86_64-pc-windows-msvc':$PATH >> "%cd%\.bashrc"

::PowerShell::
curl --ssl-no-revoke -L -o "%cd%\PowerShell-7.4.6-win-x64.zip"  "https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.zip"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\PowerShell-7.4.6-win-x64.zip" -d "%cd%\PowerShell-7.4.6-win-x64"
echo export PATH=$HOME'\PowerShell-7.4.6-win-x64':$PATH >> "%cd%\.bashrc"

::::nvim_pulgin_setting::::
"%cd%\PortableGit\bin\git.exe" clone "https://github.com/LazyVim/starter" "%cd%\nvim"

(
echo vim.api.nvim_create_autocmd("VimEnter", {
echo  callback = function(^)
echo      vim.cmd("TransparentEnable"^)
echo   end
echo }^)
) >> "%cd%\nvim\init.lua"

type nul > "%cd%\nvim\lua\plugins\colorscheme"
(
echo return {
echo  { "xiyaowong/transparent.nvim", "shaunsingh/nord.nvim" },
echo  { "neanias/everforest-nvim" },
echo  { "LazyVim/LazyVim", opts = {
echo    colorscheme = "nord",
echo  } },
echo }
) > "%cd%\nvim\lua\plugins\colorscheme.lua"

(
echo -- 挿入ノーマルモード維持
echo vim.api.nvim_set_keymap("n", "o", ":<C-u>call append(expand('.'), '')<Cr>j", { noremap = true, silent = true }^)
) >> "%cd%\nvim\lua\config\keymaps.lua"

::フォント::
::mkdir "%cd%\HackGen_NF_v2.9.0"
::curl --ssl-no-revoke -L -o "%cd%\HackGen_NF_v2.9.0.zip"  "https://github.com/yuru7/HackGen/releases/download/v2.9.0/HackGen_NF_v2.9.0.zip"
::"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\HackGen_NF_v2.9.0.zip" -d "%cd%\HackGen_NF_v2.9.0"

:: 7zip
curl --ssl-no-revoke -L -o "%cd%\7zr.exe"  "https://www.7-zip.org/a/7zr.exe"
echo alias 7z="'$HOME/7zr.exe'" >> "%cd%\.bashrc"

::mingw::
curl --ssl-no-revoke -L -o "%cd%\x86_64-8.1.0-release-posix-sjlj-rt_v6-rev0.7z"  "https://sourceforge.net/projects/mingw-w64/files/Toolchains%%20targetting%%20Win64/Personal%%20Builds/mingw-builds/8.1.0/threads-posix/sjlj/x86_64-8.1.0-release-posix-sjlj-rt_v6-rev0.7z/download"
REM tar -xf "%cd%\x86_64-8.1.0-release-posix-sjlj-rt_v6-rev0.7z"
"%cd%\7zr.exe" x "%cd%\x86_64-8.1.0-release-posix-sjlj-rt_v6-rev0.7z"
echo export PATH=$HOME'\mingw64\bin':$PATH >> "%cd%\.bashrc"

::::PortableGit\usr\binのパスは常に最下に::::
echo #PortableGit_binのパスは常に最下に >> "%cd%\.bashrc"
echo export PATH=$HOME'\PortableGit\usr\bin':$PATH >> "%cd%\.bashrc"

:::: ダウンロード後のクリーンアップ ::::
:: 不要なダウンロードファイルを削除
mkdir "%cd%\Download"
del /Q "%cd%\PortableGit-2.47.0.2-64-bit.7z.exe"
del /Q "%cd%\nvim-win64.zip"
del /Q "%cd%\python-3.13.0-embed-amd64.zip"
del /Q "%cd%\deno-x86_64-pc-windows-msvc.zip"
del /Q "%cd%\node-v22.11.0-win-x64.zip"
del /Q "%cd%\cmake-3.31.0-windows-x86_64.zip"
del /Q "%cd%\clang+llvm-18.1.8-x86_64-pc-windows-msvc.tar.xz"
del /Q "%cd%\HackGen_NF_v2.9.0.zip"
del /Q "%cd%\ripgrep-14.1.0-x86_64-pc-windows-gnu.zip"
del /Q "%cd%\tree-1.5.2.2-bin.zip"
del /Q "%cd%\fd-v10.2.0-x86_64-pc-windows-msvc.zip"
del /Q "%cd%\x86_64-8.1.0-release-posix-sjlj-rt_v6-rev0.7z"
del /Q "%cd%\PowerShell-7.4.6-win-x64.zip"

echo "ログチェックが終わってからエンターキーを押してね"
pause
