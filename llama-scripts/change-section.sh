#!/usr/bin/env bash
# batch-reformat.sh
set -euo pipefail

indir="${1:-./in}"
outdir="${2:-./out}"

mkdir -p "$outdir"

for f in "$indir"/*; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  out="$outdir/$base"

  echo "--- processing: $f -> $out ---"

  awk '
  BEGIN {
    in_user = 0
    in_assistant = 0
    user_text = ""
    assistant_text = ""
  }

  # セクション識別
  /^user$/ {
    in_user = 1
    in_assistant = 0
    next
  }

  /^assistant$/ {
    in_assistant = 1
    in_user = 0
    next
  }

  # 行全体が [end of text]（前後に空白を含んでもOK）の場合は破棄
  /^[[:space:]]*\[end of text\][[:space:]]*$/ {
    in_user = 0
    in_assistant = 0
    next
  }

  # 本文の蓄積
  in_user {
    user_text = (user_text ? user_text ORS : "") $0
    next
  }

  in_assistant {
    assistant_text = (assistant_text ? assistant_text ORS : "") $0
    next
  }

  END {
    # 行中に紛れ込んだ [end of text] も除去
    gsub(/\[end of text\]/, "", user_text)
    gsub(/\[end of text\]/, "", assistant_text)

    # 先頭・末尾の余計な改行をトリム
    gsub(/^[\n\r]+|[\n\r]+$/, "", user_text)
    gsub(/^[\n\r]+|[\n\r]+$/, "", assistant_text)

    print assistant_text
    print "<original>"
    print user_text
    print "</original>"
  }
  ' "$f" > "$out"
done