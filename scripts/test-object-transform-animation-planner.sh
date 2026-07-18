#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
PLANNER="apps/media-worker/app/object_transform_animation_planner.py"
VALIDATOR="apps/media-worker/app/animation_plan_validator.py"
TIMELINE_PLANNER="apps/media-worker/app/animation_timeline_planner.py"
EXAMPLE="configs/animation/object-transform.example.yaml"
TMP_PREFIX="/tmp/moe-object-transform-animation-planner.$$"
RUNTIME_PROBE="/home/cuneyt/MoE/runtime/media/animation/m36-5-runtime-write-probe"

cleanup() {
  rm -f "${TMP_PREFIX}"*
}
trap cleanup EXIT

run_planner() {
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$PLANNER" --request "$1" --pretty
}

expect_invalid() {
  local request="$1"
  local report="$2"
  local code="$3"
  local status=0
  run_planner "$request" >"$report" || status=$?
  if [ "$status" -ne 1 ]; then
    echo "expected invalid object request exit 1 for $request, got $status" >&2
    exit 1
  fi
  jq -e '.planned == false and .status == "invalid" and .object_plan == null' "$report" >/dev/null
  jq -e --arg code "$code" 'any(.errors[]; .code == $code)' "$report" >/dev/null
}

expect_tooling_error() {
  local request="$1"
  local report="$2"
  local code="$3"
  local status=0
  run_planner "$request" >"$report" || status=$?
  if [ "$status" -ne 2 ]; then
    echo "expected tooling error exit 2 for $request, got $status" >&2
    exit 1
  fi
  jq -e '.planned == false and .status == "invalid" and .object_plan == null' "$report" >/dev/null
  jq -e --arg code "$code" 'any(.errors[]; .code == $code)' "$report" >/dev/null
}

make_json_fixture() {
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - "$EXAMPLE" "$1" <<'PY'
import json
import sys
from pathlib import Path

import yaml

payload = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8"))
Path(sys.argv[2]).write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
}

json_request="${TMP_PREFIX}-request.json"
make_json_fixture "$json_request"

run_planner "$EXAMPLE" >"${TMP_PREFIX}-yaml-report.json"
run_planner "$json_request" >"${TMP_PREFIX}-json-report.json"

jq -e '.report_type == "object_transform_animation_planner"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.planned == true and .status == "planned"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.plan_type == "object_transform_animation_plan"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.motion_type == "transform_between"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.request_sha256 | test("^[0-9a-f]{64}$")' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.request_sha256 == input.object_plan.request_sha256' "${TMP_PREFIX}-yaml-report.json" "${TMP_PREFIX}-json-report.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$PLANNER" --request "$EXAMPLE" >"${TMP_PREFIX}-compact-a.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$PLANNER" --request "$EXAMPLE" >"${TMP_PREFIX}-compact-b.json"
cmp "${TMP_PREFIX}-compact-a.json" "${TMP_PREFIX}-compact-b.json" >/dev/null

jq -e '.object_plan.coordinate_system.handedness == "right_handed"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.coordinate_system.world_up_axis == "+Z"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.coordinate_system.euler_order == "XYZ"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.coordinate_system.request_rotation_unit == "degrees"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.coordinate_system.canonical_rotation_unit == "radians"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.object_settings == {"object_id":"demo-object","runtime_resolved":false}' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.transform.animated_fields == ["location","rotation_euler","scale"]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.transform.start_frame == 1 and .object_plan.transform.end_frame == 120' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.visibility.enabled == false and .object_plan.visibility.track_created == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null

