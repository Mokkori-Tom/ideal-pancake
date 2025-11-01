#!/usr/bin/env bash
set -euo pipefail

# === 設定（環境変数で上書き可）===
script="${script:-./exec-llama.sh}"   # 実行スクリプト（shebangで実行）
indir="${indir:-./loopdir}"           # 入力ディレクトリ
outdir="${outdir:-./loop-outdir}"     # 出力ディレクトリ
resume="${resume:-1}"                 # 1=入力より新しい出力はスキップ

# === 準備 ===
mkdir -p -- "$outdir"

# 絶対パス化
indir_abs="$(cd "$indir" && pwd)"
outdir_abs="$(cd "$outdir" && pwd)"

# outdir が indir 配下なら prune 用の相対パス
prune_rel=""
case "$outdir_abs" in
  "$indir_abs"/*) prune_rel="${outdir_abs#"$indir_abs/"}" ;;
esac

# 文字列を確実に stderr に出す（printf 実装差回避）
say() { printf '%s\n' "$*" >&2; }

# 入力より出力が新しいか（find -newer を使って移植性確保）
is_up_to_date() {
  in="$1"; out="$2"
  [ -e "$out" ] && find "$out" -newer "$in" -print -quit >/dev/null 2>&1
}

# === 実行 ===
cd "$indir_abs"

# BSD/GNU 互換: -print0 を使い、-printf 非使用
find . \
  ${prune_rel:+\( -path "./$prune_rel" -o -path "./$prune_rel/*" \) -prune -o} \
  -type f -print0 |
while IFS= read -r -d '' rel; do
  rel="${rel#./}"
  in="$indir_abs/$rel"
  out="$outdir_abs/$rel"
  mkdir -p -- "$(dirname -- "$out")"

  if [ "$resume" = "1" ] && is_up_to_date "$in" "$out"; then
    say "[skip] $rel (up-to-date)"
    continue
  fi

  say "--- processing: $in -> $out ---"
  if ! "$script" <"$in" >"$out"; then
    say "error processing $in"
  fi
done