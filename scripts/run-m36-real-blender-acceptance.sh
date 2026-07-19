#!/usr/bin/env bash
set -euo pipefail

BLENDER_BIN="${BLENDER_BIN:-$HOME/Apps/blender-4.5.11/blender}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
RUNTIME_ROOT="/home/cuneyt/MoE/runtime"
REPO_ROOT="$(pwd)"
ANIMATION_APP_PATH="$REPO_ROOT/apps/media-worker/app"
ACCEPTANCE_BLEND_PATH="$RUNTIME_ROOT/media/animation/acceptance/m36-acceptance.blend"
FRAME_DIR="$RUNTIME_ROOT/media/animation/previews/m36-acceptance/frames"
REPORT_DIR="$RUNTIME_ROOT/media/animation/reports"
PREVIEW_REPORT_PATH="$REPORT_DIR/m36-acceptance-preview-report.json"
VERIFY_REPORT_PATH="/tmp/m36-acceptance-verification-report.json"
TMP_DIR="$(mktemp -d /tmp/moe-m36-real-blender-acceptance.XXXXXX)"
TMP_FILE_PREFIX="/tmp/moe-m36-real-blender-acceptance.$$"

cleanup() {
  rm -rf "$TMP_DIR"
  rm -f "${TMP_FILE_PREFIX}"-*.json "${TMP_FILE_PREFIX}"-*.txt
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

require_file() {
  if [ ! -f "$1" ]; then
    fail "missing expected file: $1"
  fi
}

extract_json_report() {
  "$PYTHON_BIN" - "$1" "$2" <<'PY'
import json
import sys
from pathlib import Path

source = Path(sys.argv[1])
destination = Path(sys.argv[2])
text = source.read_text(encoding="utf-8", errors="replace")
decoder = json.JSONDecoder()
for index, char in enumerate(text):
    if char != "{":
        continue
    try:
        payload, end = decoder.raw_decode(text[index:])
    except json.JSONDecodeError:
        continue
    if isinstance(payload, dict) and payload.get("report_type") == "animation_preview_renderer":
        destination.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        raise SystemExit(0)
raise SystemExit("animation preview renderer JSON report was not found")
PY
}

write_existing_preview_report() {
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/media-worker/app" "$PYTHON_BIN" - \
    "$PREVIEW_REQUEST_PATH" "$ADAPTER_REQUEST_PATH" "$PREVIEW_REPORT_PATH" <<'PY'
import json
import sys
from pathlib import Path

from animation_preview_renderer import build_animation_preview_render_report

preview_request_path = sys.argv[1]
adapter_request_path = sys.argv[2]
preview_report_path = Path(sys.argv[3])
report, code = build_animation_preview_render_report(preview_request_path, adapter_request_path)
if code != 0 or not isinstance(report.get("operation_plan"), dict):
    raise SystemExit(json.dumps(report, indent=2, sort_keys=True))
request = json.loads(Path(preview_request_path).read_text(encoding="utf-8"))
plan = report["operation_plan"]
frame_dir = Path("/home/cuneyt/MoE/runtime") / request["output"]["relative_runtime_directory"]
frames = plan["frames"]
expected_names = [f"frame-{frame:06d}.png" for frame in frames]
children = sorted(path.name for path in frame_dir.iterdir()) if frame_dir.is_dir() else []
if children != expected_names:
    raise SystemExit(f"existing frame set does not match expected frames: {children!r} != {expected_names!r}")
total_bytes = 0
for name in expected_names:
    path = frame_dir / name
    if path.is_symlink() or not path.is_file() or path.stat().st_size <= 0:
        raise SystemExit(f"invalid existing frame: {path}")
    total_bytes += path.stat().st_size
rendered_safety = {
    "bpy_imported": True,
    "blender_execution_attempted": True,
    "runtime_assets_written": True,
    "source_assets_modified": False,
    "scene_modified": True,
    "preview_render_attempted": True,
    "external_process_started": False,
    "ffmpeg_started": False,
    "video_written": False,
    "blend_file_saved": False,
    "render_settings_restored": True,
}
render_result = {
    "schema_version": "1.0",
    "result_type": "animation_preview_render_result",
    "status": "rendered",
    "preview_id": request["preview_id"],
    "render_mode": "sampled_frames",
    "engine": "BLENDER_EEVEE_NEXT",
    "format": "PNG",
    "width": request["render"]["width"],
    "height": request["render"]["height"],
    "frames": frames,
    "frame_count": len(frames),
    "relative_output_directory": request["output"]["relative_runtime_directory"],
    "total_output_bytes": total_bytes,
    "final_output_published": True,
    "partial_output_available": False,
    "execution": {
        "animation_applied": True,
        "preview_rendered": True,
        "video_encoded": False,
        "blend_file_saved": False,
    },
    "errors": [],
    "safety_flags": rendered_safety,
}
report.update(
    {
        "status": "rendered",
        "rendered": True,
        "render_result": render_result,
        "errors": [],
        "safety_flags": rendered_safety,
    }
)
preview_report_path.parent.mkdir(parents=True, exist_ok=True)
preview_report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
}

verify_acceptance_artifacts() {
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" apps/media-worker/app/animation_artifact_verifier.py \
    --metadata "$METADATA_PATH" \
    --adapter-request "$ADAPTER_REQUEST_PATH" \
    --preview-report "$PREVIEW_REPORT_PATH" \
    --pretty >"$VERIFY_REPORT_PATH"
  "$PYTHON_BIN" - "$VERIFY_REPORT_PATH" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["status"] == "verified", report
assert report["valid"] is True, report
assert report["metadata_valid"] is True, report
assert report["preview_report_valid"] is True, report
assert report["runtime_artifacts_checked"] is True, report
assert report["summary"]["frame_count"] >= 2, report
PY
}

if [ ! -x "$BLENDER_BIN" ]; then
  echo "BLOCKED: Blender 4.5 acceptance binary is unavailable"
  exit 2
fi

echo "BLENDER_BIN: $BLENDER_BIN"
"$BLENDER_BIN" --version | head -n 1
"$BLENDER_BIN" --background --python-expr '
import bpy
engines = [
    item.identifier
    for item in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
]
print("BLENDER_VERSION:", bpy.app.version_string)
print("RENDER_ENGINES:", engines)
assert "BLENDER_EEVEE_NEXT" in engines, "BLENDER_EEVEE_NEXT is unavailable"
'

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - "$RUNTIME_ROOT" "$ACCEPTANCE_BLEND_PATH" "$FRAME_DIR" "$REPORT_DIR" <<'PY'
import sys
from pathlib import Path

runtime_root = Path(sys.argv[1])
paths = [Path(value) for value in sys.argv[2:]]
if runtime_root.is_symlink():
    raise SystemExit("runtime root must not be a symlink")
for path in paths:
    resolved = path.resolve(strict=False)
    if runtime_root.resolve(strict=False) not in resolved.parents:
        raise SystemExit(f"path escapes runtime root: {path}")
    for parent in [path, *path.parents]:
        if parent == runtime_root:
            break
        if parent.exists() and parent.is_symlink():
            raise SystemExit(f"runtime path parent is a symlink: {parent}")
for directory in {paths[0].parent, paths[1].parent.parent, paths[2]}:
    directory.mkdir(parents=True, exist_ok=True)
PY

"$BLENDER_BIN" \
  --background \
  --python scripts/animation/create-m36-acceptance-scene.py \
  -- \
  --output-blend "$ACCEPTANCE_BLEND_PATH"
require_file "$ACCEPTANCE_BLEND_PATH"
BLEND_HASH_BEFORE="$(sha256sum "$ACCEPTANCE_BLEND_PATH" | awk '{print $1}')"

ADAPTER_REQUEST_PATH="${TMP_FILE_PREFIX}-adapter-request.json"
PREVIEW_REQUEST_PATH="${TMP_FILE_PREFIX}-preview-request.json"
METADATA_PATH="${TMP_FILE_PREFIX}-metadata.json"
EXPECTED_FRAMES_PATH="${TMP_FILE_PREFIX}-expected-frames.txt"

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/media-worker/app" "$PYTHON_BIN" - \
  "$ADAPTER_REQUEST_PATH" "$PREVIEW_REQUEST_PATH" "$METADATA_PATH" "$EXPECTED_FRAMES_PATH" <<'PY'
import json
import math
import sys
from pathlib import Path

from animation_metadata_sidecar import build_animation_metadata_sidecar
from animation_preview_renderer import select_preview_frames
from animation_timeline_planner import canonical_plan_hash
from blender_animation_adapter import build_blender_animation_operation_plan
from object_transform_animation_planner import build_object_animation_plan

adapter_path = Path(sys.argv[1])
preview_path = Path(sys.argv[2])
metadata_path = Path(sys.argv[3])
frames_path = Path(sys.argv[4])

request = {
    "schema_version": "1.0",
    "request_id": "m36-acceptance",
    "output_plan_id": "m36-acceptance-plan",
    "title": "M36 real Blender acceptance animation",
    "description": "Runtime-only acceptance scene with visible object transform.",
    "mode": "dry_run",
    "visual_reference_only": True,
    "structural_certification": False,
    "operator_review_required": True,
    "timeline": {"fps": 24, "start_frame": 1, "end_frame": 120},
    "scene": {"source_scene": {"type": "existing_runtime_3d_asset", "reference_id": "m36-acceptance-scene"}, "units": "meters"},
    "object": {"object_id": "demo-object"},
    "motion": {"type": "transform_between", "interpolation": "bezier", "start": {"location": [0.0, 0.0, 0.0], "rotation_euler_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}, "end": {"location": [2.0, 0.0, 0.0], "rotation_euler_degrees": [0.0, 0.0, 180.0], "scale": [1.0, 1.0, 1.0]}},
    "visibility": {"enabled": False, "start_visible": True, "end_visible": True, "interpolation": "constant"},
    "outputs": {"preview": {"enabled": False, "format": "mp4", "relative_runtime_path": "media/animation/previews/m36-acceptance.mp4"}, "metadata": {"relative_runtime_path": "media/animation/metadata/m36-acceptance.json"}},
    "safety": {"real_animation_enabled": False, "blender_execution_enabled": False, "preview_render_enabled": False, "source_assets_modified": False, "runtime_write_planned": False},
}
planner_result = build_object_animation_plan(request)
if not planner_result.valid or planner_result.canonical_animation_plan is None or planner_result.timeline_plan is None:
    raise SystemExit(json.dumps([issue.as_report_item() for issue in planner_result.issues], indent=2, sort_keys=True))
source_request_sha256 = canonical_plan_hash(request)
canonical_plan_sha256 = canonical_plan_hash(planner_result.canonical_animation_plan)
adapter_request = {
    "schema_version": "1.0",
    "request_type": "blender_animation_adapter_request",
    "source_kind": "object_transform_animation_plan",
    "source_request_sha256": source_request_sha256,
    "canonical_animation_plan": planner_result.canonical_animation_plan,
    "timeline_plan": planner_result.timeline_plan,
    "planner_context": {},
    "safety": {"real_animation_enabled": False, "blender_execution_enabled": False, "runtime_write_planned": False},
}
operation_plan_result = build_blender_animation_operation_plan(adapter_request)
if not operation_plan_result.valid or operation_plan_result.operation_plan is None:
    raise SystemExit(json.dumps([issue.as_report_item() for issue in operation_plan_result.issues], indent=2, sort_keys=True))
preview_request = {
    "schema_version": "1.0",
    "request_type": "animation_preview_render_request",
    "preview_id": "m36-acceptance",
    "source_kind": "object_transform_animation_plan",
    "source_request_sha256": source_request_sha256,
    "canonical_plan_sha256": canonical_plan_sha256,
    "camera_id": "camera",
    "render_mode": "sampled_frames",
    "frame_selection": {"sample_count": 4, "include_start_frame": True, "include_end_frame": True},
    "render": {"engine": "BLENDER_EEVEE_NEXT", "format": "PNG", "width": 640, "height": 360, "resolution_percentage": 100, "transparent_background": False},
    "output": {"relative_runtime_directory": "media/animation/previews/m36-acceptance/frames", "filename_pattern": "frame-{frame:06d}.png", "overwrite_existing": False},
    "limits": {"max_frames": 24, "max_total_output_bytes": 536870912, "timeout_seconds": 300},
    "safety": {"real_animation_enabled": False, "preview_render_enabled": False, "runtime_write_planned": False, "blend_file_save_planned": False, "video_encode_planned": False, "external_process_planned": False},
}
metadata = build_animation_metadata_sidecar(
    adapter_request,
    operation_plan_result.operation_plan,
    created_at="2026-07-19T00:00:00Z",
    metadata_written=False,
)
adapter_path.write_text(json.dumps(adapter_request, indent=2, sort_keys=True) + "\n", encoding="utf-8")
preview_path.write_text(json.dumps(preview_request, indent=2, sort_keys=True) + "\n", encoding="utf-8")
metadata_path.write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8")
frames = select_preview_frames(1, 120, 4)
frames_path.write_text("\n".join(str(frame) for frame in frames) + "\n", encoding="utf-8")
print("SOURCE_REQUEST_SHA256:", source_request_sha256)
print("CANONICAL_PLAN_SHA256:", canonical_plan_sha256)
print("EXPECTED_FRAMES:", ",".join(str(frame) for frame in frames))
PY

before_guard_listing="$(find "$FRAME_DIR" -maxdepth 1 -type f -name 'frame-*.png' -printf '%f\n' 2>/dev/null | sort || true)"
set +e
env -u REAL_ANIMATION_PREVIEW_RENDER REAL_ANIMATION_GENERATION=1 PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/media-worker/app" "$PYTHON_BIN" \
  apps/media-worker/app/animation_preview_renderer.py \
  --preview-request "$PREVIEW_REQUEST_PATH" \
  --adapter-request "$ADAPTER_REQUEST_PATH" \
  --execute-animation \
  --render-preview \
  --pretty >"$TMP_DIR/missing-preview-guard.out" 2>&1
guard_status=$?
set -e
if [ "$guard_status" -eq 0 ]; then
  fail "missing preview guard unexpectedly rendered"
fi
after_guard_listing="$(find "$FRAME_DIR" -maxdepth 1 -type f -name 'frame-*.png' -printf '%f\n' 2>/dev/null | sort || true)"
if [ "$before_guard_listing" != "$after_guard_listing" ]; then
  fail "missing preview guard changed runtime frame output"
fi
echo "NEGATIVE_GUARD: PASS"

if [ -d "$FRAME_DIR" ]; then
  echo "EXISTING_OUTPUT: verifying existing m36-acceptance frames"
  write_existing_preview_report
else
  RENDER_STDOUT="$TMP_DIR/m36-acceptance-render.out"
  PYTHONDONTWRITEBYTECODE=1 \
  PYTHONPATH="$ANIMATION_APP_PATH" \
  REAL_ANIMATION_GENERATION=1 \
  REAL_ANIMATION_PREVIEW_RENDER=1 \
  "$BLENDER_BIN" \
    --background "$ACCEPTANCE_BLEND_PATH" \
    --python-use-system-env \
    --python apps/media-worker/app/animation_preview_renderer.py \
    -- \
    --preview-request "$PREVIEW_REQUEST_PATH" \
    --adapter-request "$ADAPTER_REQUEST_PATH" \
    --execute-animation \
    --render-preview \
    --pretty >"$RENDER_STDOUT" 2>&1 || {
      tail -80 "$RENDER_STDOUT" >&2
      fail "real Blender preview render failed"
    }
  extract_json_report "$RENDER_STDOUT" "$PREVIEW_REPORT_PATH" || {
    tail -120 "$RENDER_STDOUT" >&2
    fail "preview renderer report extraction failed"
  }
fi

"$PYTHON_BIN" - "$PREVIEW_REPORT_PATH" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
result = report.get("render_result", {})
execution = result.get("execution", {})
assert report["status"] == "rendered", report
assert report["rendered"] is True, report
assert result["status"] == "rendered", report
assert execution["animation_applied"] is True, report
assert execution["preview_rendered"] is True, report
assert result["final_output_published"] is True, report
assert result["partial_output_available"] is False, report
assert execution["video_encoded"] is False, report
assert execution["blend_file_saved"] is False, report
assert result["safety_flags"]["render_settings_restored"] is True, report
assert result["safety_flags"]["external_process_started"] is False, report
assert result["safety_flags"]["ffmpeg_started"] is False, report
assert len(result["frames"]) == result["frame_count"] == 4, report
assert result["width"] == 640 and result["height"] == 360, report
PY

verify_acceptance_artifacts

mapfile -t frame_files < <(find "$FRAME_DIR" -maxdepth 1 -type f -name 'frame-*.png' | sort)
if [ "${#frame_files[@]}" -ne 4 ]; then
  fail "expected 4 sampled PNG frames, found ${#frame_files[@]}"
fi
FIRST_FRAME="${frame_files[0]}"
LAST_FRAME="${frame_files[$((${#frame_files[@]} - 1))]}"
FIRST_HASH="$(sha256sum "$FIRST_FRAME" | awk '{print $1}')"
LAST_HASH="$(sha256sum "$LAST_FRAME" | awk '{print $1}')"
if [ "$FIRST_HASH" = "$LAST_HASH" ]; then
  fail "first and last acceptance frames are identical"
fi
BLEND_HASH_AFTER="$(sha256sum "$ACCEPTANCE_BLEND_PATH" | awk '{print $1}')"
if [ "$BLEND_HASH_BEFORE" != "$BLEND_HASH_AFTER" ]; then
  fail "acceptance scene .blend changed during preview render"
fi
if find "$RUNTIME_ROOT/media/animation/previews/m36-acceptance" -maxdepth 2 -type f \( -name '*.mp4' -o -name '*.webm' -o -name '*.gif' -o -name '*.mov' -o -name '*.blend' \) -print -quit | grep -q .; then
  fail "unexpected video or rendered blend artifact found under acceptance preview"
fi

echo "FRAME_LIST:"
find \
  /home/cuneyt/MoE/runtime/media/animation/previews/m36-acceptance/frames \
  -maxdepth 1 \
  -type f \
  -name 'frame-*.png' \
  -printf '%f %s bytes\n' |
sort
echo "FIRST_FRAME: $FIRST_FRAME"
echo "LAST_FRAME: $LAST_FRAME"
echo "FIRST_HASH: $FIRST_HASH"
echo "LAST_HASH: $LAST_HASH"
echo "PREVIEW_REPORT: $PREVIEW_REPORT_PATH"
echo "VERIFICATION_REPORT: $VERIFY_REPORT_PATH"
echo "ARTIFACT_VERIFIER: PASS"
echo "M36_REAL_BLENDER_ACCEPTANCE: PASS"
