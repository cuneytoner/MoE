#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
TMP_DIR="$(mktemp -d /tmp/moe-3d-first-generation-drill-plan.XXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

PYTHON_BIN="$PYTHON_BIN" scripts/3d-first-generation-drill-plan.sh >"$TMP_DIR/drill-plan.json"

jq -e '.plan_type == "first_guarded_blender_generation_drill"' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.asset_name == "simple_frame_example"' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.runtime_output_root == "/home/cuneyt/MoE/runtime/media/outputs/3d"' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.preflight.config_valid == true' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.preflight.scene_plan_valid == true' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.preflight.blender_operation_plan_valid == true' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.preflight.metadata_plan_available == true' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.preflight.safe_to_run_manually == false' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.safety_flags.operator_review_required == true' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.planned_outputs.blend | contains("blender/")' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.planned_outputs.glb | contains("glb/")' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.planned_outputs.metadata | contains("metadata/")' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.planned_outputs.report | contains("reports/")' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.required_operator_command | contains("REAL_3D_GENERATION=1")' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.required_operator_command | contains("blender --background")' "$TMP_DIR/drill-plan.json" >/dev/null
jq -e '.required_operator_command | contains("--execute-generation")' "$TMP_DIR/drill-plan.json" >/dev/null

REPORT_PATH="$TMP_DIR/drill-report.json" PYTHON_BIN="$PYTHON_BIN" scripts/3d-first-generation-drill-plan.sh
test -f "$TMP_DIR/drill-report.json"
jq -e '.plan_type == "first_guarded_blender_generation_drill"' "$TMP_DIR/drill-report.json" >/dev/null

if REPORT_PATH="docs/bad-drill-report.json" PYTHON_BIN="$PYTHON_BIN" scripts/3d-first-generation-drill-plan.sh >/dev/null 2>&1; then
  echo "REPORT_PATH unexpectedly accepted a repo path" >&2
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

echo "3D first generation drill plan OK"
