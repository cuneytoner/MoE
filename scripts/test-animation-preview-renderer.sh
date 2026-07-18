#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
RENDERER="apps/media-worker/app/animation_preview_renderer.py"
PREVIEW_SCHEMA="configs/animation/preview-render-request.schema.json"
PREVIEW_EXAMPLE="configs/animation/preview-render-request.example.json"
ADAPTER_EXAMPLE="configs/animation/blender-animation-adapter-request.example.json"
DOC="docs/ops/299-guarded-preview-render-implementation.md"
REVIEW="docs/ops/300-guarded-preview-render-implementation-review-template.md"
TMP_DIR="/tmp/moe-animation-preview-renderer.$$"
TMP_REQUEST="/tmp/moe-animation-preview-request.$$.json"
TMP_ADAPTER="/tmp/moe-animation-preview-adapter.$$.json"

cleanup() {
  rm -rf "$TMP_DIR"* "$TMP_REQUEST" "$TMP_ADAPTER"
}
trap cleanup EXIT

for path in "$RENDERER" "$PREVIEW_SCHEMA" "$PREVIEW_EXAMPLE" "$ADAPTER_EXAMPLE" "$DOC" "$REVIEW"; do
  if [ ! -f "$path" ]; then
    echo "missing animation preview renderer file: $path" >&2
    exit 1
  fi
done

jq empty "$PREVIEW_SCHEMA"
jq empty "$PREVIEW_EXAMPLE"

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" \
  --preview-request "$PREVIEW_EXAMPLE" \
  --adapter-request "$ADAPTER_EXAMPLE" \
  --pretty >"$TMP_DIR-plan-a.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" \
  --preview-request "$PREVIEW_EXAMPLE" \
  --adapter-request "$ADAPTER_EXAMPLE" \
  --pretty >"$TMP_DIR-plan-b.json"
cmp "$TMP_DIR-plan-a.json" "$TMP_DIR-plan-b.json" >/dev/null

jq -e '.report_type == "animation_preview_renderer"' "$TMP_DIR-plan-a.json" >/dev/null
jq -e '.status == "planned" and .planned == true and .rendered == false' "$TMP_DIR-plan-a.json" >/dev/null
jq -e '.operation_plan.plan_type == "animation_preview_render_operation_plan"' "$TMP_DIR-plan-a.json" >/dev/null
jq -e '.operation_plan.frames == [1,18,35,52,69,86,103,120]' "$TMP_DIR-plan-a.json" >/dev/null
jq -e '.operation_plan.operation_types == ["validate_preview_request","validate_adapter_request","resolve_camera","select_preview_frames","validate_output_directory","snapshot_render_settings","apply_animation_operations","configure_preview_render","render_preview_frame","verify_preview_frame","restore_render_settings","publish_preview_directory"]' "$TMP_DIR-plan-a.json" >/dev/null
jq -e '.operation_plan.operations[2].fallback_allowed == false and .operation_plan.operations[2].create_if_missing == false' "$TMP_DIR-plan-a.json" >/dev/null
jq -e '.safety_flags.bpy_imported == false and .safety_flags.runtime_assets_written == false and .safety_flags.preview_render_attempted == false' "$TMP_DIR-plan-a.json" >/dev/null

if grep -E 'timestamp|uuid|mtime|hostname|environment|/home/cuneyt/DiskD|/home/cuneyt/MoE/runtime|MoE_Models_Backup|Traceback|File "' "$TMP_DIR-plan-a.json" >/dev/null; then
  echo "plan-only report leaked nondeterministic metadata or host paths" >&2
  exit 1
fi

run_invalid() {
  local name="$1"
  local filter="$2"
  local code="$3"
  jq "$filter" "$PREVIEW_EXAMPLE" >"$TMP_REQUEST"
  set +e
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" \
    --preview-request "$TMP_REQUEST" \
    --adapter-request "$ADAPTER_EXAMPLE" >"$TMP_DIR-$name.json"
  local exit_code=$?
  set -e
  if [ "$exit_code" -ne 1 ]; then
    echo "$name should exit 1" >&2
    exit 1
  fi
  jq -e --arg code "$code" '.errors | map(.code) | index($code)' "$TMP_DIR-$name.json" >/dev/null
}

