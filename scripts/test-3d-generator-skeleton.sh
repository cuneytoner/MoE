#!/usr/bin/env bash
set -euo pipefail

SCRIPT="apps/3d-generator/generic_parametric_blender.py"
TMP_PLAN="$(mktemp /tmp/moe-3d-generator-plan.XXXXXX.json)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

cleanup() {
  rm -f "$TMP_PLAN"
}
trap cleanup EXIT

"$PYTHON_BIN" "$SCRIPT" --help >/dev/null
"$PYTHON_BIN" "$SCRIPT" --dry-run >/dev/null
"$PYTHON_BIN" "$SCRIPT" --plan-json >"$TMP_PLAN"
"$PYTHON_BIN" "$SCRIPT" --config configs/3d/generic-object.example.json --plan-json >/dev/null

jq -e '.safety_flags.blender_execution_attempted == false' "$TMP_PLAN" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_PLAN" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_PLAN" >/dev/null
jq -e '.metadata_plan.safety_label == "visual_reference_only"' "$TMP_PLAN" >/dev/null
jq -e '.metadata_plan.structural_certification == false' "$TMP_PLAN" >/dev/null
jq -e '.runtime_output_root == "/home/cuneyt/MoE/runtime/media/outputs/3d"' "$TMP_PLAN" >/dev/null

generated_files="$(
  find . -type f \( -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print
)"
if [ -n "$generated_files" ]; then
  echo "Unexpected generated 3D files under repo:" >&2
  echo "$generated_files" >&2
  exit 1
fi

echo "3D generator skeleton OK"
