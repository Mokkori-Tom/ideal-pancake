#!/usr/bin/env bash
# remove_end_tag.sh
set -euo pipefail

dir="./target"  # 処理したいディレクトリを指定

find "$dir" -type f | while IFS= read -r f; do
  # ファイル内の [end of text] を削除
  sed -i 's/\[end of text\]//g' "$f"
done