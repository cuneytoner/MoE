#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
SCRIPT="apps/3d-generator/generic_parametric_blender.py"
CONFIG="configs/3d/generic-object.example.json"
TMP_DIR="$(mktemp -d /tmp/moe-3d-metadata-sidecar-validator.XXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --write-metadata "$TMP_DIR/sidecar.json" >/dev/null
"$PYTHON_BIN" "$SCRIPT" --validate-metadata "$TMP_DIR/sidecar.json" >"$TMP_DIR/validation-report.json"

jq -e '.report_type == "3d_metadata_sidecar_validation"' "$TMP_DIR/validation-report.json" >/dev/null
jq -e '.valid == true' "$TMP_DIR/validation-report.json" >/dev/null
jq -e '.error_count == 0' "$TMP_DIR/validation-report.json" >/dev/null
jq -e '.safety_flags.read_only == true' "$TMP_DIR/validation-report.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/validation-report.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_DIR/validation-report.json" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "$TMP_DIR/validation-report.json" >/dev/null

cat >"$TMP_DIR/bad-sidecar.json" <<'JSON'
{
  "asset_type": "not_3d_model",
  "safety_label": "unsafe",
  "structural_certification": true,
  "output_files": {
    "glb": "/etc/passwd"
  }
}
JSON

bad_status=0
"$PYTHON_BIN" "$SCRIPT" --validate-metadata "$TMP_DIR/bad-sidecar.json" >"$TMP_DIR/bad-validation-report.json" || bad_status=$?
if [ "$bad_status" -eq 0 ]; then
  echo "invalid metadata unexpectedly validated successfully" >&2
  exit 1
fi
jq -e '.valid == false' "$TMP_DIR/bad-validation-report.json" >/dev/null
jq -e '.error_count > 0' "$TMP_DIR/bad-validation-report.json" >/dev/null
jq -e '.errors | join(" ") | test("asset_type|safety_label|output_files")' "$TMP_DIR/bad-validation-report.json" >/dev/null

if "$PYTHON_BIN" "$SCRIPT" --validate-metadata docs/bad-sidecar.json >/dev/null 2>&1; then
  echo "--validate-metadata unexpectedly accepted a repo path" >&2
  exit 1
fi

if "$PYTHON_BIN" "$SCRIPT" --validate-metadata /home/cuneyt/MoE/runtime/media/outputs/3d/metadata/bad.json >/dev/null 2>&1; then
  echo "--validate-metadata unexpectedly accepted a runtime path" >&2
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

echo "3D metadata sidecar validator OK"
