#!/usr/bin/env bash
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

# --- validation ---
command -v "$LLAMA_CLI" >/dev/null 2>&1 || { echo "llama-cli not found" >&2; exit 127; }
[ -f "$MODEL" ] || { echo "model not found: $MODEL" >&2; exit 2; }

# --- sys prompt args ---
SYS_ARGS=()
[ -f "$SYS_FILE" ] && SYS_ARGS+=( -sysf "$SYS_FILE" )

LL_ARGS=(
  -m "$MODEL"
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
#   use cat > "$tmp" to avoid shell word splitting
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
cat >"$TMP"

# empty check
if [ ! -s "$TMP" ]; then
  echo "warning: empty stdin" >&2
  exit 0
fi

# --- run ---
if [ -n "$TIMEOUT_SEC" ]; then
  timeout --preserve-status --kill-after=2s "${TIMEOUT_SEC}s" \
    "$LLAMA_CLI" "${LL_ARGS[@]}" -f "$TMP"
else
  "$LLAMA_CLI" "${LL_ARGS[@]}" -f "$TMP"
fi