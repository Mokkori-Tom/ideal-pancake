#!/usr/bin/env bash
# exec-llama-chunks.sh
set -euo pipefail

export LANG=${LANG:-C.UTF-8}
export LC_ALL=${LC_ALL:-C.UTF-8}

LLAMA_CLI="${LLAMA_CLI:-./llama.cpp/llama-cli}"
MODEL="${MODEL:-./models/Qwen3-4B-Instruct-2507-IQ4_NL.gguf}"
SYS_FILE="${SYS_FILE:-./system-prompt.txt}"

CTX=${CTX:-8192}
BATCH=${BATCH:-512}
N_PREDICT=${N_PREDICT:--1}
SEED=${SEED:-0}
MAINGPU=${MAINGPU:-0}
NGL=${NGL:-999}

# SYSは一度だけ読む（無ければ空）
SYS_PROMPT=""
if [ -f "$SYS_FILE" ]; then
  # CRLFを除去して読み込み
  SYS_PROMPT="$(tr -d '\r' < "$SYS_FILE")"
fi

# 逐次処理：1行=1ジョブ（空行はスキップ）
# ※行ではなく任意区切りにしたい場合は NUL 区切り版を下に用意しています
while IFS= read -r line; do
  # 空なら次へ
  [ -z "$line" ] && continue

  # CRLF混在対策：行末の\rを落とす
  line="${line%$'\r'}"

  # 一時ファイルへUTF-8のまま書き込み（shell展開の影響なし）
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  printf '%s' "$line" > "$tmp"

  out="$("$LLAMA_CLI" \
    -m "$MODEL" \
    --temp 0.7 \
    -c "$CTX" -b "$BATCH" \
    -n "$N_PREDICT" --seed "$SEED" \
    --split-mode none --simple-io -st \
    -ngl "$NGL" --main-gpu "$MAINGPU" \
    -sys "$SYS_PROMPT" \
    -f "$tmp")"

  # 後段でタグ等を刈り取る
  printf '%s' "$out" | python ./extract-text.py 'assistant' '[end of text]'

  rm -f "$tmp"
  trap - RETURN
done

