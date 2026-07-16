#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
SCRIPT="apps/3d-generator/generic_parametric_blender.py"
CONFIG="configs/3d/generic-object.example.json"
TMP_DIR="$(mktemp -d /tmp/moe-3d-metadata-sidecar-writer.XXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --metadata-plan-json >"$TMP_DIR/metadata-plan.json"

jq -e '.asset_type == "3d_model"' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.source == "blender_parametric"' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.asset_name == "simple_frame_example"' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.asset_category == "generic_structure"' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.config_hash | length == 64' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.safety_label == "visual_reference_only"' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.structural_certification == false' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_DIR/metadata-plan.json" >/dev/null
jq -e '.safety_flags.metadata_written == false' "$TMP_DIR/metadata-plan.json" >/dev/null

"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --write-metadata "$TMP_DIR/sidecar.json" >/dev/null

test -f "$TMP_DIR/sidecar.json"
jq -e '.asset_type == "3d_model"' "$TMP_DIR/sidecar.json" >/dev/null
jq -e '.config_hash | length == 64' "$TMP_DIR/sidecar.json" >/dev/null
jq -e '.safety_flags.metadata_written == true' "$TMP_DIR/sidecar.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/sidecar.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_DIR/sidecar.json" >/dev/null

if "$PYTHON_BIN" "$SCRIPT" --write-metadata "$TMP_DIR/no-config.json" >/dev/null 2>&1; then
  echo "--write-metadata unexpectedly succeeded without --config" >&2
  exit 1
fi

if "$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --write-metadata docs/bad-sidecar.json >/dev/null 2>&1; then
  echo "--write-metadata unexpectedly accepted a repo-relative path" >&2
  exit 1
fi

if "$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --write-metadata /home/cuneyt/MoE/runtime/media/outputs/3d/metadata/bad.json >/dev/null 2>&1; then
  echo "--write-metadata unexpectedly accepted a runtime path" >&2
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

echo "3D metadata sidecar writer OK"
