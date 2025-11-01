#!/usr/bin/env bash
set -euo pipefail

# === 設定（環境変数で上書き可）===
script="${script:-./exec-llama.sh}"   # 実行スクリプト（実行権限あり推奨）
indir="${indir:-./loopdir}"           # 入力ディレクトリ
outdir="${outdir:-./loop-outdir}"     # 出力ディレクトリ
resume="${resume:-1}"                 # 1=入力より新しい出力はスキップ

# === 準備 ===
mkdir -p -- "$outdir"

# 絶対パス化（BSD/GNUどちらでも動くように）
indir_abs="$(cd "$indir" && pwd)"
outdir_abs="$(cd "$outdir" && pwd)"

# outdir が indir 配下なら、相対パスを求めて後で prune
prune_rel=""
case "$outdir_abs" in
  "$indir_abs"/*) prune_rel="${outdir_abs#"$indir_abs/"}" ;;
esac

# === 実行 ===
# BSD互換：-printf を使わず、cd してから -print0 で列挙
cd "$indir_abs"

find . \
  ${prune_rel:+\( -path "./$prune_rel" -o -path "./$prune_rel/*" \) -prune -o} \
  -type f -print0 |
while IFS= read -r -d '' rel; do
  rel="${rel#./}"                              # "./" を除去
  in="$indir_abs/$rel"
  out="$outdir_abs/$rel"
  mkdir -p -- "$(dirname -- "$out")"

  if [[ "$resume" == "1" && -e "$out" && "$out" -nt "$in" ]]; then
    printf '[skip] %s (up-to-date)\n' "$rel" >&2
    continue
  fi

  printf '--- processing: %s -> %s ---\n' "$in" "$out" >&2
  # ここを shebang 実行に変更（27行目の“無効なオプション”回避）
  if ! "$script" <"$in" >"$out"; then
    printf 'error processing %s\n' "$in" >&2
  fi
done