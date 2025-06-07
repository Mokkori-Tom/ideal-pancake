#!/bin/bash

: <<'MEMO'
--- 仮想HOMEディレクトリ管理スクリプト ---

Usage:
  ./start-myenv.sh 仮想名 [テンプレ名] [仮想HOME親ディレクトリ]

例:
  ./start-myenv.sh dev1
      → $HOME/envhomes/dev1
  ./start-myenv.sh pyproj pydev
      → $HOME/envhomes/pyproj（テンプレpydev）
  ./start-myenv.sh box "" /mnt/data/envhomes
      → パス指定でテンプレ無し
  ./start-myenv.sh "test-$(date +%Y%m%d_%H%M)" pydev
      → 日付入りで新規作成・バージョン管理

- [テンプレ名]省略は "" を入力
- 仮想HOMEが既に存在した場合、上書き/再利用/中止を選択
- テンプレは [親ディレクトリ]/../envtemplates/ 以下に配置
- -h, --help でこのヘルプ表示

【小技・TIPS】
● テンプレを用途別に増やしておけば使い分け簡単
● for文で一括作成  for n in {1..3}; do ./start-myenv.sh test\$n; done
● inputrc, gitconfigなどdotfilesは自動生成エリアでcat > "\$VHOME/ファイル" <<EOF ...で追加
● 一回だけ自動実行例: [ -x "\$HOME/auto-save.sh" ] && bash "\$HOME/auto-save.sh" && rm -f "\$HOME/auto-save.sh"
● クロスプラットフォーム運用可
MEMO

usage() {
  # MEMOラベルの間を抽出し、1行目(MEMO)と最終行(MEMO)を削除
  sed -n '/^: <<'\''MEMO'\''$/,/^MEMO$/p' "$0" | sed '1d;$d'
  exit 0
}

if [ $# -eq 0 ] || [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]]; then
  usage
fi

VHOME_NAME="$1"
TEMPLATE="$2"
VHOME_BASE="${3:-$HOME/envhomes}"
VHOME="$VHOME_BASE/$VHOME_NAME"

if [ -n "$TEMPLATE" ]; then
  TEMPLATE_PATH="$(dirname "$VHOME_BASE")/envtemplates/$TEMPLATE"
  if [ ! -d "$TEMPLATE_PATH" ]; then
    echo "テンプレート $TEMPLATE_PATH が存在しません"
    exit 1
  fi
fi

if [ -d "$VHOME" ]; then
  echo "仮想ディレクトリ $VHOME は既に存在します。どうしますか？"
  select yn in "上書き削除" "そのまま使う" "中止"; do
    case $yn in
      "上書き削除" ) rm -rf "$VHOME"; break;;
      "そのまま使う" ) break;;
      "中止" ) echo "中止します"; exit 1;;
    esac
  done
fi

if [ -n "$TEMPLATE" ]; then
  cp -r "$TEMPLATE_PATH" "$VHOME"
else
  mkdir -p "$VHOME"

  cat > "$VHOME/.bashrc" <<EOF
export PS1="[\u@\h 仮想環境 \W]\$ "
export PATH="\$HOME/bin:\$PATH"
alias ll='ls -la --color=auto'
export LANGUAGE=ja_JP.ja
export LANG=ja_JP.UTF-8

export HOME="\$HOME"
export XDG_DATA_HOME="\$HOME/.local/share"
export XDG_CACHE_HOME="\$HOME/.cache"
export XDG_STATE_HOME="\$HOME/.local/state"
export XDG_CONFIG_HOME="\$HOME/.config"
export XDG_CONFIG_DIRS="\$HOME/etc/xdg"
export APPDATA="\$HOME/.config"

export GOROOT="\$HOME/go/"
export GOCACHE="\$HOME/.cache/go-build"
export GOENV="\$HOME/.config/go/env"

export PATH="\$HOME/python/:\$PATH"
export PATH="\$HOME/python/Scripts:\$PATH"

[ -x "\$HOME/auto-save.sh" ] && bash "\$HOME/auto-save.sh" && rm -f "\$HOME/auto-save.sh"
EOF

  cat > "$VHOME/.vimrc" <<EOF
set number
set tabstop=4
syntax on
EOF

  cat > "$VHOME/.gitconfig" <<EOF
[user]
    name = 仮想ユーザー
    email = example@example.com
[core]
    editor = vim
EOF

  cat > "$VHOME/.inputrc" <<EOF
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
EOF

  cat > "$VHOME/auto-save.sh" <<EOF
mkdir -p ~/.emacs.d/site-lisp
cd ~/.emacs.d/site-lisp
if [ ! -d auto-save ]; then
  git clone https://github.com/manateelazycat/auto-save
fi
EOF

fi

env HOME="$VHOME" bash --noprofile --rcfile "$VHOME/.bashrc"