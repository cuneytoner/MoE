#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
VALIDATOR="apps/media-worker/app/animation_plan_validator.py"
EXAMPLE="configs/animation/animation-plan.example.yaml"
TMP_PREFIX="/tmp/moe-animation-plan-validator.$$"
RUNTIME_PROBE="/home/cuneyt/MoE/runtime/media/animation/m36-2-runtime-write-probe"

cleanup() {
  rm -f "${TMP_PREFIX}"*
}
trap cleanup EXIT

run_validator() {
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --plan "$1" --pretty
}

expect_valid() {
  local plan="$1"
  local output="$2"
  run_validator "$plan" >"$output"
  jq -e '.valid == true and .error_count == 0' "$output" >/dev/null
}

expect_invalid() {
  local plan="$1"
  local output="$2"
  local expected_code="$3"
  local status=0
  run_validator "$plan" >"$output" || status=$?
  if [ "$status" -ne 1 ]; then
    echo "expected validation failure exit 1 for $plan, got $status" >&2
    exit 1
  fi
  jq -e '.valid == false and .error_count > 0' "$output" >/dev/null
  jq -e --arg code "$expected_code" 'any(.errors[]; .code == $code)' "$output" >/dev/null
}

expect_tooling_error() {
  local plan="$1"
  local output="$2"
  local expected_code="$3"
  local status=0
  run_validator "$plan" >"$output" || status=$?
  if [ "$status" -ne 2 ]; then
    echo "expected tooling/path/malformed exit 2 for $plan, got $status" >&2
    exit 1
  fi
  jq -e '.valid == false and .error_count > 0' "$output" >/dev/null
  jq -e --arg code "$expected_code" 'any(.errors[]; .code == $code)' "$output" >/dev/null
}

