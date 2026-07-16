#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
SCRIPT="apps/3d-generator/generic_parametric_blender.py"
CONFIG="configs/3d/generic-object.example.json"
TMP_DIR="$(mktemp -d /tmp/moe-3d-blender-adapter.XXXXXX)"
TMP_UNSUPPORTED_CONFIG="$(mktemp configs/3d/moe-invalid-adapter-unsupported.XXXXXX.json)"

cleanup() {
  rm -rf "$TMP_DIR"
  rm -f "$TMP_UNSUPPORTED_CONFIG"
}
trap cleanup EXIT

"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --blender-operation-plan-json >"$TMP_DIR/blender-plan.json"

jq -e '.plan_type == "blender_operation_plan"' "$TMP_DIR/blender-plan.json" >/dev/null
jq -e '.asset_name == "simple_frame_example"' "$TMP_DIR/blender-plan.json" >/dev/null
jq -e '.operation_count >= 1' "$TMP_DIR/blender-plan.json" >/dev/null
jq -e '.safety_flags.bpy_imported == false' "$TMP_DIR/blender-plan.json" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "$TMP_DIR/blender-plan.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/blender-plan.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_DIR/blender-plan.json" >/dev/null
jq -e 'all(.operations[]; .custom_properties.generation_status == "planned_only")' "$TMP_DIR/blender-plan.json" >/dev/null

"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --plan-json >"$TMP_DIR/plan.json"
jq -e '.blender_operation_plan_summary.operation_count >= 1' "$TMP_DIR/plan.json" >/dev/null

cat >"$TMP_UNSUPPORTED_CONFIG" <<'JSON'
{
  "schema_version": "1.0",
  "project_name": "invalid_adapter",
  "asset_name": "invalid_adapter",
  "asset_category": "generic_structure",
  "units": "mm",
  "safety_label": "visual_reference_only",
  "structural_certification": false,
  "coordinate_system": {},
  "dimensions": {
    "width_mm": 100,
    "depth_mm": 100,
    "height_mm": 100
  },
  "components": [
    {
      "component_id": "bad_type",
      "component_type": "unsupported_shape",
      "dimensions": {
        "width_mm": 10,
        "depth_mm": 10,
        "height_mm": 10
      }
    }
  ],
  "output_plan": {
    "runtime_output_root": "/home/cuneyt/MoE/runtime/media/outputs/3d"
  }
}
JSON

if "$PYTHON_BIN" "$SCRIPT" --config "$TMP_UNSUPPORTED_CONFIG" --blender-operation-plan-json >/dev/null 2>&1; then
  echo "unsupported component_type unexpectedly succeeded" >&2
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

echo "3D Blender adapter OK"
