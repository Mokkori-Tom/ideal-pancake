#!/usr/bin/env bash
set -euo pipefail

has() { command -v "$1" >/dev/null 2>&1; }

# ---- OS / Kernel ----
OS_NAME="unknown"
OS_VERSION="unknown"
if [ -f /etc/os-release ]; then
  OS_NAME=$(grep -E '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
  OS_VERSION=$(grep -E '^VERSION=' /etc/os-release | cut -d= -f2 | tr -d '"')
fi
KERNEL=$(uname -r)
ARCH=$(uname -m)
HOST=$(uname -n)

# ---- Android / Termux hint ----
ANDROID_MODEL=""
if has getprop; then
  ANDROID_MODEL=$(getprop ro.product.model 2>/dev/null || true)
fi

# ---- CPU ----
CPU_MODEL="unknown"
CPU_CORES=$(nproc 2>/dev/null || echo "unknown")
if has lscpu; then
  CPU_MODEL=$(lscpu | awk -F: '/Model name|型番|モデル名/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')
else
  CPU_MODEL=$(awk -F: '/model name/ {gsub(/^[ \t]+/,"",$2); print $2; exit}' /proc/cpuinfo 2>/dev/null || echo "unknown")
fi

# ---- Memory ----
MEM_TOTAL="unknown"
if has free; then
  MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
else
  MEM_TOTAL=$(awk '/MemTotal/ {printf "%.1fGiB\n",$2/1024/1024}' /proc/meminfo 2>/dev/null || echo "unknown")
fi

# ---- GPU / Accelerators ----
GPU_LIST=()
CUDA_PRESENT=false
VULKAN_LIST=()
OPENCL_LIST=()

if has nvidia-smi; then
  CUDA_PRESENT=true
  while IFS= read -r line; do
    GPU_LIST+=("$line")
  done < <(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null)
fi

# Vulkan devices
if has vulkaninfo; then
  while IFS= read -r d; do
    VULKAN_LIST+=("$d")
  done < <(vulkaninfo 2>/dev/null | awk -F: '/deviceName/ {gsub(/^[ \t]+/,"",$2); print $2}' | sed 's/^[ \t"]*//; s/[" ]*$//' | sort -u)
fi

# OpenCL devices
if has clinfo; then
  while IFS= read -r d; do
    OPENCL_LIST+=("$d")
  done < <(clinfo 2>/dev/null | awk -F: '/Device Name/ {gsub(/^[ \t]+/,"",$2); print $2}' | sed 's/^[ \t]*//; s/[ \t]*$//' | sort -u)
fi

# lspci fallback
if [ "${#GPU_LIST[@]}" -eq 0 ] && [ "${#VULKAN_LIST[@]}" -eq 0 ] && [ "${#OPENCL_LIST[@]}" -eq 0 ]; then
  if has lspci; then
    while IFS= read -r d; do GPU_LIST+=("$d"); done < <(lspci | grep -iE 'vga|3d|display' || true)
  fi
fi

# ---- Toolchain versions (best-effort) ----
vers() { has "$1" && { "$1" --version 2>&1 | head -n1; } || echo "not found"; }
GCC_VER=$(vers gcc)
CLANG_VER=$(vers clang)
CMAKE_VER=$(has cmake && cmake --version 2>&1 | head -n1 || echo "not found")
PY_VER=$(has python3 && python3 -V 2>&1 || echo "not found")
NODE_VER=$(vers node)
NPM_VER=$(vers npm)
JAVA_VER=$(has java && java -version 2>&1 | head -n1 || echo "not found")
MAKE_VER=$(vers make)
GIT_VER=$(vers git)

# ---- Storage ----
ROOT_USAGE=$(df -h / | awk 'NR==2 {print $3 "/" $2 " used(" $5 ")"}')
if has lsblk; then
  LSBLK_SUMMARY=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT -J 2>/dev/null || true)  # JSON
else
  LSBLK_SUMMARY=""
fi

# ---- JSON helpers (python3 required) ----
join_json_array() {
  python3 - << 'PY'
import sys, json
arr = [l.rstrip("\n") for l in sys.stdin if l.strip()]
print(json.dumps(arr))
PY
}

GPU_JSON=$(printf "%s\n" "${GPU_LIST[@]:-}" | join_json_array)
VULKAN_JSON=$(printf "%s\n" "${VULKAN_LIST[@]:-}" | join_json_array)
OPENCL_JSON=$(printf "%s\n" "${OPENCL_LIST[@]:-}" | join_json_array)

NOW=$(date -Is || true)

JSON_OUT=$(cat <<EOF
{
  "collected_at": "$NOW",
  "host": "$HOST",
  "os": {
    "name": "$OS_NAME",
    "version": "$OS_VERSION",
    "kernel": "$KERNEL",
    "arch": "$ARCH",
    "android_model": "$ANDROID_MODEL"
  },
  "cpu": {
    "model": "$CPU_MODEL",
    "cores": "$CPU_CORES"
  },
  "memory": {
    "total": "$MEM_TOTAL"
  },
  "accelerators": {
    "cuda_present": $([ "$CUDA_PRESENT" = true ] && echo true || echo false),
    "gpus": $GPU_JSON,
    "vulkan_devices": $VULKAN_JSON,
    "opencl_devices": $OPENCL_JSON
  },
  "toolchain": {
    "gcc": "$GCC_VER",
    "clang": "$CLANG_VER",
    "cmake": "$CMAKE_VER",
    "python3": "$PY_VER",
    "node": "$NODE_VER",
    "npm": "$NPM_VER",
    "java": "$JAVA_VER",
    "make": "$MAKE_VER",
    "git": "$GIT_VER"
  },
  "storage": {
    "root_usage": "$ROOT_USAGE",
    "lsblk": $( [ -n "$LSBLK_SUMMARY" ] && echo "$LSBLK_SUMMARY" || echo "null" )
  }
}
EOF
)

echo "$JSON_OUT" | tee system_info.json

echo
echo "----- Human-readable summary -----"
echo "Host: $HOST"
echo "OS  : $OS_NAME $OS_VERSION | Kernel $KERNEL | Arch $ARCH"
[ -n "$ANDROID_MODEL" ] && echo "Android model: $ANDROID_MODEL"
echo "CPU : $CPU_MODEL ($CPU_CORES cores)"
echo "RAM : $MEM_TOTAL"
echo "GPU :"
printf "  - %s\n" "${GPU_LIST[@]:-none}"
[ "${#VULKAN_LIST[@]}" -gt 0 ] && { echo "Vulkan devices:"; printf "  - %s\n" "${VULKAN_LIST[@]}"; }
[ "${#OPENCL_LIST[@]}" -gt 0 ] && { echo "OpenCL devices:"; printf "  - %s\n" "${OPENCL_LIST[@]}"; }
echo "CUDA present : $CUDA_PRESENT"
echo "Root usage   : $ROOT_USAGE"
echo "Toolchain    :"
printf "  - %s\n" "$GCC_VER" "$CLANG_VER" "$CMAKE_VER" "$PY_VER" "$NODE_VER" "$NPM_VER" "$JAVA_VER" "$MAKE_VER" "$GIT_VER"