#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
CONFIG="${CONFIG:-configs/3d/generic-object.example.json}"
REPORT_PATH="${REPORT_PATH:-}"
SCRIPT="apps/3d-generator/generic_parametric_blender.py"

if [ -n "$REPORT_PATH" ]; then
  case "$REPORT_PATH" in
    /tmp/*.json)
      "$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --generation-drill-plan-json >"$REPORT_PATH"
      ;;
    *)
      echo "REPORT_PATH must be an absolute /tmp JSON path" >&2
      exit 2
      ;;
  esac
else
  "$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --generation-drill-plan-json
fi
