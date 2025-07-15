# If windows PortableGit env
# echo 'export HOME="/home/root"' >> /etc/bash.bashrc
# echo 'source /home/root/.bashrc' >> /etc/bash.bashrc
# echo 'set bell-style none' >> $HOME/.inputrc
export APPDATA=$HOME/.config # windows appdata path
export download=C:/Users/$USERNAME/Downloads # windows DL path

# $HOME/.bashrc
# set env
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

# Resource files
# https://www.python.org/downloads/windows
# https://github.com/PintaProject/Pinta/releases
# https://github.com/BurntSushi/ripgrep/releases
# https://github.com/neovim/neovim/releases
# https://nodejs.org/ja/downloads
# https://github.com/LuaLS/lua-language-server/releases
# https://github.com/niXman/mingw-builds-binaries/releases
# https://github.com/clangd/clangd/releases
# https://github.com/denoland/deno/releases
# https://github.com/junegunn/fzf/releases
# https://github.com/sharkdp/bat/releases
# https://rubyinstaller.org/downloads/
# https://github.com/dandavison/delta/releases
# https://dandavison.github.io/delta/
# https://github.com/sharkdp/fd/releases
# https://github.com/avih/uclip/releases
# https://github.com/jesseduffield/lazygit/releases
# https://github.com/charmbracelet/glow
export PATH=$PATH:$HOME/tools
export PATH=$PATH:$GOROOT/bin
export PATH=$PATH:$HOME/python
export PATH=$PATH:$HOME/python/Scripts
export PATH=$PATH:$HOME/Pinta/bin
export PATH=$PATH:$HOME/ripgrep
export PATH=$PATH:$HOME/nvim/bin
export PATH=$PATH:$HOME/node
export PATH=$PATH:$HOME/lualsp/bin
export PATH=$PATH:$HOME/gcc/bin
export PATH=$PATH:$HOME/clangd/bin 
export PATH=$PATH:$HOME/deno
export PATH=$PATH:$HOME/fzf 
export PATH=$PATH:$HOME/bat
export PATH=$PATH:$HOME/ruby/bin
export PATH=$PATH:$HOME/gitdelta
export PATH=$PATH:$HOME/glow

alias ll='ls -la --color=auto'
alias gimp="gimp --no-splash"
alias krita="krita --nosplash"

export HISTFILE="$HOME/.bash_history"
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL="ignoredups:erasedups"
export HISTIGNORE="ls:bg:fg:history:pwd"
shopt -s histappend 2>/dev/null
[ -f "$HISTFILE" ] && history -r

PROMPT_COMMAND='
  HOME_NAME=$(basename "$HOME")
  VENV=""
  if [ -n "$VIRTUAL_ENV" ]; then
    VENV="\[\e[35m\]("$(basename "$VIRTUAL_ENV")")\[\e[0m\]"
  fi
  history -a; history -n
  PS1="$VENV\[\e[32m\][$HOME_NAME]\[\e[0m\][\u@\h \[\e[36m\]$(date +%Y%m%d_%H:%M)\[\e[0m\] \w]\n\$ "
'
# fzf install
# git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
# run install script
# ~/.fzf/install --key-bindings --completion --no-update-rc

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# 1. Command Conp bash> Ctrl+R → echo 'hello' 
# 2. File Conp bash> vim Ctrl+T → vim /etc/passw

realtime_rg_fzf() {
  local tmpfile=$(mktemp)
  rg --line-number --no-heading --color=never "" > "$tmpfile"
  while :; do
    local selected
    selected=$(fzf --ansi --delimiter : \
        --preview 'bat --style=numbers --color=always {1} --highlight-line {2}' \
        --preview-window='up:60%' \
        --prompt="Q rg > " \
        --header="Move:Up Dn, Select: Enter（Out: Esc）" \
        < "$tmpfile")
    [ -z "$selected" ] && break
    local file line
    file=$(echo "$selected" | cut -d: -f1)
    line=$(echo "$selected" | cut -d: -f2)
    [ -z "$file" ] && continue
    ${EDITOR:-nvim} +"$line" "$file"
  done
  rm -f "$tmpfile"
}
# Bash kye
bind -x '"\C-g": realtime_rg_fzf'

# https://github.com/tmux/tmux/wiki/Getting-Started
# tmux new
