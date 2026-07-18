#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
ADAPTER="apps/media-worker/app/blender_animation_adapter.py"
SCHEMA="configs/animation/blender-animation-adapter-request.schema.json"
EXAMPLE="configs/animation/blender-animation-adapter-request.example.json"
TMP_PREFIX="/tmp/moe-blender-animation-adapter.$$"
RUNTIME_PROBE="/home/cuneyt/MoE/runtime/media/animation/m36-7-runtime-write-probe"

cleanup() {
  rm -f "${TMP_PREFIX}"*.json
}
trap cleanup EXIT

for path in "$ADAPTER" "$SCHEMA" "$EXAMPLE"; do
  if [ ! -f "$path" ]; then
    echo "missing Blender animation adapter file: $path" >&2
    exit 1
  fi
done

jq empty "$SCHEMA"
jq empty "$EXAMPLE"
jq -e '.schema_version == "1.0"' "$EXAMPLE" >/dev/null
jq -e '.request_type == "blender_animation_adapter_request"' "$EXAMPLE" >/dev/null
jq -e '.source_kind == "object_transform_animation_plan"' "$EXAMPLE" >/dev/null
jq -e '.safety.real_animation_enabled == false' "$EXAMPLE" >/dev/null
jq -e '.safety.blender_execution_enabled == false' "$EXAMPLE" >/dev/null
jq -e '.safety.runtime_write_planned == false' "$EXAMPLE" >/dev/null
jq -e '.planner_context == {}' "$EXAMPLE" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$ADAPTER" --adapter-request "$EXAMPLE" --pretty >"${TMP_PREFIX}-report.json"
jq -e '.report_type == "blender_animation_adapter"' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.status == "planned" and .planned == true and .executed == false' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.operation_plan.plan_type == "blender_animation_operation_plan"' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.operation_plan.operation_count == (.operation_plan.operations | length)' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.operation_plan.operations[0].operation_type == "configure_scene_timeline"' "${TMP_PREFIX}-report.json" >/dev/null
jq -e 'all(.operation_plan.operations[] | select(.operation_type == "resolve_target"); .required == true and .create_if_missing == false)' "${TMP_PREFIX}-report.json" >/dev/null
jq -e 'any(.operation_plan.operations[]; .operation_type == "set_rotation_mode" and .rotation_mode == "XYZ")' "${TMP_PREFIX}-report.json" >/dev/null
jq -e 'any(.operation_plan.operations[]; .operation_type == "set_transform_values")' "${TMP_PREFIX}-report.json" >/dev/null
jq -e 'any(.operation_plan.operations[]; .operation_type == "insert_transform_keyframe" and .data_path == "location")' "${TMP_PREFIX}-report.json" >/dev/null
jq -e 'any(.operation_plan.operations[]; .operation_type == "insert_transform_keyframe" and .data_path == "rotation_euler")' "${TMP_PREFIX}-report.json" >/dev/null
jq -e 'any(.operation_plan.operations[]; .operation_type == "insert_transform_keyframe" and .data_path == "scale")' "${TMP_PREFIX}-report.json" >/dev/null
jq -e 'any(.operation_plan.operations[]; .operation_type == "set_fcurve_interpolation" and .interpolation == "BEZIER")' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.safety_flags.bpy_imported == false' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.safety_flags.source_assets_modified == false' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.safety_flags.keyframes_written == false' "${TMP_PREFIX}-report.json" >/dev/null
jq -e '.safety_flags.scene_modified == false' "${TMP_PREFIX}-report.json" >/dev/null

set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$ADAPTER" --adapter-request "$EXAMPLE" --execute-animation >"${TMP_PREFIX}-guard-report.json"
guard_exit=$?
set -e
if [ "$guard_exit" -ne 2 ]; then
  echo "--execute-animation without REAL_ANIMATION_GENERATION=1 should exit 2" >&2
  exit 1
fi
jq -e '.status == "guard_blocked" and .planned == true and .executed == false' "${TMP_PREFIX}-guard-report.json" >/dev/null

REAL_ANIMATION_GENERATION=1 PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$ADAPTER" --adapter-request "$EXAMPLE" >"${TMP_PREFIX}-env-only-report.json"
jq -e '.status == "planned" and .executed == false' "${TMP_PREFIX}-env-only-report.json" >/dev/null

set +e
REAL_ANIMATION_GENERATION=1 PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$ADAPTER" --adapter-request "$EXAMPLE" --execute-animation >"${TMP_PREFIX}-missing-bpy-report.json"
missing_bpy_exit=$?
set -e
if [ "$missing_bpy_exit" -ne 2 ]; then
  echo "guarded execution outside Blender should exit 2" >&2
  exit 1
fi
jq -e '.status == "blender_unavailable" and .executed == false' "${TMP_PREFIX}-missing-bpy-report.json" >/dev/null

