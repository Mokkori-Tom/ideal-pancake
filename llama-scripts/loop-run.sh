#!/usr/bin/env bash
set -euo pipefail

# === 設定 ===
script="${script:-./exec-llama.sh}"  # 実行スクリプト
indir="${indir:-./loopdir}"          # 入力ディレクトリ
outdir="${outdir:-./loop-outdir}"    # 出力ディレクトリ

# === 準備 ===
mkdir -p "$outdir"

# === 実行 ===
find "$indir" -maxdepth 1 -type f | while IFS= read -r f; do
  # ファイル名のみ
  base=$(basename "$f")

  # 出力パス（拡張子を維持）
  out="$outdir/$base"

  echo "--- processing: $f -> $out ---" >&2

  # 実行（逐次処理）
  if ! cat "$f" | bash "$script" > "$out"; then
    echo "error processing $f" >&2
  fi
done