run_invalid "unknown" '.extra = true' "unknown_field"
run_invalid "missing" 'del(.camera_id)' "missing_required_field"
run_invalid "bad-preview-id" '.preview_id = "../bad"' "unsafe_identifier"
run_invalid "bad-camera-id" '.camera_id = "/camera"' "unsafe_identifier"
run_invalid "bad-kind" '.source_kind = "video_plan"' "enum_mismatch"
run_invalid "bad-source-hash" '.source_request_sha256 = "ABC"' "invalid_sha256"
run_invalid "bad-sample" '.frame_selection.sample_count = 1' "invalid_sample_count"
run_invalid "bad-engine" '.render.engine = "CYCLES"' "const_mismatch"
run_invalid "bad-format" '.render.format = "JPEG"' "const_mismatch"
run_invalid "bad-output" '.output.relative_runtime_directory = "/tmp/out"' "unsafe_output_path"
run_invalid "mismatch-output" '.output.relative_runtime_directory = "media/animation/previews/other-preview/frames"' "preview_output_mismatch"
run_invalid "bad-pattern" '.output.filename_pattern = "{frame}.png"' "const_mismatch"
run_invalid "overwrite" '.output.overwrite_existing = true' "const_mismatch"
run_invalid "pixel-budget" '.frame_selection.sample_count = 24 | .render.width = 1921' "invalid_resolution"

jq '.source_kind = "camera_animation_plan"' "$PREVIEW_EXAMPLE" >"$TMP_REQUEST"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$TMP_REQUEST" --adapter-request "$ADAPTER_EXAMPLE" >"$TMP_DIR-kind-mismatch.json"
kind_exit=$?
set -e
if [ "$kind_exit" -ne 1 ]; then
  echo "source kind mismatch should exit 1" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("source_kind_mismatch")' "$TMP_DIR-kind-mismatch.json" >/dev/null

jq '.source_request_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "$PREVIEW_EXAMPLE" >"$TMP_REQUEST"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$TMP_REQUEST" --adapter-request "$ADAPTER_EXAMPLE" >"$TMP_DIR-source-hash-mismatch.json"
source_hash_exit=$?
set -e
if [ "$source_hash_exit" -ne 1 ]; then
  echo "source hash mismatch should exit 1" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("source_request_hash_mismatch")' "$TMP_DIR-source-hash-mismatch.json" >/dev/null

jq '.canonical_plan_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "$PREVIEW_EXAMPLE" >"$TMP_REQUEST"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$TMP_REQUEST" --adapter-request "$ADAPTER_EXAMPLE" >"$TMP_DIR-canonical-hash-mismatch.json"
canonical_hash_exit=$?
set -e
if [ "$canonical_hash_exit" -ne 1 ]; then
  echo "canonical hash mismatch should exit 1" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("canonical_plan_hash_mismatch")' "$TMP_DIR-canonical-hash-mismatch.json" >/dev/null

jq '.frame_selection.sample_count = 24' "$PREVIEW_EXAMPLE" >"$TMP_REQUEST"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$TMP_REQUEST" --adapter-request "$ADAPTER_EXAMPLE" >/dev/null
sample_timeline_exit=$?
set -e
if [ "$sample_timeline_exit" -ne 0 ]; then
  echo "sample_count 24 should be valid for 120-frame timeline" >&2
  exit 1
fi

