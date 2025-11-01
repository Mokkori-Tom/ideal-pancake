#!/usr/bin/env bash
set -euo pipefail

# === 設定（環境変数で上書き可）===
script="${script:-./exec-llama.sh}"   # 実行スクリプト（shebang実行）
indir="${indir:-./loopdir}"           # 入力ディレクトリ
outdir="${outdir:-./loop-outdir}"     # 出力ディレクトリ
resume="${resume:-1}"                 # 1=入力より新しい出力はスキップ

# === 準備 ===
mkdir -p -- "$outdir"

# 絶対パス
indir_abs="$(cd "$indir" && pwd)"
outdir_abs="$(cd "$outdir" && pwd)"

# 入力配下に出力があるなら prune 用の相対パス
prune_rel=""
case "$outdir_abs" in
  "$indir_abs"/*) prune_rel="${outdir_abs#"$indir_abs/"}" ;;
esac

# サブシェルに渡す環境
export OUTDIR="$outdir_abs" RESUME="$resume" SCRIPT="$script"

cd "$indir_abs"

# -printf/-read -d を使わず、-exec で1ファイルずつ安全処理
find . \
  ${prune_rel:+\( -path "./$prune_rel" -o -path "./$prune_rel/*" \) -prune -o} \
  -type f -exec sh -c '
    rel="${1#./}"
    in="$PWD/$rel"
    out="$OUTDIR/$rel"
    mkdir -p -- "$(dirname -- "$out")"

    # 更新判定（-newer を利用）
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