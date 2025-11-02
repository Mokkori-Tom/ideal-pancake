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
  BEGIN {in_user=0; in_assistant=0; user_text=""; assistant_text=""}
  /^user$/        {in_user=1; in_assistant=0; next}
  /^assistant$/   {in_assistant=1; in_user=0; next}
  /^\[end of text\]$/ {in_user=0; in_assistant=0; next}

  in_user       {user_text = (user_text ? user_text ORS : "") $0; next}
  in_assistant  {assistant_text = (assistant_text ? assistant_text ORS : "") $0; next}

  END {
    gsub(/^[\n\r]+|[\n\r]+$/, "", user_text)
    gsub(/^[\n\r]+|[\n\r]+$/, "", assistant_text)
    print "*　*　*"
    print assistant_text
    print "<original>"
    print "*　*　*"
    print user_text
    print "</original>"
  }' "$f" > "$out"
done