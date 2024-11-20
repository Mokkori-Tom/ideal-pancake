chcp 65001

:: Git for WindowsのPortableバージョンをダウンロード
curl --ssl-no-revoke -L -o "%cd%\PortableGit-2.47.0.2-64-bit.7z.exe" "https://github.com/git-for-windows/git/releases/download/v2.47.0.windows.2/PortableGit-2.47.0.2-64-bit.7z.exe"

echo 現在のディレクトリを選択してください。
:: PortableGitのインストーラーを実行
"%cd%\PortableGit-2.47.0.2-64-bit.7z.exe"

:: 環境変数PATHの設定 (現在のセッションのみ有効)
:: setxを使用する場合は永続的に設定され、他のアプリケーションにも影響するため注意
set PATH=%PATH%;%cd%\PortableGit\bin
for /f "tokens=2,*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set oldpath=%%b
set newpath=;%cd%\PortableGit\bin
setx PATH "%oldpath%%newpath%"

:: 必要な設定ファイルを作成
type nul > "%cd%\.pythonrc.py"
type nul > "%cd%\.bash_history"
type nul > "%cd%\.bashrc"
mkdir "%cd%\nvim"
mkdir "%cd%\.local\share"
mkdir "%cd%\.local\cache"
mkdir "%cd%\.local\state"
mkdir "%cd%\localappdata"
type nul > "%cd%\nvim\_init.vim"
type nul > "%cd%\nvim\init.lua"

:: bash.bashrcにGit Bashの設定を追加
:: ユーザーのホームディレクトリとエンコーディングを設定
echo source '%cd%\.bashrc' >> "%cd%\PortableGit\etc\bash.bashrc"
echo export HOME='%cd%' >> "%cd%\.bashrc"
echo export XDG_CONFIG_HOME='%cd%' >> "%cd%\.bashrc"
echo export XDG_DATA_HOME='%cd%\.local\share' >> "%cd%\.bashrc"
echo export XDG_CACHE_HOME='%cd%\.local\cache' >> "%cd%\.bashrc"
echo export XDG_STATE_HOME='%cd%\.local\state' >> "%cd%\.bashrc"
echo export LOCALAPPDATA='%cd%\localappdata' >> "%cd%\.bashrc"
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
echo export PATH='%cd%\nvim-win64\bin':$PATH >> "%cd%\.bashrc"

:::: Python ::::
:: Pythonのダウンロードと解凍、環境設定
curl --ssl-no-revoke -L -o "%cd%\python-3.13.0-embed-amd64.zip"  "https://www.python.org/ftp/python/3.13.0/python-3.13.0-embed-amd64.zip"
mkdir "%cd%\python-313"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\python-3.13.0-embed-amd64.zip" -d "%cd%\python-313"
echo export PATH='%cd%\python-313':$PATH >> "%cd%\.bashrc"

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
echo export PATH='%cd%\python-313\Scripts':$PATH >> "%cd%\.bashrc"

::::Deno_JS ::::
:: Deno_jsのダウンロードと解凍、PATH設定
curl --ssl-no-revoke -L -o "%cd%\deno-x86_64-pc-windows-msvc.zip"  "https://github.com/denoland/deno/releases/download/v2.0.6/deno-x86_64-pc-windows-msvc.zip"
mkdir "%cd%\deno-206"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\deno-x86_64-pc-windows-msvc.zip"  -d "%cd%\deno-206"
echo export PATH='%cd%\deno-206':$PATH >> "%cd%\.bashrc"

:::: NodeJS ::::
:: Node.jsのダウンロードと解凍、PATH設定
curl --ssl-no-revoke -L -o "%cd%\node-v22.11.0-win-x64.zip"  "https://nodejs.org/dist/v22.11.0/node-v22.11.0-win-x64.zip"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\node-v22.11.0-win-x64.zip"
echo export PATH='%cd%\node-v22.11.0-win-x64':$PATH >> "%cd%\.bashrc"

:::: CMake ::::
:: CMakeのダウンロードと解凍、PATH設定
curl --ssl-no-revoke -L -o "%cd%\cmake-3.31.0-windows-x86_64.zip"  "https://github.com/Kitware/CMake/releases/download/v3.31.0/cmake-3.31.0-windows-x86_64.zip"
"%cd%\PortableGit\usr\bin\unzip.exe" "%cd%\cmake-3.31.0-windows-x86_64.zip"
echo export PATH='%cd%\cmake-3.31.0-windows-x86_64\bin':$PATH >> "%cd%\.bashrc"

::::PortableGit\usr\binのパスは常に最下に::::
echo #PortableGit_binのパスは常に最下に >> "%cd%\.bashrc"
echo export PATH='%cd%\PortableGit\usr\bin':$PATH >> "%cd%\.bashrc"

::::vim_pulgin_setting::::
curl --ssl-no-revoke -L -o "%cd%\nvim-win64\share\nvim\runtime\autoload\plug.vim"  "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
echo -- Plugin manager setup >> "%cd%\nvim\init.lua"
echo local plug = vim.fn['plug#begin']('~/.vim/plugged') >> "%cd%\nvim\init.lua"
echo. >> "%cd%\nvim\init.lua"
echo -- List your plugins here >> "%cd%\nvim\init.lua"
echo vim.fn['plug#']('vim-denops/denops.vim') >> "%cd%\nvim\init.lua"
echo vim.fn['plug#']('vim-denops/denops-helloworld.vim') >> "%cd%\nvim\init.lua"
echo vim.fn['plug#']('preservim/nerdcommenter') >> "%cd%\nvim\init.lua"
echo. >> "%cd%\nvim\init.lua"
echo vim.fn['plug#end']() >> "%cd%\nvim\init.lua"
echo. >> "%cd%\nvim\init.lua"
echo -- 行番号を表示 >> "%cd%\nvim\init.lua"
echo vim.opt.number = true >> "%cd%\nvim\init.lua"
echo. >> "%cd%\nvim\init.lua"
echo -- カラースキームの設定 >> "%cd%\nvim\init.lua"
echo vim.cmd('colorscheme vim') >> "%cd%\nvim\init.lua"
echo. >> "%cd%\nvim\init.lua"
echo -- init.lua >> "%cd%\nvim\init.lua"
echo vim.cmd [[filetype plugin on]] >> "%cd%\nvim\init.lua"

:::: ダウンロード後のクリーンアップ ::::
:: 不要なダウンロードファイルを削除
mkdir "%cd%\Download"
del /Q "%cd%\PortableGit-2.47.0.2-64-bit.7z.exe"
del /Q "%cd%\nvim-win64.zip"
del /Q "%cd%\python-3.13.0-embed-amd64.zip"
del /Q "%cd%\deno-x86_64-pc-windows-msvc.zip"
del /Q "%cd%\node-v22.11.0-win-x64.zip"
del /Q "%cd%\cmake-3.31.0-windows-x86_64.zip"

echo "インストールが終わってからエンターキーを押してね"
pause
