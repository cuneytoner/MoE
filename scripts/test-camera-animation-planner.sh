#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
PLANNER="apps/media-worker/app/camera_animation_planner.py"
VALIDATOR="apps/media-worker/app/animation_plan_validator.py"
TIMELINE_PLANNER="apps/media-worker/app/animation_timeline_planner.py"
EXAMPLE="configs/animation/camera-orbit.example.yaml"
TMP_PREFIX="/tmp/moe-camera-animation-planner.$$"
RUNTIME_PROBE="/home/cuneyt/MoE/runtime/media/animation/m36-4-runtime-write-probe"

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
    echo "expected invalid camera request exit 1 for $request, got $status" >&2
    exit 1
  fi
  jq -e '.planned == false and .status == "invalid" and .camera_plan == null' "$report" >/dev/null
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
  jq -e '.planned == false and .status == "invalid" and .camera_plan == null' "$report" >/dev/null
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

jq -e '.report_type == "camera_animation_planner"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.planned == true and .status == "planned"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.plan_type == "camera_animation_plan"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.motion_type == "orbit"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.request_sha256 | test("^[0-9a-f]{64}$")' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.request_sha256 == input.camera_plan.request_sha256' "${TMP_PREFIX}-yaml-report.json" "${TMP_PREFIX}-json-report.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$PLANNER" --request "$EXAMPLE" >"${TMP_PREFIX}-compact-a.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$PLANNER" --request "$EXAMPLE" >"${TMP_PREFIX}-compact-b.json"
cmp "${TMP_PREFIX}-compact-a.json" "${TMP_PREFIX}-compact-b.json" >/dev/null

jq -e '.camera_plan.coordinate_system.handedness == "right_handed"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.coordinate_system.world_up_axis == "+Z"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.coordinate_system.orbit_plane == "XY"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.coordinate_system.camera_forward_axis == "-Z"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.coordinate_system.euler_order == "XYZ"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.poses | map(.frame) == [1,30,60,90,120]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.poses[0].angle_degrees == -90.0 and .camera_plan.poses[-1].angle_degrees == 270.0' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.poses | map(.angle_degrees) == [-90.0,0.0,90.0,180.0,270.0]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.poses[1].location == [5.0,0.0,3.0]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.poses[2].location == [0.0,5.0,3.0]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e 'all(.camera_plan.poses[]; .location[2] == 3.0)' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e 'all(.camera_plan.poses[]; all(.location[]; type == "number") and all(.rotation_euler[]; type == "number"))' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e 'all(.camera_plan.poses[]; .rotation_euler[1] == 0.0)' "${TMP_PREFIX}-yaml-report.json" >/dev/null

if grep -E -- '-0(\\.0+)?([,[:space:]}]|$)' "${TMP_PREFIX}-yaml-report.json" >/dev/null; then
  echo "camera planner output contains negative zero" >&2
  exit 1
fi

jq -e '.camera_plan.camera_settings == {"animated":false,"camera_id":"camera","lens_mm":50.0}' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.canonical_animation_plan.tracks | length == 1' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.canonical_animation_plan.tracks[0].target_type == "camera"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.canonical_animation_plan.tracks[0].property == "transform"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.canonical_animation_plan.tracks[0].keyframes | length == 5' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e 'all(.camera_plan.canonical_animation_plan.tracks[0].keyframes[]; has("location") and has("rotation_euler") and (has("scale")|not) and (has("visibility")|not))' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.canonical_animation_plan.tracks | map(.target_type) | index("object") | not' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.timeline_plan.summary.track_count == 1 and .camera_plan.timeline_plan.summary.keyframe_count == 5 and .camera_plan.timeline_plan.summary.segment_count == 4' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.camera_plan.summary.pose_count == 5 and .camera_plan.summary.first_frame == 1 and .camera_plan.summary.last_frame == 120 and .camera_plan.summary.camera_track_count == 1' "${TMP_PREFIX}-yaml-report.json" >/dev/null

