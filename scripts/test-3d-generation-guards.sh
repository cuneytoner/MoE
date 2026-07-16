#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
SCRIPT="apps/3d-generator/generic_parametric_blender.py"
CONFIG="configs/3d/generic-object.example.json"
TMP_PLAN="$(mktemp /tmp/moe-3d-generation-guards-plan.XXXXXX.json)"
TMP_REAL_PLAN="$(mktemp /tmp/moe-3d-generation-guards-real.XXXXXX.json)"
TMP_EXECUTE_STDERR="$(mktemp /tmp/moe-3d-generation-guards-execute.XXXXXX.err)"
TMP_BLENDER_STDERR="$(mktemp /tmp/moe-3d-generation-guards-blender.XXXXXX.err)"

cleanup() {
  rm -f "$TMP_PLAN" "$TMP_REAL_PLAN" "$TMP_EXECUTE_STDERR" "$TMP_BLENDER_STDERR"
}
trap cleanup EXIT

"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --dry-run >/dev/null
"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --plan-json >"$TMP_PLAN"

jq -e '.generation_guard.generation_implementation_present == true' "$TMP_PLAN" >/dev/null
jq -e '.generation_guard.real_generation_env_enabled == false' "$TMP_PLAN" >/dev/null
jq -e '.generation_guard.execute_generation_requested == false' "$TMP_PLAN" >/dev/null
jq -e '.generation_guard.all_generation_guards_passed == false' "$TMP_PLAN" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_PLAN" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_PLAN" >/dev/null

REAL_3D_GENERATION=1 "$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --plan-json >"$TMP_REAL_PLAN"
jq -e '.generation_guard.real_generation_env_enabled == true' "$TMP_REAL_PLAN" >/dev/null
jq -e '.generation_guard.execute_generation_requested == false' "$TMP_REAL_PLAN" >/dev/null
jq -e '.generation_guard.all_generation_guards_passed == false' "$TMP_REAL_PLAN" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_REAL_PLAN" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_REAL_PLAN" >/dev/null

execute_status=0
"$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --execute-generation >/dev/null 2>"$TMP_EXECUTE_STDERR" || execute_status=$?
if [ "$execute_status" -eq 0 ]; then
  echo "--execute-generation unexpectedly succeeded without REAL_3D_GENERATION=1" >&2
  exit 1
fi
grep -F "REAL_3D_GENERATION=1" "$TMP_EXECUTE_STDERR" >/dev/null

blender_status=0
REAL_3D_GENERATION=1 "$PYTHON_BIN" "$SCRIPT" --config "$CONFIG" --execute-generation >/dev/null 2>"$TMP_BLENDER_STDERR" || blender_status=$?
if [ "$blender_status" -eq 0 ]; then
  echo "guarded generation unexpectedly succeeded outside Blender" >&2
  exit 1
fi
grep -F "Blender/bpy is unavailable" "$TMP_BLENDER_STDERR" >/dev/null
if grep -F "Traceback" "$TMP_BLENDER_STDERR" >/dev/null; then
  echo "outside-Blender failure included a traceback" >&2
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

echo "3D generation guards OK"
