#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
SCRIPT="apps/3d-generator/generic_parametric_blender.py"
CONFIG="configs/3d/generic-object.example.json"
TMP_DIR="$(mktemp -d /tmp/moe-3d-artifact-verifier.XXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --write-metadata "$TMP_DIR/sidecar.json" >/dev/null
"$PYTHON_BIN" "$SCRIPT" --verify-artifacts "$TMP_DIR/sidecar.json" >"$TMP_DIR/verification.json"

jq -e '.report_type == "3d_artifact_verification"' "$TMP_DIR/verification.json" >/dev/null
jq -e '.valid == true' "$TMP_DIR/verification.json" >/dev/null
jq -e '.safety_flags.read_only == true' "$TMP_DIR/verification.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/verification.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_DIR/verification.json" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "$TMP_DIR/verification.json" >/dev/null

jq '.output_files = {
  "blend": "blender/simple_frame_example-test.blend",
  "glb": "glb/simple_frame_example-test.glb",
  "metadata": "metadata/simple_frame_example-test.json",
  "report": "reports/simple_frame_example-test.json"
}' "$TMP_DIR/sidecar.json" >"$TMP_DIR/sidecar-with-outputs.json"

"$PYTHON_BIN" "$SCRIPT" --verify-artifacts "$TMP_DIR/sidecar-with-outputs.json" >"$TMP_DIR/outputs-verification.json"
jq -e '.valid == true' "$TMP_DIR/outputs-verification.json" >/dev/null
jq -e '.artifact_count == 4' "$TMP_DIR/outputs-verification.json" >/dev/null

missing_status=0
"$PYTHON_BIN" "$SCRIPT" --verify-artifacts "$TMP_DIR/sidecar-with-outputs.json" \
  --require-existing-artifacts >"$TMP_DIR/missing-verification.json" || missing_status=$?
if [ "$missing_status" -eq 0 ]; then
  echo "missing artifacts unexpectedly verified successfully" >&2
  exit 1
fi
jq -e '.valid == false' "$TMP_DIR/missing-verification.json" >/dev/null
jq -e '.error_count > 0' "$TMP_DIR/missing-verification.json" >/dev/null

jq '.output_files.glb = "/etc/passwd"' "$TMP_DIR/sidecar-with-outputs.json" >"$TMP_DIR/bad-absolute.json"
bad_absolute_status=0
"$PYTHON_BIN" "$SCRIPT" --verify-artifacts "$TMP_DIR/bad-absolute.json" \
  >"$TMP_DIR/bad-absolute-report.json" || bad_absolute_status=$?
if [ "$bad_absolute_status" -eq 0 ]; then
  echo "absolute artifact path unexpectedly verified successfully" >&2
  exit 1
fi
jq -e '.valid == false' "$TMP_DIR/bad-absolute-report.json" >/dev/null
jq -e '.errors | join(" ") | test("unsafe|output_files|runtime-relative")' "$TMP_DIR/bad-absolute-report.json" >/dev/null

jq '.output_files.glb = "../bad.glb"' "$TMP_DIR/sidecar-with-outputs.json" >"$TMP_DIR/bad-traversal.json"
bad_traversal_status=0
"$PYTHON_BIN" "$SCRIPT" --verify-artifacts "$TMP_DIR/bad-traversal.json" \
  >"$TMP_DIR/bad-traversal-report.json" || bad_traversal_status=$?
if [ "$bad_traversal_status" -eq 0 ]; then
  echo "traversal artifact path unexpectedly verified successfully" >&2
  exit 1
fi
jq -e '.valid == false' "$TMP_DIR/bad-traversal-report.json" >/dev/null

if "$PYTHON_BIN" "$SCRIPT" --verify-artifacts docs/bad-sidecar.json >/dev/null 2>&1; then
  echo "--verify-artifacts unexpectedly accepted a repo path" >&2
  exit 1
fi

if "$PYTHON_BIN" "$SCRIPT" --verify-artifacts /home/cuneyt/MoE/runtime/media/outputs/3d/metadata/bad.json >/dev/null 2>&1; then
  echo "--verify-artifacts unexpectedly accepted a runtime path" >&2
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

echo "3D artifact verifier OK"
