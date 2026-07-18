#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
PLANNER="apps/media-worker/app/animation_timeline_planner.py"
VALIDATOR="apps/media-worker/app/animation_plan_validator.py"
EXAMPLE="configs/animation/animation-plan.example.yaml"
TMP_PREFIX="/tmp/moe-animation-timeline-planner.$$"
RUNTIME_PROBE="/home/cuneyt/MoE/runtime/media/animation/m36-3-runtime-write-probe"

cleanup() {
  rm -f "${TMP_PREFIX}"*
}
trap cleanup EXIT

run_planner() {
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$PLANNER" --plan "$1" --pretty
}

make_json_fixture() {
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - "$EXAMPLE" "$1" <<'PY'
import json
import sys
from pathlib import Path

import yaml

source = Path(sys.argv[1])
target = Path(sys.argv[2])
payload = yaml.safe_load(source.read_text(encoding="utf-8"))
target.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
}

json_plan="${TMP_PREFIX}-valid-plan.json"
make_json_fixture "$json_plan"

run_planner "$EXAMPLE" >"${TMP_PREFIX}-yaml-report.json"
run_planner "$json_plan" >"${TMP_PREFIX}-json-report.json"

jq -e '.report_type == "animation_timeline_planner"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.planned == true and .status == "planned"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.plan_type == "animation_timeline_keyframe_plan"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.source_plan_id == "camera-orbit-demo"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.source_plan_sha256 | test("^[0-9a-f]{64}$")' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.source_plan_sha256 == input.timeline_plan.source_plan_sha256' "${TMP_PREFIX}-yaml-report.json" "${TMP_PREFIX}-json-report.json" >/dev/null

jq 'del(.source_plan_path)' "${TMP_PREFIX}-yaml-report.json" >"${TMP_PREFIX}-yaml-no-path.json"
jq 'del(.source_plan_path)' "${TMP_PREFIX}-json-report.json" >"${TMP_PREFIX}-json-no-path.json"
cmp "${TMP_PREFIX}-yaml-no-path.json" "${TMP_PREFIX}-json-no-path.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$PLANNER" --plan "$EXAMPLE" >"${TMP_PREFIX}-compact-a.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$PLANNER" --plan "$EXAMPLE" >"${TMP_PREFIX}-compact-b.json"
cmp "${TMP_PREFIX}-compact-a.json" "${TMP_PREFIX}-compact-b.json" >/dev/null

jq -e '.timeline_plan.timeline.total_frames == 120' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.timeline.frame_span == 119' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.timeline.frame_duration_seconds == 0.041666667' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.timeline.frame_span_seconds == 4.958333333' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.timeline.duration_seconds == 5.0' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.timeline.declared_duration_seconds == 5.0' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].keyframes[0].time_seconds == 0.0' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].keyframes[1].normalized_progress == 1.0' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].keyframes[1].time_seconds == 4.958333333' "${TMP_PREFIX}-yaml-report.json" >/dev/null

if grep -E -- '-0(\\.0+)?([,[:space:]}]|$)' "${TMP_PREFIX}-yaml-report.json" >/dev/null; then
  echo "planner output contains negative zero" >&2
  exit 1
fi

jq '.tracks[0].keyframes = [
  {"frame": 1, "location": [0, 0, 0]},
  {"frame": 61, "location": [1, 2, 3]},
  {"frame": 120, "location": [2, 4, 6]}
] | .tracks[0].property = "location"' "$json_plan" >"${TMP_PREFIX}-three-keyframes.json"
run_planner "${TMP_PREFIX}-three-keyframes.json" >"${TMP_PREFIX}-three-keyframes-report.json"
jq -e '.timeline_plan.tracks[0].keyframes[1].normalized_progress == 0.504201681' "${TMP_PREFIX}-three-keyframes-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].segment_count == 2' "${TMP_PREFIX}-three-keyframes-report.json" >/dev/null
jq -e '.timeline_plan.summary.segment_count == 2' "${TMP_PREFIX}-three-keyframes-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].segments[0].frame_delta == 60' "${TMP_PREFIX}-three-keyframes-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].segments[0].duration_seconds == 2.5' "${TMP_PREFIX}-three-keyframes-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].segments[0].interpolation == "bezier"' "${TMP_PREFIX}-three-keyframes-report.json" >/dev/null

jq '.tracks[0].keyframes = [{"frame": 1, "location": [1,2,3]}] | .tracks[0].property = "location"' "$json_plan" >"${TMP_PREFIX}-single-keyframe.json"
run_planner "${TMP_PREFIX}-single-keyframe.json" >"${TMP_PREFIX}-single-keyframe-report.json"
jq -e '.timeline_plan.tracks[0].segment_count == 0' "${TMP_PREFIX}-single-keyframe-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].segments == []' "${TMP_PREFIX}-single-keyframe-report.json" >/dev/null

