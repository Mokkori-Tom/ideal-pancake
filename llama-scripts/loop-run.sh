#!/usr/bin/env bash
set -euo pipefail

# === 設定（環境変数で上書き可）===
script="${script:-./exec-llama.sh}"   # 実行スクリプト
indir="${indir:-./loopdir}"           # 入力ディレクトリ（相対OK）
outdir="${outdir:-./loop-outdir}"     # 出力ディレクトリ
resume="${resume:-1}"                 # 1=入力より新しい出力はスキップ

# === 準備 ===
mkdir -p -- "$outdir"

# === 実行 ===
# - indir配下の outdir は除外（再帰防止）
# - %P で indir からの相対パスを得る
while IFS= read -r -d '' rel; do
  in="$indir/$rel"
  out="$outdir/$rel"
  mkdir -p -- "$(dirname -- "$out")"

  # 既存が新しければスキップ
  if [[ "$resume" == "1" && -e "$out" && "$out" -nt "$in" ]]; then
    printf '[skip] %s (up-to-date)\n' "$rel" >&2
    continue
  fi

  printf '--- processing: %s -> %s ---\n' "$in" "$out" >&2
  if ! bash "$script" <"$in" >"$out"; then
    printf 'error processing %s\n' "$in" >&2
  fi
done < <(
  find "$indir" \
    \( -path "$outdir" -o -path "$outdir/*" \) -prune -o \
    -type f -printf '%P\0'
)