canonical_plan="${TMP_PREFIX}-canonical-plan.json"
jq '.camera_plan.canonical_animation_plan' "${TMP_PREFIX}-yaml-report.json" >"$canonical_plan"
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
jq '.camera.camera_id = "bad camera"' "$json_request" >"${TMP_PREFIX}-bad-camera.json"
expect_invalid "${TMP_PREFIX}-bad-camera.json" "${TMP_PREFIX}-bad-camera-report.json" "unsafe_identifier"
jq '.motion.type = "dolly"' "$json_request" >"${TMP_PREFIX}-bad-motion.json"
expect_invalid "${TMP_PREFIX}-bad-motion.json" "${TMP_PREFIX}-bad-motion-report.json" "unsupported_motion_type"
jq '.motion.orientation = "free"' "$json_request" >"${TMP_PREFIX}-bad-orientation.json"
expect_invalid "${TMP_PREFIX}-bad-orientation.json" "${TMP_PREFIX}-bad-orientation-report.json" "unsupported_orientation"
jq '.motion.radius = 0' "$json_request" >"${TMP_PREFIX}-radius-zero.json"
expect_invalid "${TMP_PREFIX}-radius-zero.json" "${TMP_PREFIX}-radius-zero-report.json" "number_below_minimum"
jq '.motion.radius = -1' "$json_request" >"${TMP_PREFIX}-radius-negative.json"
expect_invalid "${TMP_PREFIX}-radius-negative.json" "${TMP_PREFIX}-radius-negative-report.json" "number_below_minimum"
jq '.motion.radius = nan' "$json_request" >"${TMP_PREFIX}-radius-nan.json"
expect_invalid "${TMP_PREFIX}-radius-nan.json" "${TMP_PREFIX}-radius-nan-report.json" "type_mismatch"
jq '.motion.center = [0, nan, 1]' "$json_request" >"${TMP_PREFIX}-center-nan.json"
expect_invalid "${TMP_PREFIX}-center-nan.json" "${TMP_PREFIX}-center-nan-report.json" "type_mismatch"
jq '.motion.center = [0, 1]' "$json_request" >"${TMP_PREFIX}-center-short.json"
expect_invalid "${TMP_PREFIX}-center-short.json" "${TMP_PREFIX}-center-short-report.json" "vector_length_invalid"
jq '.camera.lens_mm = 0.5' "$json_request" >"${TMP_PREFIX}-lens-low.json"
expect_invalid "${TMP_PREFIX}-lens-low.json" "${TMP_PREFIX}-lens-low-report.json" "number_below_minimum"
jq '.camera.lens_mm = 301' "$json_request" >"${TMP_PREFIX}-lens-high.json"
expect_invalid "${TMP_PREFIX}-lens-high.json" "${TMP_PREFIX}-lens-high-report.json" "number_above_maximum"
jq '.motion.end_angle_degrees = .motion.start_angle_degrees' "$json_request" >"${TMP_PREFIX}-same-angle.json"
expect_invalid "${TMP_PREFIX}-same-angle.json" "${TMP_PREFIX}-same-angle-report.json" "orbit_angle_span_invalid"
jq '.motion.end_angle_degrees = 4000' "$json_request" >"${TMP_PREFIX}-angle-span.json"
expect_invalid "${TMP_PREFIX}-angle-span.json" "${TMP_PREFIX}-angle-span-report.json" "orbit_angle_span_invalid"
jq '.motion.keyframe_count = 1' "$json_request" >"${TMP_PREFIX}-keyframes-low.json"
expect_invalid "${TMP_PREFIX}-keyframes-low.json" "${TMP_PREFIX}-keyframes-low-report.json" "number_below_minimum"
jq '.motion.keyframe_count = 65' "$json_request" >"${TMP_PREFIX}-keyframes-high.json"
expect_invalid "${TMP_PREFIX}-keyframes-high.json" "${TMP_PREFIX}-keyframes-high-report.json" "number_above_maximum"
jq '.timeline.end_frame = 2 | .motion.keyframe_count = 3' "$json_request" >"${TMP_PREFIX}-keyframes-too-many.json"
expect_invalid "${TMP_PREFIX}-keyframes-too-many.json" "${TMP_PREFIX}-keyframes-too-many-report.json" "keyframe_count_exceeds_timeline"
jq '.motion.radius = 0.000001 | .motion.height_offset = 0 | .motion.center = [0,0,1]' "$json_request" >"${TMP_PREFIX}-near-center.json"
run_planner "${TMP_PREFIX}-near-center.json" >"${TMP_PREFIX}-near-center-report.json"
jq -e '.planned == true' "${TMP_PREFIX}-near-center-report.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/media-worker/app" "$PYTHON_BIN" - "$json_request" <<'PY'
import copy
import json
import sys
from pathlib import Path

from camera_animation_planner import (
    build_camera_animation_plan,
    build_look_at_rotation_euler,
    build_orbit_frame_numbers,
    build_orbit_positions,
)

request = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
before = copy.deepcopy(request)
result = build_camera_animation_plan(request)
assert result.valid, result.issues
assert request == before
assert build_orbit_frame_numbers(1, 120, 5) == (1, 30, 60, 90, 120)
poses = build_orbit_positions(request)
assert poses[1].location == (5.0, 0.0, 3.0)
assert poses[2].location == (0.0, 5.0, 3.0)
assert build_look_at_rotation_euler((5.0, 0.0, 3.0), (0.0, 0.0, 1.0))[1] == 0.0
try:
    build_look_at_rotation_euler((0.0, 0.0, 1.0), (0.0, 0.0, 1.0))
except ValueError:
    pass
else:
    raise AssertionError("look-at center collision was not rejected")
PY

if grep -E 'timestamp|uuid|mtime|cwd|environment|/home/cuneyt/DiskD|/home/cuneyt/MoE/runtime|MoE_Models_Backup|Traceback|File "' "${TMP_PREFIX}-yaml-report.json" >/dev/null; then
  echo "camera planner output leaked nondeterministic metadata or host paths" >&2
  exit 1
fi

if [ -e "$RUNTIME_PROBE" ]; then
  echo "camera planner wrote or touched animation runtime probe path" >&2
  exit 1
fi

if grep -R '^import bpy\|from bpy\|mathutils\|subprocess\|ffmpeg\|constraints\.new\|constraint_add\|keyframe_insert\|render-preview\|execute-animation\|REAL_ANIMATION_GENERATION' "$PLANNER" >/dev/null; then
  echo "camera planner contains forbidden Blender/constraint/process execution surface" >&2
  exit 1
fi

if rg -n "animation_output_card|animation_reference_board|animation_dashboard" apps/media-worker/app configs/animation >/dev/null; then
  echo "M36.13+ animation output card behavior appears to have started" >&2
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

echo "Camera animation planner OK"
