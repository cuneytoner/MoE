#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
SCRIPT="apps/3d-generator/generic_parametric_blender.py"
CONFIG="configs/3d/generic-object.example.json"
TMP_PLAN="$(mktemp /tmp/moe-3d-dry-run-plan.XXXXXX.json)"
TMP_CONFIG_PLAN="$(mktemp /tmp/moe-3d-dry-run-config-plan.XXXXXX.json)"
TMP_REAL_PLAN="$(mktemp /tmp/moe-3d-dry-run-real-plan.XXXXXX.json)"
TMP_TXT_CONFIG="$(mktemp /tmp/moe-3d-dry-run-review.XXXXXX.txt)"

cleanup() {
  rm -f "$TMP_PLAN" "$TMP_CONFIG_PLAN" "$TMP_REAL_PLAN" "$TMP_TXT_CONFIG"
}
trap cleanup EXIT

"$PYTHON_BIN" "$SCRIPT" --dry-run >/dev/null
"$PYTHON_BIN" "$SCRIPT" --plan-json >"$TMP_PLAN"
"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --dry-run >/dev/null
"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --plan-json >"$TMP_CONFIG_PLAN"

jq -e '.safety_flags.dry_run == true' "$TMP_PLAN" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "$TMP_PLAN" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_PLAN" >/dev/null
jq -e '.safety_flags.source_assets_modified == false' "$TMP_PLAN" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_PLAN" >/dev/null
jq -e '.metadata_plan.asset_type == "3d_model"' "$TMP_PLAN" >/dev/null
jq -e '.metadata_plan.safety_label == "visual_reference_only"' "$TMP_PLAN" >/dev/null
jq -e '.metadata_plan.structural_certification == false' "$TMP_PLAN" >/dev/null
jq -e '.runtime_output_root == "/home/cuneyt/MoE/runtime/media/outputs/3d"' "$TMP_PLAN" >/dev/null

jq -e '.config_loaded == true' "$TMP_CONFIG_PLAN" >/dev/null
jq -e '.config_summary.asset_name == "simple_frame_example"' "$TMP_CONFIG_PLAN" >/dev/null
jq -e '.config_summary.component_count >= 1' "$TMP_CONFIG_PLAN" >/dev/null

REAL_3D_GENERATION=1 "$PYTHON_BIN" "$SCRIPT" --plan-json >"$TMP_REAL_PLAN"
jq -e '.safety_flags.real_generation_requested == true' "$TMP_REAL_PLAN" >/dev/null
jq -e '.safety_flags.real_generation_enabled == true' "$TMP_REAL_PLAN" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_REAL_PLAN" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_REAL_PLAN" >/dev/null

printf '{"schema_version":"1.0"}\n' >"$TMP_TXT_CONFIG"
if "$PYTHON_BIN" "$SCRIPT" --config "$TMP_TXT_CONFIG" --plan-json >/dev/null 2>&1; then
  echo "non-json config unexpectedly succeeded" >&2
  exit 1
fi

generated_files="$(
  find . -type f \( -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print
)"
if [ -n "$generated_files" ]; then
  echo "Unexpected generated 3D files under repo:" >&2
  echo "$generated_files" >&2
  exit 1
fi

echo "3D dry-run review OK"
