#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
SCRIPT="apps/media-worker/app/animation_metadata_sidecar.py"
ADAPTER="apps/media-worker/app/blender_animation_adapter.py"
EXAMPLE="configs/animation/blender-animation-adapter-request.example.json"
TMP_DIR="$(mktemp -d /tmp/moe-animation-metadata.XXXXXX)"
TMP_FILE_PREFIX="/tmp/moe-animation-metadata-writer.$$"

cleanup() {
  rm -rf "$TMP_DIR"
  rm -f "${TMP_FILE_PREFIX}"*.json
}
trap cleanup EXIT

for path in "$SCRIPT" "$ADAPTER" "$EXAMPLE"; do
  if [ ! -f "$path" ]; then
    echo "missing animation metadata writer dependency: $path" >&2
    exit 1
  fi
done

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$SCRIPT" --adapter-request "$EXAMPLE" --pretty >"$TMP_DIR/report.json"
jq -e '.report_type == "animation_metadata_sidecar_writer"' "$TMP_DIR/report.json" >/dev/null
jq -e '.status == "planned" and .metadata_path == null' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.schema_version == "1.0"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.metadata_type == "animation_sidecar" and .metadata.asset_type == "animation"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.source == "blender_animation_adapter"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.generator_script == "apps/media-worker/app/animation_metadata_sidecar.py"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.generator_version == "0.1.0"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.animation_id == "object-transform-demo-plan"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.title == "Move and rotate a static object"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.created_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.source_request_sha256 | test("^[a-f0-9]{64}$")' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.adapter_request_sha256 | test("^[a-f0-9]{64}$")' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.canonical_plan_sha256 | test("^[a-f0-9]{64}$")' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.operation_plan_sha256 | test("^[a-f0-9]{64}$")' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.timeline == {"duration_seconds":5,"end_frame":120,"fps":24,"start_frame":1,"total_frames":120}' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.animation_summary.track_count == 1' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.animation_summary.keyframe_count == 2' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.animation_summary.segment_count == 1' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.animation_summary.target_types == ["object"]' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.animation_summary.target_ids == ["demo-object"]' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.animation_summary.properties == ["transform"]' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.animation_summary.interpolations == ["bezier"]' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.adapter_summary.operation_count == 14' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.adapter_summary.operation_types == ["configure_scene_timeline","insert_transform_keyframe","resolve_target","set_fcurve_interpolation","set_rotation_mode","set_transform_values"]' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.adapter_summary.resolved_target_ids == ["demo-object"]' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.adapter_summary.execution_status == "not_executed"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.output_files.preview == "media/animation/previews/object-transform-demo.mp4"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.output_files.metadata == "media/animation/metadata/object-transform-demo.json"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.output_files.report == null' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.preview_available == false' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.visual_reference_only == true and .metadata.structural_certification == false and .metadata.operator_review_required == true' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.generation_mode == "metadata_only"' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.validation.adapter_request_valid == true and .metadata.validation.operation_plan_valid == true' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.safety_flags.metadata_written == false' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.safety_flags.runtime_assets_written == false' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.safety_flags.blender_execution_attempted == false' "$TMP_DIR/report.json" >/dev/null
jq -e '.metadata.safety_flags.preview_render_attempted == false' "$TMP_DIR/report.json" >/dev/null
jq -e '.safety_flags.metadata_written == false' "$TMP_DIR/report.json" >/dev/null
if grep -F "$PWD" "$TMP_DIR/report.json" >/dev/null || grep -F "/home/cuneyt/MoE/runtime" "$TMP_DIR/report.json" >/dev/null || grep -F "/home/cuneyt/MoE_Models_Backup" "$TMP_DIR/report.json" >/dev/null; then
  echo "writer report leaked absolute repo/runtime/model path" >&2
  exit 1
fi

test ! -e "$TMP_DIR/should-not-exist.json"

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - <<'PY'
import json
import sys

sys.path.insert(0, "apps/media-worker/app")
from animation_metadata_sidecar import (  # noqa: E402
    build_animation_metadata_sidecar,
    build_animation_metadata_writer_report,
)
from blender_animation_adapter import build_blender_animation_operation_plan, load_adapter_request  # noqa: E402

loaded = load_adapter_request("configs/animation/blender-animation-adapter-request.example.json")
plan = build_blender_animation_operation_plan(loaded.request).operation_plan
metadata = build_animation_metadata_sidecar(loaded.request, plan, created_at="2026-01-01T00:00:00Z")
assert metadata["created_at"] == "2026-01-01T00:00:00Z"
try:
    build_animation_metadata_sidecar(loaded.request, plan, created_at="not-a-date")
except ValueError:
    pass
else:
    raise AssertionError("invalid timestamp was accepted")
report, exit_code = build_animation_metadata_writer_report("configs/animation/blender-animation-adapter-request.example.json", created_at="2026-01-01T00:00:00Z")
assert exit_code == 0, report
assert report["metadata"]["created_at"] == "2026-01-01T00:00:00Z"
PY