jq '.timeline_plan.source_plan_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "$EXAMPLE" >"${TMP_PREFIX}-bad-hash.json"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$ADAPTER" --adapter-request "${TMP_PREFIX}-bad-hash.json" >"${TMP_PREFIX}-bad-hash-report.json"
bad_hash_exit=$?
set -e
if [ "$bad_hash_exit" -ne 1 ]; then
  echo "bad timeline hash should exit 1" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("canonical_plan_hash_mismatch")' "${TMP_PREFIX}-bad-hash-report.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - <<'PY'
import ast
from pathlib import Path

tree = ast.parse(Path("apps/media-worker/app/blender_animation_adapter.py").read_text(encoding="utf-8"))
module_imports = []
local_bpy_imports = []
for node in ast.walk(tree):
    if isinstance(node, (ast.Import, ast.ImportFrom)):
        names = [alias.name for alias in getattr(node, "names", [])]
        module = getattr(node, "module", None)
        if any(name == "bpy" or name.startswith("bpy.") or name == "mathutils" or name.startswith("mathutils.") for name in names) or module in {"bpy", "mathutils"}:
            parent_name = None
            for parent in ast.walk(tree):
                for child in ast.iter_child_nodes(parent):
                    if child is node and isinstance(parent, ast.FunctionDef):
                        parent_name = parent.name
            if parent_name is None:
                module_imports.append((node.lineno, names, module))
            elif parent_name == "execute_blender_animation_operation_plan" and names == ["bpy"]:
                local_bpy_imports.append(node.lineno)
assert not module_imports, module_imports
assert local_bpy_imports, "bpy import must exist only inside guarded public execution function"
PY

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - <<'PY'
import json
import sys
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, "apps/media-worker/app")
from blender_animation_adapter import (  # noqa: E402
    _execute_with_bpy_module,
    build_blender_animation_adapter_report,
)

report, exit_code = build_blender_animation_adapter_report("configs/animation/blender-animation-adapter-request.example.json")
assert exit_code == 0, report
plan = report["operation_plan"]

class KeyPoint:
    def __init__(self):
        self.interpolation = "UNSET"

class FCurve:
    def __init__(self, data_path):
        self.data_path = data_path
        self.keyframe_points = [KeyPoint()]

class FakeTarget:
    def __init__(self):
        self.type = "MESH"
        self.rotation_mode = ""
        self.location = [99, 99, 99]
        self.rotation_euler = [99, 99, 99]
        self.scale = [99, 99, 99]
        self.hide_viewport = False
        self.hide_render = False
        self.animation_data = SimpleNamespace(action=SimpleNamespace(fcurves=[]))
        self.inserted = []

    def keyframe_insert(self, *, data_path, frame):
        self.inserted.append((data_path, frame))
        self.animation_data.action.fcurves.append(FCurve(data_path))

target = FakeTarget()
scene = SimpleNamespace(render=SimpleNamespace(fps=0), frame_start=0, frame_end=0)
bpy = SimpleNamespace(context=SimpleNamespace(scene=scene), data=SimpleNamespace(objects={"demo-object": target}))
result, exec_exit = _execute_with_bpy_module(plan, bpy)
assert exec_exit == 0, result
assert result["status"] == "executed"
assert result["operations_applied"] == plan["operation_count"]
assert result["keyframe_insert_count"] == 6
assert result["interpolation_update_count"] == 6
assert scene.render.fps == 24 and scene.frame_start == 1 and scene.frame_end == 120
assert target.rotation_mode == "XYZ"
assert target.location == [2.0, 0.0, 1.0]
assert target.rotation_euler == [0.0, 0.0, 1.570796327]
assert target.scale == [1.0, 1.0, 1.0]
assert result["safety_flags"]["bpy_imported"] is True
assert result["safety_flags"]["blender_execution_attempted"] is True
assert result["safety_flags"]["keyframes_written"] is True
assert result["safety_flags"]["scene_modified"] is True
assert result["safety_flags"]["runtime_assets_written"] is False
assert result["safety_flags"]["preview_render_attempted"] is False
assert result["safety_flags"]["blend_file_saved"] is False
PY

before_mtime="missing"
if [ -e "$RUNTIME_PROBE" ]; then
  before_mtime="$(stat -c %Y "$RUNTIME_PROBE")"
fi
after_mtime="missing"
if [ -e "$RUNTIME_PROBE" ]; then
  after_mtime="$(stat -c %Y "$RUNTIME_PROBE")"
fi
if [ "$before_mtime" != "$after_mtime" ]; then
  echo "adapter wrote or touched animation runtime probe path" >&2
  exit 1
fi

if grep -R '^import bpy\|from bpy\|mathutils\|subprocess\|render-preview' "$ADAPTER" >/dev/null; then
  echo "adapter contains forbidden import or execution surface" >&2
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

echo "Blender animation adapter OK"
