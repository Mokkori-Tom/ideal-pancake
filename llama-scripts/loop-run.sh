#!/usr/bin/env bash
set -euo pipefail

# === 設定 ===
script="${script:-./exec-llama.sh}"  # 実行スクリプト
indir="${indir:-./loopdir}"          # 入力ディレクトリ
outdir="${outdir:-./loop-outdir}"    # 出力ディレクトリ

# === 準備 ===
mkdir -p "$outdir"

# === 実行 ===
find "$indir" -type f | while IFS= read -r f; do
  # indir/ 以降の相対パスを抽出
  rel="${f#$indir/}"

  # 出力先パス（拡張子を維持）
  out="$outdir/$rel"

  # 出力先ディレクトリを作成
  mkdir -p "$(dirname "$out")"

  echo "--- processing: $f -> $out ---" >&2

  # 実行（逐次処理）
  if ! cat "$f" | bash "$script" > "$out"; then
    echo "error processing $f" >&2
  fi
done