jq '.timeline_plan.source_plan_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "$EXAMPLE" >"${TMP_FILE_PREFIX}-bad-hash.json"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$SCRIPT" --adapter-request "${TMP_FILE_PREFIX}-bad-hash.json" >"$TMP_DIR/bad-hash-report.json"
bad_hash_exit=$?
set -e
if [ "$bad_hash_exit" -ne 1 ]; then
  echo "hash mismatch should exit 1" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("canonical_plan_hash_mismatch")' "$TMP_DIR/bad-hash-report.json" >/dev/null

jq '.timeline_plan.timeline.total_frames = 999' "$EXAMPLE" >"${TMP_FILE_PREFIX}-timeline-mismatch.json"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$SCRIPT" --adapter-request "${TMP_FILE_PREFIX}-timeline-mismatch.json" >"$TMP_DIR/timeline-mismatch-report.json"
timeline_mismatch_exit=$?
set -e
if [ "$timeline_mismatch_exit" -ne 1 ]; then
  echo "timeline mismatch should exit 1" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("timeline_plan_mismatch")' "$TMP_DIR/timeline-mismatch-report.json" >/dev/null

printf '{' >"${TMP_FILE_PREFIX}-malformed.json"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$SCRIPT" --adapter-request "${TMP_FILE_PREFIX}-malformed.json" >"$TMP_DIR/malformed-report.json"
malformed_exit=$?
set -e
if [ "$malformed_exit" -ne 2 ]; then
  echo "malformed JSON should exit 2" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("malformed_json")' "$TMP_DIR/malformed-report.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$SCRIPT" --adapter-request "$EXAMPLE" --write-metadata "$TMP_DIR/written.json" --pretty >"$TMP_DIR/write-report.json"
test -f "$TMP_DIR/written.json"
jq -e '.status == "written" and .metadata_path == "'"$TMP_DIR"'/written.json"' "$TMP_DIR/write-report.json" >/dev/null
jq -e '.metadata.safety_flags.metadata_written == true' "$TMP_DIR/write-report.json" >/dev/null
jq -e '.safety_flags.metadata_written == true' "$TMP_DIR/write-report.json" >/dev/null
jq -e '.metadata_type == "animation_sidecar"' "$TMP_DIR/written.json" >/dev/null
jq -e '.safety_flags.metadata_written == true' "$TMP_DIR/written.json" >/dev/null
tail -c 1 "$TMP_DIR/written.json" | od -An -t x1 | grep -q '0a'

if find "$TMP_DIR" -name '*.tmp' -print -quit | grep -q .; then
  echo "atomic write left temporary residue" >&2
  exit 1
fi

for bad_path in \
  "relative.json" \
  "$PWD/bad.json" \
  "/home/cuneyt/MoE/runtime/media/animation/metadata/bad.json" \
  "/home/cuneyt/MoE_Models_Backup/bad.json" \
  "/mnt/bad.json" \
  "$TMP_DIR/bad.txt" \
  "$TMP_DIR/../bad.json"; do
  if PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$SCRIPT" --adapter-request "$EXAMPLE" --write-metadata "$bad_path" >/dev/null 2>&1; then
    echo "unsafe write path accepted: $bad_path" >&2
    exit 1
  fi
done

ln -s "$TMP_DIR/written.json" "$TMP_DIR/link.json"
if PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$SCRIPT" --adapter-request "$EXAMPLE" --write-metadata "$TMP_DIR/link.json" >/dev/null 2>&1; then
  echo "destination symlink was accepted" >&2
  exit 1
fi

mkdir "$TMP_DIR/real-parent"
ln -s "$TMP_DIR/real-parent" "$TMP_DIR/parent-link"
if PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$SCRIPT" --adapter-request "$EXAMPLE" --write-metadata "$TMP_DIR/parent-link/bad.json" >/dev/null 2>&1; then
  echo "parent symlink was accepted" >&2
  exit 1
fi

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - <<'PY'
import ast
from pathlib import Path

tree = ast.parse(Path("apps/media-worker/app/animation_metadata_sidecar.py").read_text(encoding="utf-8"))
for node in ast.walk(tree):
    if isinstance(node, (ast.Import, ast.ImportFrom)):
        names = [alias.name for alias in getattr(node, "names", [])]
        module = getattr(node, "module", None)
        blocked = {"bpy", "mathutils", "subprocess"}
        assert not (set(names) & blocked), (node.lineno, names)
        assert module not in blocked, (node.lineno, module)
text = Path("apps/media-worker/app/animation_metadata_sidecar.py").read_text(encoding="utf-8")
assert "execute_blender_animation_operation_plan" not in text
assert "render-preview" not in text
assert "ffmpeg" not in text
PY

if grep -R '^import bpy\|from bpy\|mathutils\|subprocess\|ffmpeg\|render-preview\|execute_blender_animation_operation_plan' "$SCRIPT" >/dev/null; then
  echo "writer contains forbidden Blender/execution surface" >&2
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

echo "Animation metadata sidecar writer OK"
