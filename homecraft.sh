#!/bin/bash
set -e

usage() {
  cat <<EOF
homecraft - Virtual HOME environment generator and launcher

Usage:
  homecraft <name|path> [template] [-f|--force] [-r|--reuse] [--date] [-d DIR] [-zsh] [-h|--help]

  <name|path>   : "myenv" creates ./myenv, "/foo/bar" creates at absolute path.
  [template]    : Template directory name (if omitted, minimal dotfiles are auto-generated)
  -f, --force   : Overwrite (remove) existing HOME if already present
  -r, --reuse   : Reuse existing HOME as is
  --date        : Append _YYYYMMDD_HHMM to HOME name (or use __DATE__ in name)
  -d DIR        : Set parent directory (default: current directory)
  -zsh          : Start with zsh (requires .zshrc in template or will auto-generate)
  -h, --help    : Show this help

Examples:
  homecraft dev1
  homecraft /mnt/data/dev2
  homecraft testenv pytemplate --date -d /tmp/workenv
  homecraft "test-__DATE__"
  homecraft myzsh zshtemplate -zsh
EOF
  exit 1
}

ACTION=""
VHOME_BASE="."
DATE_SUFFIX=""
POSITIONAL=()
ZSH_MODE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force) ACTION=force; shift ;;
    -r|--reuse) ACTION=reuse; shift ;;
    --date) DATE_SUFFIX="_$(date +%Y%m%d_%H%M)"; shift ;;
    -d) VHOME_BASE="$2"; shift 2 ;;
    -zsh) ZSH_MODE=1; shift ;;
    -h|--help) usage ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [ -z "$1" ]; then usage; fi
BASE_NAME="$1"
VHOME_NAME="${BASE_NAME//__DATE__/$(date +%Y%m%d_%H%M)}${DATE_SUFFIX}"

if [[ "$VHOME_NAME" = /* ]]; then
  VHOME="$VHOME_NAME"
else
  VHOME="$VHOME_BASE/$VHOME_NAME"
fi

TEMPLATE="$2"
if [ -n "$TEMPLATE" ]; then
  if [[ "$TEMPLATE" = /* ]]; then
    TEMPLATE_PATH="$TEMPLATE"
  else
    TEMPLATE_PATH="$(dirname "$VHOME")/../envtemplates/$TEMPLATE"
  fi
fi

if [ -d "$VHOME" ]; then
  case "$ACTION" in
    force) rm -rf "$VHOME" ;;
    reuse) ;;
    *)
      echo -e "\033[33m$VHOME already exists. Use -f (force) or -r (reuse).\033[0m"
      exit 2
      ;;
  esac
fi

if [ -n "$TEMPLATE_PATH" ]; then
  cp -a "$TEMPLATE_PATH" "$VHOME"
else
  mkdir -p "$VHOME"
  ABSVHOME="$(cd "$VHOME" && pwd)"

  # record parent virtual-home
  PARENTHOME="${HOME:-}"
  if [ -n "$PARENTHOME" ] && [ "$PARENTHOME" != "$ABSVHOME" ]; then
    echo "$PARENTHOME" > "$ABSVHOME/.virtualhome"
  fi

  # minimal .bashrc (guarded: force or create-only)
  if [ "$ACTION" = "force" ] || [ ! -f "$ABSVHOME/.bashrc" ]; then
cat > "$ABSVHOME/.bashrc" <<'EOF'
export HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HOME"

get_home_depth() {
  local d="$HOME"
  local depth=1
  while [ -f "$d/.virtualhome" ]; do
    depth=$((depth + 1))
    d="$(cat "$d/.virtualhome")"
  done
  echo $depth
}
PROMPT_COMMAND='
  HOME_DEPTH=$(get_home_depth)
  HOME_NAME=$(basename "$HOME")
  PS1="\[\e[33m\][Depth:\$HOME_DEPTH]\[\e[0m\]\[\e[32m\][\$HOME_NAME]\[\e[0m\][\u@\h \[\e[36m\]`date +%Y%m%d_%H:%M`\[\e[0m\] \W]\n\$ "
'
alias ll='ls -la --color=auto'
export LANG=en_US.UTF-8
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=10000
export HISTCONTROL=ignoredups:erasedups
export HISTIGNORE="ls:bg:fg:history:pwd"
shopt -s histappend
[ -f "$HISTFILE" ] && history -r
trap 'history -a' EXIT
EOF
  fi

  # minimal .vimrc
cat > "$ABSVHOME/.vimrc" <<"EOF"
set number
set tabstop=4
syntax on
EOF

  # minimal .gitconfig
cat > "$ABSVHOME/.gitconfig" <<"EOF"
[user]
    name = Virtual User
    email = example@example.com
[core]
    editor = vim
EOF

  # minimal .inputrc
cat > "$ABSVHOME/.inputrc" <<"EOF"
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
EOF

  # minimal .zshrc (guarded: force or create-only)
  if [ "$ZSH_MODE" = 1 ]; then
    if [ "$ACTION" = "force" ] || [ ! -f "$ABSVHOME/.zshrc" ]; then
cat > "$ABSVHOME/.zshrc" <<'EOF'
export HOME="$(cd "$(dirname "$0")" && pwd)"
cd "$HOME"
get_home_depth() {
  local d="$HOME"
  local depth=1
  while [[ -f "$d/.virtualhome" ]]; do
    depth=$((depth + 1))
    d=$(cat "$d/.virtualhome")
  done
  echo $depth
}
precmd() {
  export HOME_DEPTH=$(get_home_depth)
  export HOME_NAME=$(basename "$HOME")
  PROMPT="%F{yellow}[Depth:$HOME_DEPTH]%f%F{green}[$HOME_NAME]%f[%n@%m %F{cyan}%D{%Y-%m-%d_%H:%M}%f %~]\n%# "
}
alias ll='ls -la --color=auto'
export LANG=en_US.UTF-8
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
[ -f "$HISTFILE" ] && fc -R "$HISTFILE"
autoload -Uz add-zsh-hook
add-zsh-hook zshexit 'fc -A'
EOF
    fi
  fi

fi

# finalize
ABSVHOME="$(cd "$VHOME" && pwd)"

echo -e "\033[32mVirtual HOME: $VHOME is ready.\033[0m"

if [ "$ZSH_MODE" = 1 ]; then
  env HOME="$ABSVHOME" zsh
else
  RCFILE="$ABSVHOME/.bashrc"
  env HOME="$ABSVHOME" bash --noprofile --rcfile "$RCFILE"
fi
