#!/usr/bin/env bash
set -euo pipefail

dir="${1:-.}"  # 第1引数に対象ディレクトリ（デフォルトはカレント）
cd "$dir"

for f in *.*; do
  [ -f "$f" ] || continue
  base="${f%.*}"
  mv -v -- "$f" "${base}.md"
done