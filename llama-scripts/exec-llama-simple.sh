#!/usr/bin/env bash
#exec-llama-simple.sh
set -euo pipefail

export LANG=${LANG:-C.UTF-8}
export LC_ALL=${LC_ALL:-C.UTF-8}

LLAMA_CLI="${LLAMA_CLI:-./llama.cpp/llama-cli}"
MODEL="${MODEL:-./models/Qwen3-4B-Instruct-2507-IQ4_NL.gguf}"
SYS_FILE="${SYS_FILE:-./system-prompt.txt}"

CTX=${CTX:-8192} #32768
BATCH=${BATCH:-512}
N_PREDICT=${N_PREDICT:--1}
SEED=${SEED:--1}
MAINGPU=${MAINGPU:-0}
NGL=${NGL:-999}
SPLIT_MODE=${SPLIT_MODE:-none}
TIMEOUT_SEC="${TIMEOUT_SEC:-}"
PROMPT_CACHE="${PROMPT_CACHE:-}"

# 入力サイズ上限（バイト）
# 例: 1MiB = 1048576, 10MiB = 10485760
MAX_INPUT_BYTES="${MAX_INPUT_BYTES:-1048576}"

# バイナリチェックをスキップしたい場合は 1 にする
SKIP_BINARY_CHECK="${SKIP_BINARY_CHECK:-0}"

# --- validation ---
command -v "$LLAMA_CLI" >/dev/null 2>&1 || { echo "llama-cli not found" >&2; exit 127; }
[ -f "$MODEL" ] || { echo "model not found: $MODEL" >&2; exit 2; }

# --- sys prompt args ---
SYS_ARGS=()
[ -f "$SYS_FILE" ] && SYS_ARGS+=( -sysf "$SYS_FILE" )

LL_ARGS=(
  -m "$MODEL"
  --no-warmup
  --simple-io
  -st
  -c "$CTX" -b "$BATCH"
  -n "$N_PREDICT" --seed "$SEED"
  -ngl "$NGL" --main-gpu "$MAINGPU"
  -sm "$SPLIT_MODE"
  "${SYS_ARGS[@]}"
)
[ -n "$PROMPT_CACHE" ] && LL_ARGS+=( --prompt-cache "$PROMPT_CACHE" )

# --- read stdin safely (all bytes, keep newlines exactly) ---
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
cat >"$TMP"

# empty check
if [ ! -s "$TMP" ]; then
  echo "warning: empty stdin" >&2
  exit 0
fi

# --- size check ---
if [ -n "${MAX_INPUT_BYTES}" ] && [ "$MAX_INPUT_BYTES" -gt 0 ]; then
  input_size="$(wc -c <"$TMP")"
  if [ "$input_size" -gt "$MAX_INPUT_BYTES" ]; then
    echo "error: input too large: ${input_size} bytes (limit: ${MAX_INPUT_BYTES})" >&2
    exit 3
  fi
fi

# --- binary-ish check (very簡易) ---
if [ "$SKIP_BINARY_CHECK" != "1" ]; then
  # NULバイトが含まれていたらバイナリとみなす
  if LC_ALL=C grep -q $'\x00' "$TMP"; then
    echo "error: binary input detected (NUL byte found)" >&2
    exit 3
  fi
fi

# --- run ---
if [ -n "$TIMEOUT_SEC" ]; then
  timeout --preserve-status --kill-after=2s "${TIMEOUT_SEC}s" \
    "$LLAMA_CLI" "${LL_ARGS[@]}" -f "$TMP"
else
  "$LLAMA_CLI" "${LL_ARGS[@]}" -f "$TMP"
fi