make_json_fixture() {
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - "$EXAMPLE" "$1" <<'PY'
import json
import sys
from pathlib import Path

import yaml

source = Path(sys.argv[1])
target = Path(sys.argv[2])
target.write_text(json.dumps(yaml.safe_load(source.read_text(encoding="utf-8")), indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
}

json_plan="${TMP_PREFIX}-valid-plan.json"
make_json_fixture "$json_plan"

expect_valid "$EXAMPLE" "${TMP_PREFIX}-valid-yaml-report.json"
expect_valid "$json_plan" "${TMP_PREFIX}-valid-json-report.json"

jq -e '.report_type == "animation_plan_validation"' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.plan_path == "configs/animation/animation-plan.example.yaml"' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.summary.plan_id == "camera-orbit-demo"' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.summary.fps == 24 and .summary.start_frame == 1 and .summary.end_frame == 120 and .summary.duration_seconds == 5' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.summary.track_count == 1 and .summary.keyframe_count == 2' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.summary.target_types == ["camera"] and .summary.properties == ["transform"] and .summary.interpolations == ["bezier"]' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.safety_flags.read_only == true' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.safety_flags.source_assets_modified == false' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.safety_flags.preview_render_attempted == false' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null
jq -e '.safety_flags.external_process_started == false' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null

if grep -E '/home/cuneyt/DiskD|/home/cuneyt/MoE/runtime|MoE_Models_Backup|Traceback|File "' "${TMP_PREFIX}-valid-yaml-report.json" >/dev/null; then
  echo "validation report leaked host paths or traceback details" >&2
  exit 1
fi

cat >"${TMP_PREFIX}-malformed.yaml" <<'YAML'
schema_version: "1.0"
timeline: [
YAML
expect_tooling_error "${TMP_PREFIX}-malformed.yaml" "${TMP_PREFIX}-malformed-yaml-report.json" "malformed_yaml"

cat >"${TMP_PREFIX}-malformed.json" <<'JSON'
{"schema_version": "1.0",
JSON
expect_tooling_error "${TMP_PREFIX}-malformed.json" "${TMP_PREFIX}-malformed-json-report.json" "malformed_json"

cat >"${TMP_PREFIX}-root-array.json" <<'JSON'
[]
JSON
expect_tooling_error "${TMP_PREFIX}-root-array.json" "${TMP_PREFIX}-root-array-report.json" "root_not_object"

jq 'del(.schema_version)' "$json_plan" >"${TMP_PREFIX}-missing-required.json"
expect_invalid "${TMP_PREFIX}-missing-required.json" "${TMP_PREFIX}-missing-required-report.json" "missing_required_field"

jq '.extra = true' "$json_plan" >"${TMP_PREFIX}-unknown-top.json"
expect_invalid "${TMP_PREFIX}-unknown-top.json" "${TMP_PREFIX}-unknown-top-report.json" "unknown_field"

jq '.timeline.extra = true' "$json_plan" >"${TMP_PREFIX}-unknown-nested.json"
expect_invalid "${TMP_PREFIX}-unknown-nested.json" "${TMP_PREFIX}-unknown-nested-report.json" "unknown_field"

jq '.schema_version = "2.0"' "$json_plan" >"${TMP_PREFIX}-bad-schema-version.json"
expect_invalid "${TMP_PREFIX}-bad-schema-version.json" "${TMP_PREFIX}-bad-schema-version-report.json" "const_mismatch"

jq '.mode = "render"' "$json_plan" >"${TMP_PREFIX}-bad-mode.json"
expect_invalid "${TMP_PREFIX}-bad-mode.json" "${TMP_PREFIX}-bad-mode-report.json" "enum_mismatch"

jq '.safety.runtime_write_planned = true' "$json_plan" >"${TMP_PREFIX}-bad-safety.json"
expect_invalid "${TMP_PREFIX}-bad-safety.json" "${TMP_PREFIX}-bad-safety-report.json" "const_mismatch"

jq '.timeline.fps = true' "$json_plan" >"${TMP_PREFIX}-bool-fps.json"
expect_invalid "${TMP_PREFIX}-bool-fps.json" "${TMP_PREFIX}-bool-fps-report.json" "type_mismatch"

jq '.timeline.fps = 0' "$json_plan" >"${TMP_PREFIX}-fps-low.json"
expect_invalid "${TMP_PREFIX}-fps-low.json" "${TMP_PREFIX}-fps-low-report.json" "number_below_minimum"

jq '.timeline.fps = 121' "$json_plan" >"${TMP_PREFIX}-fps-high.json"
expect_invalid "${TMP_PREFIX}-fps-high.json" "${TMP_PREFIX}-fps-high-report.json" "number_above_maximum"

jq '.timeline.end_frame = 1' "$json_plan" >"${TMP_PREFIX}-bad-range.json"
expect_invalid "${TMP_PREFIX}-bad-range.json" "${TMP_PREFIX}-bad-range-report.json" "timeline_invalid_range"

jq '.timeline.duration_seconds = 9' "$json_plan" >"${TMP_PREFIX}-bad-duration.json"
expect_invalid "${TMP_PREFIX}-bad-duration.json" "${TMP_PREFIX}-bad-duration-report.json" "timeline_duration_mismatch"

jq '.tracks += [.tracks[0]]' "$json_plan" >"${TMP_PREFIX}-duplicate-track.json"
expect_invalid "${TMP_PREFIX}-duplicate-track.json" "${TMP_PREFIX}-duplicate-track-report.json" "duplicate_track_id"

jq '.tracks = []' "$json_plan" >"${TMP_PREFIX}-empty-tracks.json"
expect_invalid "${TMP_PREFIX}-empty-tracks.json" "${TMP_PREFIX}-empty-tracks-report.json" "array_too_short"

jq '.tracks = [range(0;65) | (. as $i | . = $ARGS.named.track | .track_id = ("track-" + ($i|tostring)))]' --argjson track "$(jq '.tracks[0]' "$json_plan")" "$json_plan" >"${TMP_PREFIX}-too-many-tracks.json"
expect_invalid "${TMP_PREFIX}-too-many-tracks.json" "${TMP_PREFIX}-too-many-tracks-report.json" "array_too_long"

jq '.tracks[0].keyframes = []' "$json_plan" >"${TMP_PREFIX}-empty-keyframes.json"
expect_invalid "${TMP_PREFIX}-empty-keyframes.json" "${TMP_PREFIX}-empty-keyframes-report.json" "array_too_short"

jq '.tracks[0].keyframes = [range(0;1001) | {frame: ., location: [0,0,0]}]' "$json_plan" >"${TMP_PREFIX}-too-many-keyframes.json"
expect_invalid "${TMP_PREFIX}-too-many-keyframes.json" "${TMP_PREFIX}-too-many-keyframes-report.json" "array_too_long"

jq '.tracks[0].keyframes[1].frame = 1' "$json_plan" >"${TMP_PREFIX}-duplicate-frame.json"
expect_invalid "${TMP_PREFIX}-duplicate-frame.json" "${TMP_PREFIX}-duplicate-frame-report.json" "duplicate_keyframe_frame"

jq '.tracks[0].keyframes[0].frame = 20 | .tracks[0].keyframes[1].frame = 10' "$json_plan" >"${TMP_PREFIX}-out-of-order.json"
expect_invalid "${TMP_PREFIX}-out-of-order.json" "${TMP_PREFIX}-out-of-order-report.json" "keyframes_not_strictly_increasing"

jq '.tracks[0].keyframes[1].frame = 999' "$json_plan" >"${TMP_PREFIX}-outside-timeline.json"
expect_invalid "${TMP_PREFIX}-outside-timeline.json" "${TMP_PREFIX}-outside-timeline-report.json" "keyframe_outside_timeline"

jq '.tracks[0].property = "location" | del(.tracks[0].keyframes[0].location) | del(.tracks[0].keyframes[0].rotation_euler) | del(.tracks[0].keyframes[0].scale) | .tracks[0].keyframes[0].visibility = true' "$json_plan" >"${TMP_PREFIX}-missing-property.json"
expect_invalid "${TMP_PREFIX}-missing-property.json" "${TMP_PREFIX}-missing-property-report.json" "keyframe_property_mismatch"

jq '.tracks[0].property = "location" | .tracks[0].keyframes[0] = {frame: 1, location: [1,2,3], rotation_euler: [0,0,0]}' "$json_plan" >"${TMP_PREFIX}-unrelated-property.json"
expect_invalid "${TMP_PREFIX}-unrelated-property.json" "${TMP_PREFIX}-unrelated-property-report.json" "keyframe_property_mismatch"

jq '.tracks[0].keyframes[0].location = [1,2]' "$json_plan" >"${TMP_PREFIX}-bad-vector-length.json"
expect_invalid "${TMP_PREFIX}-bad-vector-length.json" "${TMP_PREFIX}-bad-vector-length-report.json" "vector_length_invalid"

jq '.tracks[0].keyframes[0].location = [1,2, nan]' "$json_plan" >"${TMP_PREFIX}-non-finite-vector.json"
expect_invalid "${TMP_PREFIX}-non-finite-vector.json" "${TMP_PREFIX}-non-finite-vector-report.json" "type_mismatch"

jq '.plan_id = "../bad"' "$json_plan" >"${TMP_PREFIX}-bad-plan-id.json"
expect_invalid "${TMP_PREFIX}-bad-plan-id.json" "${TMP_PREFIX}-bad-plan-id-report.json" "unsafe_identifier"

jq '.scene.source_scene.reference_id = "/home/cuneyt/MoE/runtime/bad.blend"' "$json_plan" >"${TMP_PREFIX}-bad-reference-id.json"
expect_invalid "${TMP_PREFIX}-bad-reference-id.json" "${TMP_PREFIX}-bad-reference-id-report.json" "unsafe_identifier"

jq '.tracks[0].target_id = "https://example.invalid/model"' "$json_plan" >"${TMP_PREFIX}-bad-target-id.json"
expect_invalid "${TMP_PREFIX}-bad-target-id.json" "${TMP_PREFIX}-bad-target-id-report.json" "unsafe_identifier"

jq '.outputs.preview.relative_runtime_path = "/tmp/out.mp4"' "$json_plan" >"${TMP_PREFIX}-absolute-preview.json"
expect_invalid "${TMP_PREFIX}-absolute-preview.json" "${TMP_PREFIX}-absolute-preview-report.json" "unsafe_runtime_relative_path"

jq '.outputs.preview.relative_runtime_path = "media/animation/previews/../out.mp4"' "$json_plan" >"${TMP_PREFIX}-traversal-preview.json"
expect_invalid "${TMP_PREFIX}-traversal-preview.json" "${TMP_PREFIX}-traversal-preview-report.json" "unsafe_runtime_relative_path"

jq '.outputs.preview.relative_runtime_path = "media\\\\animation\\\\previews\\\\out.mp4"' "$json_plan" >"${TMP_PREFIX}-backslash-preview.json"
expect_invalid "${TMP_PREFIX}-backslash-preview.json" "${TMP_PREFIX}-backslash-preview-report.json" "unsafe_runtime_relative_path"

jq '.outputs.preview.relative_runtime_path = "https://example.invalid/out.mp4"' "$json_plan" >"${TMP_PREFIX}-url-preview.json"
expect_invalid "${TMP_PREFIX}-url-preview.json" "${TMP_PREFIX}-url-preview-report.json" "unsafe_runtime_relative_path"

jq '.outputs.preview.format = "webm" | .outputs.preview.relative_runtime_path = "media/animation/previews/camera-orbit-demo.mp4"' "$json_plan" >"${TMP_PREFIX}-extension-mismatch.json"
expect_invalid "${TMP_PREFIX}-extension-mismatch.json" "${TMP_PREFIX}-extension-mismatch-report.json" "unsafe_runtime_relative_path"

jq '.outputs.metadata.relative_runtime_path = "../metadata.json"' "$json_plan" >"${TMP_PREFIX}-unsafe-metadata.json"
expect_invalid "${TMP_PREFIX}-unsafe-metadata.json" "${TMP_PREFIX}-unsafe-metadata-report.json" "unsafe_runtime_relative_path"

ln -s "$json_plan" "${TMP_PREFIX}-symlink-plan.json"
expect_tooling_error "${TMP_PREFIX}-symlink-plan.json" "${TMP_PREFIX}-symlink-report.json" "input_symlink_rejected"

cp "$json_plan" "${TMP_PREFIX}-outside.txt"
expect_tooling_error "${TMP_PREFIX}-outside.txt" "${TMP_PREFIX}-outside-extension-report.json" "unsupported_input_extension"

if run_validator "docs/not-an-animation-plan.json" >/dev/null 2>&1; then
  echo "validator accepted non-allowlisted source path" >&2
  exit 1
fi

oversized="${TMP_PREFIX}-oversized.json"
: >"$oversized"
for _ in $(seq 1 260); do
  printf '%1024s' "x" >>"$oversized"
done
expect_tooling_error "$oversized" "${TMP_PREFIX}-oversized-report.json" "input_too_large"

run_validator "${TMP_PREFIX}-duplicate-track.json" >"${TMP_PREFIX}-deterministic-a.json" || true
run_validator "${TMP_PREFIX}-duplicate-track.json" >"${TMP_PREFIX}-deterministic-b.json" || true
cmp "${TMP_PREFIX}-deterministic-a.json" "${TMP_PREFIX}-deterministic-b.json" >/dev/null

if [ -e "$RUNTIME_PROBE" ]; then
  echo "validator wrote or touched animation runtime probe path" >&2
  exit 1
fi

if grep -R '^import bpy\|from bpy\|subprocess\|ffmpeg\|render-preview\|execute-animation\|REAL_ANIMATION_GENERATION' apps/media-worker/app/animation_plan_validator.py >/dev/null; then
  echo "validator contains forbidden Blender/render/process execution surface" >&2
  exit 1
fi

if rg -n "Blender operation plan|bpy operation|adapter implementation|execute-animation" apps/media-worker/app configs/animation --glob '!configs/animation/animation-plan.example.yaml' >/dev/null; then
  echo "M36.6 Blender animation adapter behavior appears to have started" >&2
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

echo "Animation plan validator OK"