set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$PREVIEW_EXAMPLE" --adapter-request "$ADAPTER_EXAMPLE" --execute-animation >"$TMP_DIR-only-execute.json"
only_execute_exit=$?
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$PREVIEW_EXAMPLE" --adapter-request "$ADAPTER_EXAMPLE" --render-preview >"$TMP_DIR-only-render.json"
only_render_exit=$?
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$PREVIEW_EXAMPLE" --adapter-request "$ADAPTER_EXAMPLE" --execute-animation --render-preview >"$TMP_DIR-no-env.json"
no_env_exit=$?
REAL_ANIMATION_GENERATION=1 PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$PREVIEW_EXAMPLE" --adapter-request "$ADAPTER_EXAMPLE" --execute-animation --render-preview >"$TMP_DIR-one-env.json"
one_env_exit=$?
REAL_ANIMATION_PREVIEW_RENDER=1 PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$PREVIEW_EXAMPLE" --adapter-request "$ADAPTER_EXAMPLE" --execute-animation --render-preview >"$TMP_DIR-preview-env.json"
preview_env_exit=$?
REAL_ANIMATION_GENERATION=1 REAL_ANIMATION_PREVIEW_RENDER=1 PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$RENDERER" --preview-request "$PREVIEW_EXAMPLE" --adapter-request "$ADAPTER_EXAMPLE" >"$TMP_DIR-env-no-flags.json"
env_no_flags_exit=$?
set -e
for value in "$only_execute_exit" "$only_render_exit" "$no_env_exit" "$one_env_exit" "$preview_env_exit"; do
  if [ "$value" -ne 2 ]; then
    echo "guard-blocked CLI case should exit 2" >&2
    exit 1
  fi
done
if [ "$env_no_flags_exit" -ne 0 ]; then
  echo "environment guards without CLI flags should remain plan-only" >&2
  exit 1
fi
jq -e '.status == "planned" and .safety_flags.bpy_imported == false' "$TMP_DIR-env-no-flags.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - <<'PY'
import ast
from pathlib import Path

tree = ast.parse(Path("apps/media-worker/app/animation_preview_renderer.py").read_text(encoding="utf-8"))
module_imports = []
local_bpy = []
for node in ast.walk(tree):
    if isinstance(node, (ast.Import, ast.ImportFrom)):
        names = [alias.name for alias in getattr(node, "names", [])]
        module = getattr(node, "module", None)
        if any(name in {"bpy", "mathutils", "subprocess"} for name in names) or module in {"bpy", "mathutils", "subprocess"}:
            parent_name = None
            for parent in ast.walk(tree):
                for child in ast.iter_child_nodes(parent):
                    if child is node and isinstance(parent, ast.FunctionDef):
                        parent_name = parent.name
            if parent_name is None:
                module_imports.append((node.lineno, names, module))
            elif parent_name == "execute_animation_preview_render" and names == ["bpy"]:
                local_bpy.append(node.lineno)
assert not module_imports, module_imports
assert local_bpy, "bpy import must exist only inside guarded public execution function"
PY

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - <<'PY'
import json
import shutil
import sys
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, "apps/media-worker/app")
from animation_preview_renderer import (  # noqa: E402
    _execute_preview_with_bpy_module,
    build_animation_preview_render_report,
    build_blender_animation_operation_plan,
    build_preview_render_operation_plan,
    load_adapter_request,
    load_preview_render_request,
    preflight_preview_render,
    select_preview_frames,
    validate_preview_render_operation_plan,
)

assert select_preview_frames(1, 120, 8) == (1, 18, 35, 52, 69, 86, 103, 120)
assert select_preview_frames(1, 120, 8)[0] == 1
assert select_preview_frames(1, 120, 8)[-1] == 120
assert all(a < b for a, b in zip(select_preview_frames(1, 120, 8), select_preview_frames(1, 120, 8)[1:]))

preview = load_preview_render_request("configs/animation/preview-render-request.example.json").request
adapter = load_adapter_request("configs/animation/blender-animation-adapter-request.example.json").request
adapter_plan = build_blender_animation_operation_plan(adapter).operation_plan
preview_plan = build_preview_render_operation_plan(preview, adapter, adapter_plan)
assert not validate_preview_render_operation_plan(preview_plan)
bad_plan = json.loads(json.dumps(preview_plan))
bad_plan["operations"][0]["operation_type"] = "run_ffmpeg"
assert [issue.code for issue in validate_preview_render_operation_plan(bad_plan)]

