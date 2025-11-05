#!/usr/bin/env bash
# batch-loop-run.sh
set -euo pipefail

# ===== 設定 =====
# 使用モデル
: "${MODEL:=./models/Qwen3.gguf}"
# 実行スクリプト
: "${script:=./exec-llama-simple.sh}"

# 入力ディレクトリ
# <file-path> - </file-path>
# <file-text>(テキスト本文)</file-text>
: "${indir:=./hogehoge-in/}"
# 出力ディレクトリ
: "${outdir:=./hogehoge-out/}"

# システムプロンプト
# <sys-prompt> - </sys-prompt>
: "${SYS_FILE:=./prompt/sys-prompt.txt}"                         
# メインユーザープロンプト
# <main-prompt> - </main-prompt>
: "${USER_PROMPT_FILE:=./prompt/main-user.txt}"

# ===== 準備 =====
[ -f "$USER_PROMPT_FILE" ] || { echo "error: not found: $USER_PROMPT_FILE" >&2; exit 2; }
USER_PROMPT="$(cat "$USER_PROMPT_FILE")"
export LLAMA_CLI MODEL SYS_FILE
mkdir -p "$outdir"

# ===== 実行 =====
find "$indir" -maxdepth 1 -type f -print0 |
while IFS= read -r -d '' f; do
  base=${f##*/}
  relpath="${f#./}"
  out="$outdir/$base"

  echo "--- processing: $f -> $out ---" >&2

  {
    printf '<main-prompt>\n%s\n</main-prompt>\n' "$USER_PROMPT"
    printf '<file-path>\n%s\n</file-path>\n' "$relpath"
    printf '<file-text>\n'
    cat "$f"
    printf '\n</file-text>\n'
  } | bash "$script" >"$out" || echo "error processing $f" >&2
done