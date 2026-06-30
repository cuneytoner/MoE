#!/usr/bin/env bash
set -euo pipefail

MEDIA_RUNTIME_ROOT="${MEDIA_RUNTIME_ROOT:-/home/cuneyt/MoE/runtime}"
MEDIA_ROOT="${MEDIA_ROOT:-${MEDIA_RUNTIME_ROOT}/media}"
MEDIA_REPORTS_DIR="${MEDIA_REPORTS_DIR:-${MEDIA_RUNTIME_ROOT}/reports/media}"

required_dirs=(
  "${MEDIA_ROOT}"
  "${MEDIA_ROOT}/jobs"
  "${MEDIA_ROOT}/outputs/images"
  "${MEDIA_ROOT}/outputs/videos"
  "${MEDIA_ROOT}/outputs/3d"
  "${MEDIA_ROOT}/outputs/rigs"
  "${MEDIA_ROOT}/outputs/animations"
  "${MEDIA_REPORTS_DIR}"
)

echo "Preparing Media Lab runtime directories outside the codebase"
for dir in "${required_dirs[@]}"; do
  case "$dir" in
    /home/cuneyt/MoE/runtime/*) ;;
    *)
      echo "FAIL: refusing to create media runtime directory outside /home/cuneyt/MoE/runtime: $dir" >&2
      exit 1
      ;;
  esac
  mkdir -p "$dir"
  echo "OK: $dir"
done

echo "Media runtime layout OK"
