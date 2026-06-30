#!/usr/bin/env bash
set -euo pipefail

echo "ComfyUI VRAM status"

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "WARN: nvidia-smi not found."
  exit 0
fi

nvidia-smi
echo ""

free_mib="$(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits 2>/dev/null | head -n 1 | tr -d ' ')"
if [ -n "$free_mib" ]; then
  echo "Detected free VRAM: ${free_mib} MiB"
  if [ "$free_mib" -lt 6000 ]; then
    echo "WARN: free VRAM may be low for Flux. Consider manually stopping llama-server before image mode."
  fi
fi

if pgrep -af "llama-server" >/dev/null 2>&1; then
  echo "WARN: llama-server process appears to be running:"
  pgrep -af "llama-server" || true
else
  echo "PASS: no llama-server process detected by pgrep."
fi

echo "INFO: This script does not kill or stop anything."