jq '.tracks = [
  .tracks[0],
  (.tracks[0] | .track_id = "object-main" | .target_type = "object" | .target_id = "object-a" | .property = "visibility" | .interpolation = "linear" | .keyframes = [{"frame": 1, "visibility": true}, {"frame": 120, "visibility": false}])
]' "$json_plan" >"${TMP_PREFIX}-two-tracks.json"
run_planner "${TMP_PREFIX}-two-tracks.json" >"${TMP_PREFIX}-two-tracks-report.json"
jq -e '.timeline_plan.tracks[0].track_id == "camera-main" and .timeline_plan.tracks[1].track_id == "object-main"' "${TMP_PREFIX}-two-tracks-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].sequence == 0 and .timeline_plan.tracks[1].sequence == 1' "${TMP_PREFIX}-two-tracks-report.json" >/dev/null
jq -e '.timeline_plan.tracks[1].keyframes[0].values.visibility == true and .timeline_plan.tracks[1].keyframes[1].values.visibility == false' "${TMP_PREFIX}-two-tracks-report.json" >/dev/null
jq -e '.timeline_plan.summary.track_count == 2 and .timeline_plan.summary.keyframe_count == 4 and .timeline_plan.summary.segment_count == 2' "${TMP_PREFIX}-two-tracks-report.json" >/dev/null
jq -e '.timeline_plan.summary.target_types == ["camera","object"]' "${TMP_PREFIX}-two-tracks-report.json" >/dev/null
jq -e '.timeline_plan.summary.properties == ["transform","visibility"]' "${TMP_PREFIX}-two-tracks-report.json" >/dev/null
jq -e '.timeline_plan.summary.interpolations == ["bezier","linear"]' "${TMP_PREFIX}-two-tracks-report.json" >/dev/null

jq -e '.timeline_plan.tracks[0].keyframes[0].values | has("frame") | not' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].keyframes[0].values.location == [4.0, -4.0, 3.0]' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].keyframes[0].values | has("scale") | not' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].keyframes | length == 2' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.tracks[0].segments | length == 1' "${TMP_PREFIX}-yaml-report.json" >/dev/null

jq -e '.timeline_plan.planned_outputs.preview_enabled == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.planned_outputs.preview_relative_runtime_path == "media/animation/previews/camera-orbit-demo.mp4"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.timeline_plan.planned_outputs.metadata_relative_runtime_path == "media/animation/metadata/camera-orbit-demo.json"' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.safety_flags.read_only == true' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.safety_flags.source_assets_modified == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.safety_flags.preview_render_attempted == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.safety_flags.external_process_started == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.safety_flags.interpolation_evaluated == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null
jq -e '.safety_flags.keyframes_written == false' "${TMP_PREFIX}-yaml-report.json" >/dev/null

jq '.timeline.end_frame = 1' "$json_plan" >"${TMP_PREFIX}-invalid-plan.json"
invalid_status=0
run_planner "${TMP_PREFIX}-invalid-plan.json" >"${TMP_PREFIX}-invalid-report.json" || invalid_status=$?
if [ "$invalid_status" -ne 1 ]; then
  echo "invalid planner input expected exit 1, got $invalid_status" >&2
  exit 1
fi
jq -e '.planned == false and .status == "invalid" and .timeline_plan == null' "${TMP_PREFIX}-invalid-report.json" >/dev/null
jq -e 'any(.errors[]; .code == "timeline_invalid_range")' "${TMP_PREFIX}-invalid-report.json" >/dev/null

cat >"${TMP_PREFIX}-malformed.json" <<'JSON'
{"schema_version": "1.0",
JSON
malformed_status=0
run_planner "${TMP_PREFIX}-malformed.json" >"${TMP_PREFIX}-malformed-report.json" || malformed_status=$?
if [ "$malformed_status" -ne 2 ]; then
  echo "malformed planner input expected exit 2, got $malformed_status" >&2
  exit 1
fi
jq -e '.planned == false and .status == "invalid" and .timeline_plan == null' "${TMP_PREFIX}-malformed-report.json" >/dev/null
jq -e 'any(.errors[]; .code == "malformed_json")' "${TMP_PREFIX}-malformed-report.json" >/dev/null

validator_status=0
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --plan "${TMP_PREFIX}-invalid-plan.json" >/dev/null || validator_status=$?
if [ "$validator_status" -ne 1 ]; then
  echo "validator reuse check expected validator exit 1, got $validator_status" >&2
  exit 1
fi

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/media-worker/app" "$PYTHON_BIN" - "$json_plan" <<'PY'
import copy
import json
import sys
from pathlib import Path

from animation_timeline_planner import (
    build_timeline_keyframe_plan,
    canonical_plan_hash,
    frame_to_normalized_progress,
    frame_to_time_seconds,
)

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
before = copy.deepcopy(payload)
result = build_timeline_keyframe_plan(payload)
assert result.valid, result.issues
assert payload == before
assert len(canonical_plan_hash(payload)) == 64
assert canonical_plan_hash(payload) == canonical_plan_hash(before)
assert frame_to_time_seconds(1, 1, 24) == 0.0
assert frame_to_normalized_progress(120, 1, 120) == 1.0
assert result.plan["tracks"][0]["keyframes"][0]["values"]["location"] == [4.0, -4.0, 3.0]
PY

if grep -E 'timestamp|uuid|mtime|cwd|environment|/home/cuneyt/DiskD|/home/cuneyt/MoE/runtime|MoE_Models_Backup|Traceback|File "' "${TMP_PREFIX}-yaml-report.json" >/dev/null; then
  echo "planner output leaked nondeterministic metadata or host paths" >&2
  exit 1
fi

if [ -e "$RUNTIME_PROBE" ]; then
  echo "planner wrote or touched animation runtime probe path" >&2
  exit 1
fi

if grep -R '^import bpy\|from bpy\|subprocess\|ffmpeg\|render-preview\|execute-animation\|REAL_ANIMATION_GENERATION\|sample-frames' "$PLANNER" >/dev/null; then
  echo "planner contains forbidden Blender/render/process execution surface" >&2
  exit 1
fi

if rg -n "REAL_ANIMATION_GENERATION|execute-animation|render-preview" apps/media-worker/app configs/animation >/dev/null; then
  echo "M36.7 guarded Blender animation implementation appears to have started" >&2
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

echo "Animation timeline planner OK"
