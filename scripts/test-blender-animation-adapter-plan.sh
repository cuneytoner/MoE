#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
PLAN_DOC="docs/ops/289-blender-animation-adapter-plan.md"
REVIEW_DOC="docs/ops/290-blender-animation-adapter-plan-review-template.md"
EXAMPLE="configs/animation/blender-animation-operation-plan.example.json"
MILESTONES="docs/milestones.md"

for path in "$PLAN_DOC" "$REVIEW_DOC" "$EXAMPLE" "$MILESTONES"; do
  if [ ! -f "$path" ]; then
    echo "missing Blender animation adapter plan file: $path" >&2
    exit 1
  fi
done

jq empty "$EXAMPLE"
jq -e '.schema_version == "1.0"' "$EXAMPLE" >/dev/null
jq -e '.plan_type == "blender_animation_operation_plan"' "$EXAMPLE" >/dev/null
jq -e '.status == "planned"' "$EXAMPLE" >/dev/null
jq -e '.operation_count == (.operations | length)' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.bpy_imported == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.source_assets_modified == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.keyframes_written == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.scene_modified == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.external_process_started == false' "$EXAMPLE" >/dev/null

jq -e '.operations[0].operation_type == "configure_scene_timeline"' "$EXAMPLE" >/dev/null
jq -e '.operations[0].operation_id == "configure-scene-timeline"' "$EXAMPLE" >/dev/null
jq -e '.operations[0].fps == 24 and .operations[0].start_frame == 1 and .operations[0].end_frame == 120' "$EXAMPLE" >/dev/null
jq -e 'all(.operations[] | select(.operation_type == "resolve_target"); .required == true and .create_if_missing == false)' "$EXAMPLE" >/dev/null
jq -e 'all(.operations[] | select(.operation_type == "set_rotation_mode"); .rotation_mode == "XYZ")' "$EXAMPLE" >/dev/null
jq -e 'all(.operations[] | select(.operation_type == "set_camera_lens"); .animated == false and .lens_mm >= 1 and .lens_mm <= 300 and .target_type == "camera")' "$EXAMPLE" >/dev/null
jq -e 'all(.operations[] | select(.operation_type == "insert_transform_keyframe"); (.data_path == "location" or .data_path == "rotation_euler" or .data_path == "scale"))' "$EXAMPLE" >/dev/null
jq -e 'all(.operations[] | select(.operation_type == "set_visibility_value"); .blender_properties == ["hide_viewport","hide_render"])' "$EXAMPLE" >/dev/null
jq -e 'all(.operations[] | select(.operation_type == "insert_visibility_keyframe"); .data_paths == ["hide_viewport","hide_render"])' "$EXAMPLE" >/dev/null
jq -e 'all(.operations[] | select(.operation_type == "set_fcurve_interpolation"); (.interpolation == "CONSTANT" or .interpolation == "LINEAR" or .interpolation == "BEZIER"))' "$EXAMPLE" >/dev/null
jq -e 'all(.operations[]; .operation_id | test("^[a-z0-9][a-z0-9-]*$"))' "$EXAMPLE" >/dev/null
jq -e '(.operations | map(.operation_id) | length) == (.operations | map(.operation_id) | unique | length)' "$EXAMPLE" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - "$EXAMPLE" <<'PY'
import json
import sys
from pathlib import Path

allowed = {
    "configure_scene_timeline",
    "resolve_target",
    "set_rotation_mode",
    "set_camera_lens",
    "set_transform_values",
    "set_visibility_value",
    "insert_transform_keyframe",
    "insert_visibility_keyframe",
    "set_fcurve_interpolation",
}
forbidden = {
    "create_object",
    "delete_object",
    "rename_object",
    "duplicate_object",
    "import_asset",
    "export_asset",
    "save_blend",
    "render_frame",
    "render_animation",
    "run_ffmpeg",
    "execute_python",
    "run_operator",
    "run_shell",
}
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
types = {operation["operation_type"] for operation in payload["operations"]}
assert types <= allowed, sorted(types - allowed)
assert not (types & forbidden), sorted(types & forbidden)
assert payload["operation_types"] == sorted(types), payload["operation_types"]
PY

