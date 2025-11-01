#!/usr/bin/env bash
set -euo pipefail

# === 設定（環境変数で上書き可）===
script="${script:-./exec-llama.sh}"   # 実行スクリプト
indir="${indir:-./loopdir}"           # 入力ディレクトリ
outdir="${outdir:-./loop-outdir}"     # 出力ディレクトリ
resume="${resume:-1}"                 # 1=入力より新しい出力はスキップ

# === 準備 ===
# 絶対パス化
script_abs="$(cd "$(dirname "$script")" && pwd)/$(basename "$script")"
indir_abs="$(cd "$indir" && pwd)"
outdir_abs="$(cd "$outdir" && pwd)"
mkdir -p -- "$outdir_abs"

# 入力配下に出力があるなら prune 用の相対パス
prune_rel=""
case "$outdir_abs" in
  "$indir_abs"/*) prune_rel="${outdir_abs#"$indir_abs/"}" ;;
esac

# 環境をエクスポート
export OUTDIR="$outdir_abs" RESUME="$resume" SCRIPT="$script_abs"

cd "$indir_abs"

# -exec で逐次処理
find . \
  ${prune_rel:+\( -path "./$prune_rel" -o -path "./$prune_rel/*" \) -prune -o} \
  -type f -exec sh -c '
    rel="${1#./}"
    in="$PWD/$rel"
    out="$OUTDIR/$rel"
    mkdir -p -- "$(dirname -- "$out")"

    if [ "$RESUME" = "1" ] && [ -e "$out" ] && \
       find "$out" -newer "$in" -quit >/dev/null 2>&1; then
      printf "%s\n" "[skip] $rel (up-to-date)" >&2
      exit 0
    fi

    printf "%s\n" "--- processing: $in -> $out ---" >&2
    if ! "$SCRIPT" <"$in" >"$out"; then
      printf "%s\n" "error processing $in" >&2
    fi
  ' sh {} \;