class KeyPoint:
    def __init__(self):
        self.interpolation = "UNSET"

class FCurve:
    def __init__(self, data_path):
        self.data_path = data_path
        self.keyframe_points = [KeyPoint()]

class FakeTarget:
    def __init__(self, target_type="MESH"):
        self.type = target_type
        self.rotation_mode = ""
        self.location = [0, 0, 0]
        self.rotation_euler = [0, 0, 0]
        self.scale = [1, 1, 1]
        self.hide_viewport = False
        self.hide_render = False
        self.data = SimpleNamespace(lens=0)
        self.animation_data = SimpleNamespace(action=SimpleNamespace(fcurves=[]))
        self.inserted = []

    def keyframe_insert(self, *, data_path, frame):
        self.inserted.append((data_path, frame))
        self.animation_data.action.fcurves.append(FCurve(data_path))

class FakeRenderOperator:
    def __init__(self, scene, *, mode="ok", bytes_per_frame=8):
        self.scene = scene
        self.mode = mode
        self.bytes_per_frame = bytes_per_frame
        self.calls = []

    def render(self, *, write_still):
        self.calls.append((self.scene.frame_current, self.scene.render.filepath, write_still))
        path = Path(self.scene.render.filepath)
        if self.mode == "raise":
            raise RuntimeError("fake render failed")
        if self.mode == "missing":
            return
        path.parent.mkdir(parents=True, exist_ok=True)
        if self.mode == "symlink":
            target = path.parent / "target.png"
            target.write_bytes(b"PNGDATA")
            path.symlink_to(target)
            return
        if self.mode == "empty":
            path.write_bytes(b"")
            return
        path.write_bytes((b"PNGDATA!!" * self.bytes_per_frame)[: self.bytes_per_frame])

class FakeScene:
    def __init__(self, *, fail_restore=False):
        self.render = SimpleNamespace(
            engine="OLD",
            resolution_x=10,
            resolution_y=20,
            resolution_percentage=50,
            image_settings=SimpleNamespace(file_format="JPEG"),
            film_transparent=True,
            filepath="old-path",
            fps=0,
        )
        self.camera = "old-camera"
        self.frame_current = 42
        self.frame_start = 0
        self.frame_end = 0
        self.fail_restore = fail_restore
        self.frames_set = []

    def frame_set(self, frame):
        if self.fail_restore and frame == 42:
            raise RuntimeError("restore failed")
        self.frame_current = frame
        self.frames_set.append(frame)

class FakeBpy:
    def __init__(self, *, camera=True, camera_type="CAMERA", render_mode="ok", bytes_per_frame=8, supported=("BLENDER_EEVEE_NEXT",), fail_restore=False):
        self.scene = FakeScene(fail_restore=fail_restore)
        objects = {"demo-object": FakeTarget("MESH")}
        if camera:
            objects["camera"] = FakeTarget(camera_type)
        self.data = SimpleNamespace(objects=objects)
        self.context = SimpleNamespace(scene=self.scene)
        self.ops = SimpleNamespace(render=FakeRenderOperator(self.scene, mode=render_mode, bytes_per_frame=bytes_per_frame))
        self.supported_render_engines = supported

def runtime_root(name):
    root = Path("/tmp") / f"moe-animation-preview-renderer-fake-{name}"
    shutil.rmtree(root, ignore_errors=True)
    (root / "media" / "animation" / "previews").mkdir(parents=True)
    return root