grep -q "Adapter Input Envelope" "$PLAN_DOC"
grep -q "camera_animation_plan" "$PLAN_DOC"
grep -q "object_transform_animation_plan" "$PLAN_DOC"
grep -q "M36.2 validation" "$PLAN_DOC"
grep -q "M36.3 timeline/keyframe planner" "$PLAN_DOC"
grep -q "configure_scene_timeline" "$PLAN_DOC"
grep -q "resolve_target" "$PLAN_DOC"
grep -q "set_rotation_mode" "$PLAN_DOC"
grep -q "set_camera_lens" "$PLAN_DOC"
grep -q "set_transform_values" "$PLAN_DOC"
grep -q "set_visibility_value" "$PLAN_DOC"
grep -q "insert_transform_keyframe" "$PLAN_DOC"
grep -q "insert_visibility_keyframe" "$PLAN_DOC"
grep -q "set_fcurve_interpolation" "$PLAN_DOC"
grep -q "create_if_missing" "$PLAN_DOC"
grep -q "create_if_missing.*false" "$PLAN_DOC"
grep -q "Target creation" "$PLAN_DOC" || grep -q "must not create" "$PLAN_DOC"
grep -q "rotation_mode.*XYZ" "$PLAN_DOC"
grep -q "animated.*false" "$PLAN_DOC"
grep -q "location" "$PLAN_DOC"
grep -q "rotation_euler" "$PLAN_DOC"
grep -q "scale" "$PLAN_DOC"
grep -q "visible=true" "$PLAN_DOC"
grep -q "hide_viewport=false" "$PLAN_DOC"
grep -q "hide_render=false" "$PLAN_DOC"
grep -q "constant -> CONSTANT" "$PLAN_DOC"
grep -q "linear   -> LINEAR" "$PLAN_DOC"
grep -q "bezier   -> BEZIER" "$PLAN_DOC"
grep -q "REAL_ANIMATION_GENERATION=1" "$PLAN_DOC"
grep -q -- "--execute-animation" "$PLAN_DOC"
grep -q "bpy.*module level" "$PLAN_DOC"
grep -q "guarded execution function" "$PLAN_DOC"
grep -q "M36.7 is implemented separately by 291 and 292" "$PLAN_DOC"

for heading in \
  "Repository State" \
  "M35 Adapter Lessons" \
  "Adapter Input Envelope" \
  "Canonical Plan Requirement" \
  "Timeline Plan Requirement" \
  "Planner Context" \
  "Target Resolution" \
  "Operation Allowlist" \
  "Operation Ordering" \
  "Timeline Setup" \
  "Rotation Mode" \
  "Camera Lens" \
  "Transform Values" \
  "Transform Keyframes" \
  "Visibility Mapping" \
  "Visibility Keyframes" \
  "Interpolation Mapping" \
  "Operation Ids" \
  "Preflight" \
  "Failure Handling" \
  "Execution Guards" \
  "Blender Import Boundary" \
  "Runtime Write Boundary" \
  "M36.7 Contract" \
  "Regression Results" \
  "Final Decision"; do
  grep -q "## $heading" "$REVIEW_DOC"
done

grep -q -- "- M36.5 Object Transform Animation Planner DONE" "$MILESTONES"
grep -q -- "- M36.6 Blender Animation Adapter Plan DONE" "$MILESTONES"
grep -q -- "- M36.7 Guarded Blender Animation Implementation DONE" "$MILESTONES"
grep -q -- "- M36.8 Animation Metadata Sidecar Writer DONE" "$MILESTONES"
grep -q -- "- M36.9 Animation Metadata Validator DONE" "$MILESTONES"
grep -q -- "- M36.10 Preview Render Safety Plan PLANNED" "$MILESTONES"

if [ -e "apps/media-worker/app/animation_blender_adapter.py" ]; then
  echo "unexpected alternate Blender animation adapter implementation found" >&2
  exit 1
fi

if grep -R '^import bpy\|from bpy\|mathutils' apps/media-worker/app configs/animation --exclude='blender_animation_adapter.py' >/dev/null; then
  echo "new animation layer contains forbidden Blender import surface" >&2
  exit 1
fi

if grep -R "preview_render_safety\|render_preview_plan\|--render-preview" apps/media-worker/app configs/animation >/dev/null; then
  echo "M36.10+ animation preview behavior appears to have started in app/config source" >&2
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

echo "Blender animation adapter plan OK"
