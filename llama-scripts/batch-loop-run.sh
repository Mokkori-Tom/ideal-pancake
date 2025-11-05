#!/usr/bin/env bash
# loop-run.sh
set -euo pipefail

: "${MODEL:=./models/Qwen3-30B-A3B-Instruct-2507-IQ4_NL.gguf}"
: "${script:=./exec-llama-simple.sh}"

# 処理対象のテキスト群
# <file-path>-</file-path>
: "${indir:=./hogehoge-in/}"
: "${outdir:=./hogehoge-out/}"

# バッチプロンプト(システムプロンプト)
: "${SYS_FILE:=./prompt/sys-prompt.txt}"
# バッチプロンプト(ユーザープロンプト)
# <main-prompt>-</main-prompt>
: "${USER_PROMPT_FILE:=./prompt/main-user.txt}"

# === メインプロンプト読込 ===
if [ ! -f "$USER_PROMPT_FILE" ]; then
  echo "error: USER_PROMPT_FILE not found: $USER_PROMPT_FILE" >&2
  exit 2
fi

USER_PROMPT="$(cat "$USER_PROMPT_FILE")"

export LLAMA_CLI MODEL SYS_FILE

mkdir -p "$outdir"

find "$indir" -maxdepth 1 -type f -print0 |
while IFS= read -r -d '' f; do
  base=${f##*/}
  relpath="${f#./}"   # 実行パスからの相対
  out="$outdir/$base"

  echo "--- processing: $f -> $out ---" >&2

  {
    printf '<main-prompt>\n%s\n</main-prompt>\n' "$USER_PROMPT"
    printf '<file-path>\n%s\n</file-path>\n' "$relpath"
    cat "$f"
  } | bash "$script" >"$out" || echo "error processing $f" >&2
done