# If windows PortableGit env
# cat 'export HOME="/home/root"' >> /etc/bash.bashrc
# cat 'source /home/root/.bashrc' >> /etc/bash.bashrc
# cat 'cd $HOME' >> /etc/bash.bashrc
# cat 'set bell-style none' >> $HOME/.inputrc
export APPDATA=$HOME/.config # windows appdata path
export download=C:/Users/$USERNAME/Downloads # windows DL path

# $HOME/.bashrc
# 環境変数の設定
export LANGUAGE=ja_JP.ja
export LANG=ja_JP.UTF-8
export XDG_DATA_HOME=$HOME/.local/share # https://wiki.archlinux.org/title/XDG_Base_Directory
export XDG_CACHE_HOME=$HOME/.cache
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CONFIG_DIRS=/etc/xdg
export tools=$HOME/tools # your tools path
export EDITOR=nvim
export GOROOT=$HOME/go/ # Go本体(変更時のみ)

# リソース用PATHの追加
export PATH=$HOME/tools:$PATH
export PATH=$GOROOT/bin:$PATH # https://go.dev/dl/
export PATH=$HOME/python:$PATH # https://www.python.org/downloads/windows/
export PATH=$HOME/python/Scripts:$PATH 
export PATH=$HOME/Pinta/bin:$PATH # https://github.com/PintaProject/Pinta/releases
export PATH=$HOME/ripgrep:$PATH # https://github.com/BurntSushi/ripgrep/releases
export PATH=$HOME/nvim/bin:$PATH # https://github.com/neovim/neovim/releases
export PATH=$HOME/node:$PATH # https://nodejs.org/ja/download
export PATH=$HOME/lualsp/bin/:$PATH # https://github.com/LuaLS/lua-language-server/releases
export PATH=$HOME/gcc/bin/:$PATH # https://github.com/niXman/mingw-builds-binaries/releases
export PATH=$HOME/clangd/bin/:$PATH # https://github.com/clangd/clangd/releases
# export PATH=$HOME/:$PATH  

alias ll='ls -la --color=auto'

PROMPT_COMMAND='
  HOME_NAME=$(basename "$HOME")
  VENV=""
  if [ -n "$VIRTUAL_ENV" ]; then
    VENV="\[\e[35m\]("$(basename "$VIRTUAL_ENV")")\[\e[0m\]"
  fi
  PS1="$VENV\[\e[33m\]\[\e[0m\]\[\e[32m\][$HOME_NAME]\[\e[0m\][\u@\h \[\e[36m\]$(date +%Y%m%d_%H:%M)\[\e[0m\] \w]\n\$ "
'
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:erasedups
export HISTIGNORE="ls:bg:fg:history:pwd"
shopt -s histappend 2>/dev/null
[ -f "$HISTFILE" ] && history -r
PROMPT_COMMAND='history -a; history -n;'"$PROMPT_COMMAND"
