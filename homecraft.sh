#!/bin/bash
set -e

# Homecraft: Create, manage, and launch sandboxed virtual HOME directories for Bash/zsh.
# Inspired by UNIX spirit and power-user workflow.

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

Tips:
- You can store reusable templates under ../envtemplates/
- Use for n in {1..3}; do homecraft test\$n; done for batch creation
- Bash/zsh history is inherited for seamless workflow
- Edit this script to add more default dotfiles or custom setup as you wish!
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
  [[ "$TEMPLATE" = /* ]] && TEMPLATE_PATH="$TEMPLATE" || TEMPLATE_PATH="$(dirname "$VHOME")/../envtemplates/$TEMPLATE"
fi

if [ -d "$VHOME" ]; then
  case "$ACTION" in
    force)
      rm -rf "$VHOME"
      ;;
    reuse)
      ;;
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

  # Inherit shell history (bash/zsh) for seamless workflow
  [ -f "$HOME/.bash_history" ] && cp "$HOME/.bash_history" "$ABSVHOME/.bash_history"

  # Minimal .bashrc
  cat > "$ABSVHOME/.bashrc" <<EOF
echo -e "\033[36m==== Virtual HOME: \$HOME (bash) ====\033[0m"
export HOME="$ABSVHOME"
cd "\$HOME"
PROMPT_COMMAND='PS1="[\u@\h \$(date "+%Y-%m-%d_%H:%M") \w]\\$ "'
alias ll='ls -la --color=auto'
export LANG=en_US.UTF-8
export HISTFILE="\$HOME/.bash_history"
EOF

  # Minimal .vimrc
  cat > "$ABSVHOME/.vimrc" <<"EOF"
set number
set tabstop=4
syntax on
EOF

  # Minimal .gitconfig
  cat > "$ABSVHOME/.gitconfig" <<"EOF"
[user]
    name = Virtual User
    email = example@example.com
[core]
    editor = vim
EOF

  # Minimal .inputrc
  cat > "$ABSVHOME/.inputrc" <<"EOF"
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
EOF

  # .zshrc auto-gen (if -zsh and no template)
  if [ "$ZSH_MODE" = 1 ]; then
    [ -f "$HOME/.zsh_history" ] && cp "$HOME/.zsh_history" "$ABSVHOME/.zsh_history"
    cat > "$ABSVHOME/.zshrc" <<EOF
echo -e "\033[36m==== Virtual HOME: \$HOME (zsh) ====\033[0m"
export HOME="$ABSVHOME"
cd "\$HOME"
PROMPT='%n@%m %~ %# '
alias ll='ls -la --color=auto'
export LANG=en_US.UTF-8
export HISTFILE="\$HOME/.zsh_history"
EOF
  fi

fi

ABSVHOME="$(cd "$VHOME" && pwd)"

echo -e "\033[32mVirtual HOME: $VHOME is ready.\033[0m"

if [ "$ZSH_MODE" = 1 ]; then
  env HOME="$ABSVHOME" zsh --rcs
else
  RCFILE="$ABSVHOME/.bashrc"
  env HOME="$ABSVHOME" bash --noprofile --rcfile "$RCFILE"
fi
