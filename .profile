# $HOME/.profile

# path setting
export PATH="$PATH:$OPT/gix" # https://github.com/GitoxideLabs/gitoxide/releases

# prompt setting
export HOME_NAME=$(basename "$HOME")
export PS1="\033[32m[$HOME_NAME]\033[0m[\w]\n\$ "

# alias setting
alias ll='ls -la'
alias git='gix'