fake = FakeBpy()
root = runtime_root("success")
result, code = _execute_preview_with_bpy_module(preview, adapter, preview_plan, adapter_plan, fake, runtime_root=root, monotonic=lambda: 0.0)
assert code == 0, result
assert result["status"] == "rendered"
assert result["final_output_published"] is True
assert result["partial_output_available"] is False
assert result["execution"]["animation_applied"] is True
assert result["execution"]["preview_rendered"] is True
assert result["safety_flags"]["runtime_assets_written"] is True
assert result["safety_flags"]["render_settings_restored"] is True
final = root / preview["output"]["relative_runtime_directory"]
assert final.is_dir()
assert sorted(p.name for p in final.iterdir()) == [f"frame-{frame:06d}.png" for frame in preview_plan["frames"]]
assert fake.scene.render.engine == "OLD"
assert fake.scene.render.resolution_x == 10
assert fake.scene.render.image_settings.file_format == "JPEG"
assert fake.scene.camera == "old-camera"
assert fake.scene.frame_current == 42
assert fake.ops.render.calls[0][0] == 1 and fake.ops.render.calls[-1][0] == 120

for name, fake_kwargs, expected in [
    ("missing-camera", {"camera": False}, "preflight_failed"),
    ("wrong-camera", {"camera_type": "MESH"}, "preflight_failed"),
    ("unsupported-engine", {"supported": ()}, "preflight_failed"),
    ("render-raise", {"render_mode": "raise"}, "render_failed"),
    ("missing-frame", {"render_mode": "missing"}, "verification_failed"),
    ("symlink-frame", {"render_mode": "symlink"}, "verification_failed"),
    ("empty-frame", {"render_mode": "empty"}, "verification_failed"),
    ("size-limit", {"bytes_per_frame": 10}, "output_limit_exceeded"),
    ("restore-fail", {"fail_restore": True}, "restore_failed"),
]:
    local_preview = json.loads(json.dumps(preview))
    if name == "size-limit":
        local_preview["limits"]["max_total_output_bytes"] = 1
    local_plan = build_preview_render_operation_plan(local_preview, adapter, adapter_plan)
    root = runtime_root(name)
    fake = FakeBpy(**fake_kwargs)
    result, code = _execute_preview_with_bpy_module(local_preview, adapter, local_plan, adapter_plan, fake, runtime_root=root, monotonic=lambda: 0.0)
    assert code == 1, (name, result)
    assert result["status"] == expected, (name, result)
    assert result["final_output_published"] is False
    assert result["partial_output_available"] is False
    assert not (root / local_preview["output"]["relative_runtime_directory"]).exists()
    preview_parent = root / "media" / "animation" / "previews" / local_preview["preview_id"]
    assert not preview_parent.exists() or not any(preview_parent.iterdir())

root = runtime_root("existing")
(root / "media" / "animation" / "previews" / preview["preview_id"]).mkdir()
preflight, code = preflight_preview_render(preview, preview_plan, FakeBpy(), runtime_root=root)
assert code == 1
assert any(error["code"] == "preview_directory_exists" for error in preflight["errors"])

root = runtime_root("symlink-root")
shutil.rmtree(root / "media" / "animation" / "previews")
(root / "bad-target").mkdir()
(root / "media" / "animation" / "previews").symlink_to(root / "bad-target")
preflight, code = preflight_preview_render(preview, preview_plan, FakeBpy(), runtime_root=root)
assert code == 1
assert any(error["code"] == "preview_root_symlink" for error in preflight["errors"])

class Clock:
    def __init__(self, values):
        self.values = list(values)
    def __call__(self):
        return self.values.pop(0) if self.values else 999.0

local_preview = json.loads(json.dumps(preview))
local_preview["limits"]["timeout_seconds"] = 1
for name, clock in [("timeout-before", Clock([0, 2])), ("timeout-between", Clock([0, 0, 0, 2]))]:
    root = runtime_root(name)
    result, code = _execute_preview_with_bpy_module(local_preview, adapter, preview_plan, adapter_plan, FakeBpy(), runtime_root=root, monotonic=clock)
    assert code == 1, (name, result)
    assert result["status"] == "timeout", (name, result)
    assert not (root / local_preview["output"]["relative_runtime_directory"]).exists()

for root in Path("/tmp").glob("moe-animation-preview-renderer-fake-*"):
    shutil.rmtree(root, ignore_errors=True)