jq -e '.object_plan.canonical_animation_plan.tracks | length == 1' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].track_id == "object-demo-object-transform"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].target_type == "object"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].property == "transform"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].interpolation == "bezier"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].keyframes | length == 2' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].keyframes | map(.frame) == [1,120]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].keyframes[0].location == [0.0,0.0,0.0]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].keyframes[1].location == [2.0,0.0,1.0]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].keyframes[1].rotation_euler == [0.0,0.0,1.570796327]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].keyframes[1].scale == [1.0,1.0,1.0]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks | map(.target_type) | index("camera") | not' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.summary.object_track_count == 1 and .object_plan.summary.transform_track_count == 1 and .object_plan.summary.visibility_track_count == 0 and .object_plan.summary.keyframe_count == 2' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.object_plan.timeline_plan.summary.track_count == 1 and .object_plan.timeline_plan.summary.keyframe_count == 2 and .object_plan.timeline_plan.summary.segment_count == 1' "${TMP_PREFIX}-yaml-report.json" >/dev/null

if grep -E -- '-0(\\.0+)?([,[:space:]}]|$)' "${TMP_PREFIX}-yaml-report.json" >/dev/null; then
  echo "object planner output contains negative zero" >&2
  exit 1
fi

canonical_plan="${TMP_PREFIX}-canonical-plan.json"
jq '.object_plan.canonical_animation_plan' "${TMP_PREFIX}-yaml-report.json" >"$canonical_plan"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --plan "$canonical_plan" >"${TMP_PREFIX}-validator-report.json"
jq -e '.valid == true' "${TMP_PREFIX}-validator-report.json" >/dev/null
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$TIMELINE_PLANNER" --plan "$canonical_plan" >"${TMP_PREFIX}-timeline-report.json"
jq -e '.planned == true' "${TMP_PREFIX}-timeline-report.json" >/dev/null