PY

for heading in \
  "Purpose" \
  "Implementation source" \
  "Preview request loading" \
  "Schema validation" \
  "Adapter request integration" \
  "Hash validation" \
  "Frame selection" \
  "Preview operation plan" \
  "Plan-only behavior" \
  "Execution guards" \
  "Blender import boundary" \
  "Preflight" \
  "Camera resolution" \
  "Runtime root" \
  "Output path safety" \
  "Staging" \
  "Atomic publish" \
  "Render settings snapshot" \
  "Animation execution reuse" \
  "PNG frame rendering" \
  "Frame verification" \
  "Output size limit" \
  "Timeout" \
  "Render settings restore" \
  "Failure behavior" \
  "CLI" \
  "Exit codes" \
  "Fake bpy tests" \
  "No-video boundary" \
  "M36.12 boundary" \
  "Final decision"; do
  grep -q "## $heading" "$DOC"
done

for heading in \
  "Repository state" \
  "Implementation source" \
  "Preview schema reuse" \
  "Preview request loading" \
  "Adapter request reuse" \
  "Animation operation plan reuse" \
  "Hash validation" \
  "Frame selection" \
  "Operation plan determinism" \
  "Plan-only behavior" \
  "CLI flag consistency" \
  "Four execution guards" \
  "Blender import boundary" \
  "Preflight" \
  "Camera resolution" \
  "No camera fallback" \
  "Runtime root" \
  "Path validation" \
  "Symlink protection" \
  "Overwrite protection" \
  "Staging" \
  "Atomic publish" \
  "Render settings snapshot" \
  "Animation execution" \
  "PNG rendering" \
  "Frame verification" \
  "Size limit" \
  "Timeout" \
  "Render settings restore" \
  "Failure truthfulness" \
  "Fake bpy regression" \
  "No subprocess" \
  "No ffmpeg" \
  "No video" \
  "No blend save" \
  "No metadata write" \
  "Source/runtime/model boundaries" \
  "Regression results" \
  "Final decision"; do
  grep -q "## $heading" "$REVIEW"
done

grep -q -- "- M36.11 Guarded Preview Render Implementation DONE" docs/milestones.md
grep -q -- "- M36.12 Animation Artifact Verifier DONE" docs/milestones.md
grep -q -- "- M36.13 Animation Output Card API Plan DONE" docs/milestones.md
grep -q -- "- M36.14 Animation Output Card API DONE" docs/milestones.md
grep -q -- "- M36.15 Dashboard Animation Cards UI PLANNED" docs/milestones.md
if rg -n "M36\\.15.*DONE|M37\\.0.*DONE|M38" README.md docs scripts --glob '!scripts/test-animation-preview-renderer.sh' --glob '!scripts/test-animation-output-card-api-plan.sh' --glob '!scripts/test-animation-output-card-api.sh' >/dev/null; then
  echo "future milestone state changed unexpectedly" >&2
  exit 1
fi

if grep -R '^import bpy\|from bpy\|mathutils\|subprocess' "$RENDERER" >/dev/null; then
  echo "preview renderer contains forbidden module import or video/save surface" >&2
  exit 1
fi

if find . -type f \( -name "frame-*.png" -o -name "*.mp4" -o -name "*.webm" -o -name "*.mov" -o -name "*.gif" -o -name "*.blend" \) -print -quit | grep -q .; then
  echo "generated preview/video artifact found in source checkout" >&2
  exit 1
fi

rm -rf "$TMP_DIR"* "$TMP_REQUEST" "$TMP_ADAPTER"
if find /tmp -maxdepth 3 -path '/tmp/systemd-private-*' -prune -o \( -name 'moe-animation-preview*' -o -name '.frames-staging-*' -o -name 'frame-*.png' \) -print -quit | grep -q .; then
  echo "temporary animation preview fixtures were not cleaned" >&2
  exit 1
fi

echo "Animation preview renderer OK"