cat >"${TMP_PREFIX}-malformed.yaml" <<'YAML'
schema_version: "1.0"
motion: [
YAML
expect_tooling_error "${TMP_PREFIX}-malformed.yaml" "${TMP_PREFIX}-malformed-yaml-report.json" "malformed_yaml"

cat >"${TMP_PREFIX}-malformed.json" <<'JSON'
{"schema_version": "1.0",
JSON
expect_tooling_error "${TMP_PREFIX}-malformed.json" "${TMP_PREFIX}-malformed-json-report.json" "malformed_json"

jq '.extra = true' "$json_request" >"${TMP_PREFIX}-unknown.json"
expect_invalid "${TMP_PREFIX}-unknown.json" "${TMP_PREFIX}-unknown-report.json" "unknown_field"
jq '.mode = "real"' "$json_request" >"${TMP_PREFIX}-mode.json"
expect_invalid "${TMP_PREFIX}-mode.json" "${TMP_PREFIX}-mode-report.json" "const_mismatch"
jq '.safety.runtime_write_planned = true' "$json_request" >"${TMP_PREFIX}-safety.json"
expect_invalid "${TMP_PREFIX}-safety.json" "${TMP_PREFIX}-safety-report.json" "const_mismatch"
jq '.request_id = "../bad"' "$json_request" >"${TMP_PREFIX}-bad-request-id.json"
expect_invalid "${TMP_PREFIX}-bad-request-id.json" "${TMP_PREFIX}-bad-request-id-report.json" "unsafe_identifier"
jq '.output_plan_id = "/bad"' "$json_request" >"${TMP_PREFIX}-bad-output-id.json"
expect_invalid "${TMP_PREFIX}-bad-output-id.json" "${TMP_PREFIX}-bad-output-id-report.json" "unsafe_identifier"
jq '.scene.source_scene.reference_id = "https://example.invalid/asset"' "$json_request" >"${TMP_PREFIX}-bad-reference.json"
expect_invalid "${TMP_PREFIX}-bad-reference.json" "${TMP_PREFIX}-bad-reference-report.json" "unsafe_identifier"
jq '.object.object_id = "bad object"' "$json_request" >"${TMP_PREFIX}-bad-object.json"
expect_invalid "${TMP_PREFIX}-bad-object.json" "${TMP_PREFIX}-bad-object-report.json" "unsafe_identifier"
jq '.motion.type = "path"' "$json_request" >"${TMP_PREFIX}-bad-motion.json"
expect_invalid "${TMP_PREFIX}-bad-motion.json" "${TMP_PREFIX}-bad-motion-report.json" "unsupported_motion_type"
jq '.motion.interpolation = "ease-in"' "$json_request" >"${TMP_PREFIX}-bad-interpolation.json"
expect_invalid "${TMP_PREFIX}-bad-interpolation.json" "${TMP_PREFIX}-bad-interpolation-report.json" "enum_mismatch"
jq '.timeline.end_frame = 1' "$json_request" >"${TMP_PREFIX}-bad-timeline.json"
expect_invalid "${TMP_PREFIX}-bad-timeline.json" "${TMP_PREFIX}-bad-timeline-report.json" "timeline_invalid_range"
jq 'del(.motion.start.location, .motion.start.rotation_euler_degrees, .motion.start.scale, .motion.end.location, .motion.end.rotation_euler_degrees, .motion.end.scale)' "$json_request" >"${TMP_PREFIX}-empty-transform.json"
expect_invalid "${TMP_PREFIX}-empty-transform.json" "${TMP_PREFIX}-empty-transform-report.json" "empty_transform"
jq 'del(.motion.end.location)' "$json_request" >"${TMP_PREFIX}-missing-end-location.json"
expect_invalid "${TMP_PREFIX}-missing-end-location.json" "${TMP_PREFIX}-missing-end-location-report.json" "transform_field_mismatch"
jq 'del(.motion.start.rotation_euler_degrees)' "$json_request" >"${TMP_PREFIX}-missing-start-rotation.json"
expect_invalid "${TMP_PREFIX}-missing-start-rotation.json" "${TMP_PREFIX}-missing-start-rotation-report.json" "transform_field_mismatch"
jq 'del(.motion.end.scale)' "$json_request" >"${TMP_PREFIX}-missing-end-scale.json"
expect_invalid "${TMP_PREFIX}-missing-end-scale.json" "${TMP_PREFIX}-missing-end-scale-report.json" "transform_field_mismatch"
jq '.motion.start = {"rotation_euler_degrees":[0,0,0]} | .motion.end = {"location":[1,2,3]}' "$json_request" >"${TMP_PREFIX}-different-fields.json"
expect_invalid "${TMP_PREFIX}-different-fields.json" "${TMP_PREFIX}-different-fields-report.json" "transform_field_mismatch"
jq '.motion.start.location = [1,2]' "$json_request" >"${TMP_PREFIX}-bad-vector-length.json"
expect_invalid "${TMP_PREFIX}-bad-vector-length.json" "${TMP_PREFIX}-bad-vector-length-report.json" "vector_length_invalid"
jq '.motion.start.location = [1,true,3]' "$json_request" >"${TMP_PREFIX}-bool-vector.json"
expect_invalid "${TMP_PREFIX}-bool-vector.json" "${TMP_PREFIX}-bool-vector-report.json" "type_mismatch"
jq '.motion.start.location = [1,nan,3]' "$json_request" >"${TMP_PREFIX}-nan-vector.json"
expect_invalid "${TMP_PREFIX}-nan-vector.json" "${TMP_PREFIX}-nan-vector-report.json" "type_mismatch"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - "$json_request" "${TMP_PREFIX}-inf-vector.json" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
payload["motion"]["start"]["location"] = [1, float("inf"), 3]
Path(sys.argv[2]).write_text(json.dumps(payload, allow_nan=True) + "\n", encoding="utf-8")
PY
expect_invalid "${TMP_PREFIX}-inf-vector.json" "${TMP_PREFIX}-inf-vector-report.json" "type_mismatch"
jq '.motion.start.location = [1000001,0,0]' "$json_request" >"${TMP_PREFIX}-location-high.json"
expect_invalid "${TMP_PREFIX}-location-high.json" "${TMP_PREFIX}-location-high-report.json" "number_above_maximum"
jq '.motion.start.rotation_euler_degrees = [36001,0,0]' "$json_request" >"${TMP_PREFIX}-rotation-high.json"
expect_invalid "${TMP_PREFIX}-rotation-high.json" "${TMP_PREFIX}-rotation-high-report.json" "number_above_maximum"
jq '.motion.start.scale = [0,1,1]' "$json_request" >"${TMP_PREFIX}-scale-zero.json"
expect_invalid "${TMP_PREFIX}-scale-zero.json" "${TMP_PREFIX}-scale-zero-report.json" "number_below_minimum"
jq '.motion.start.scale = [-1,1,1]' "$json_request" >"${TMP_PREFIX}-scale-negative.json"
expect_invalid "${TMP_PREFIX}-scale-negative.json" "${TMP_PREFIX}-scale-negative-report.json" "number_below_minimum"
jq '.motion.start.scale = [1000001,1,1]' "$json_request" >"${TMP_PREFIX}-scale-high.json"
expect_invalid "${TMP_PREFIX}-scale-high.json" "${TMP_PREFIX}-scale-high-report.json" "number_above_maximum"

jq 'del(.motion.start.rotation_euler_degrees, .motion.start.scale, .motion.end.rotation_euler_degrees, .motion.end.scale)' "$json_request" >"${TMP_PREFIX}-location-only.json"
run_planner "${TMP_PREFIX}-location-only.json" >"${TMP_PREFIX}-location-only-report.json"
jq -e '.object_plan.transform.animated_fields == ["location"]' "${TMP_PREFIX}-location-only-report.json" >/dev/null
jq -e 'all(.object_plan.canonical_animation_plan.tracks[0].keyframes[]; has("location") and (has("rotation_euler")|not) and (has("scale")|not))' "${TMP_PREFIX}-location-only-report.json" >/dev/null

jq 'del(.motion.start.location, .motion.start.scale, .motion.end.location, .motion.end.scale) | .motion.end.rotation_euler_degrees = [0,180,-90]' "$json_request" >"${TMP_PREFIX}-rotation-only.json"
run_planner "${TMP_PREFIX}-rotation-only.json" >"${TMP_PREFIX}-rotation-only-report.json"
jq -e '.object_plan.transform.animated_fields == ["rotation_euler"]' "${TMP_PREFIX}-rotation-only-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].keyframes[0].rotation_euler == [0.0,0.0,0.0]' "${TMP_PREFIX}-rotation-only-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].keyframes[1].rotation_euler == [0.0,3.141592654,-1.570796327]' "${TMP_PREFIX}-rotation-only-report.json" >/dev/null
jq -e 'all(.object_plan.canonical_animation_plan.tracks[0].keyframes[]; (has("location")|not) and has("rotation_euler") and (has("scale")|not))' "${TMP_PREFIX}-rotation-only-report.json" >/dev/null

jq 'del(.motion.start.location, .motion.start.rotation_euler_degrees, .motion.end.location, .motion.end.rotation_euler_degrees)' "$json_request" >"${TMP_PREFIX}-scale-only.json"
run_planner "${TMP_PREFIX}-scale-only.json" >"${TMP_PREFIX}-scale-only-report.json"
jq -e '.object_plan.transform.animated_fields == ["scale"]' "${TMP_PREFIX}-scale-only-report.json" >/dev/null
jq -e 'all(.object_plan.canonical_animation_plan.tracks[0].keyframes[]; (has("location")|not) and (has("rotation_euler")|not) and has("scale"))' "${TMP_PREFIX}-scale-only-report.json" >/dev/null

jq '.visibility.enabled = true | .visibility.end_visible = false' "$json_request" >"${TMP_PREFIX}-visibility.json"
run_planner "${TMP_PREFIX}-visibility.json" >"${TMP_PREFIX}-visibility-report.json"
jq -e '.object_plan.canonical_animation_plan.tracks | length == 2' "${TMP_PREFIX}-visibility-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].property == "transform" and .object_plan.canonical_animation_plan.tracks[1].property == "visibility"' "${TMP_PREFIX}-visibility-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[1].track_id == "object-demo-object-visibility"' "${TMP_PREFIX}-visibility-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[1].interpolation == "constant"' "${TMP_PREFIX}-visibility-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[1].keyframes == [{"frame":1,"visibility":true},{"frame":120,"visibility":false}]' "${TMP_PREFIX}-visibility-report.json" >/dev/null
jq -e 'all(.object_plan.canonical_animation_plan.tracks[0].keyframes[]; has("visibility") | not)' "${TMP_PREFIX}-visibility-report.json" >/dev/null
jq -e '.object_plan.summary.object_track_count == 2 and .object_plan.summary.visibility_track_count == 1 and .object_plan.summary.keyframe_count == 4' "${TMP_PREFIX}-visibility-report.json" >/dev/null
jq '.visibility.enabled = true | .visibility.interpolation = "linear"' "$json_request" >"${TMP_PREFIX}-visibility-linear.json"
expect_invalid "${TMP_PREFIX}-visibility-linear.json" "${TMP_PREFIX}-visibility-linear-report.json" "enum_mismatch"

jq '.motion.end = .motion.start' "$json_request" >"${TMP_PREFIX}-same-transform.json"
run_planner "${TMP_PREFIX}-same-transform.json" >"${TMP_PREFIX}-same-transform-report.json"
jq -e '.planned == true' "${TMP_PREFIX}-same-transform-report.json" >/dev/null
jq -e 'any(.warnings[]; .code == "object_transform_unchanged")' "${TMP_PREFIX}-same-transform-report.json" >/dev/null
jq -e '.object_plan.canonical_animation_plan.tracks[0].keyframes | length == 2' "${TMP_PREFIX}-same-transform-report.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/media-worker/app" "$PYTHON_BIN" - "$json_request" <<'PY'
import copy
import json
import sys
from pathlib import Path

from object_transform_animation_planner import (
    build_object_animation_plan,
    normalize_object_transform,
)

request = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
before = copy.deepcopy(request)
result = build_object_animation_plan(request)
assert result.valid, result.issues
assert request == before
state = normalize_object_transform({"rotation_euler_degrees": [0, 90, -180]})
assert state.location is None
assert state.rotation_euler == (0.0, 1.570796327, -3.141592654)
assert state.scale is None
PY

if grep -E 'timestamp|uuid|mtime|cwd|environment|hostname|/home/cuneyt/DiskD|/home/cuneyt/MoE/runtime|MoE_Models_Backup|Traceback|File "' "${TMP_PREFIX}-yaml-report.json" >/dev/null; then
  echo "object planner output leaked nondeterministic metadata or host paths" >&2
  exit 1
fi

if [ -e "$RUNTIME_PROBE" ]; then
  echo "object planner wrote or touched animation runtime probe path" >&2
  exit 1
fi

if grep -R '^import bpy\|from bpy\|mathutils\|subprocess\|ffmpeg\|constraints\.new\|constraint_add\|keyframe_insert\|render-preview\|execute-animation\|REAL_ANIMATION_GENERATION' "$PLANNER" >/dev/null; then
  echo "object planner contains forbidden Blender/constraint/process execution surface" >&2
  exit 1
fi

if rg -n "animation_artifact_verifier|verify_animation_artifact" apps/media-worker/app configs/animation >/dev/null; then
  echo "M36.12+ animation artifact verifier behavior appears to have started" >&2
  exit 1
fi

if find . -type d \( -name node_modules -o -name dist -o -name build -o -name .cache -o -name __pycache__ \) -print -quit | grep -q .; then
  echo "generated dependency/build/cache directory found in source checkout" >&2
  exit 1
fi

if find . -type f \( -name "*.mp4" -o -name "*.webm" -o -name "*.mov" -o -name "*.gif" -o -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print -quit | grep -q .; then
  echo "generated animation/video/3D artifact found in source checkout" >&2
  exit 1
fi

echo "Object transform animation planner OK"
