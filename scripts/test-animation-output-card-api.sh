#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
TMP_DIR="$(mktemp -d /tmp/moe-animation-output-cards.XXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

for path in \
  apps/gateway-api/app/media_animation_output_cards.py \
  packages/animation-validation/animation_validation/__init__.py \
  packages/animation-validation/animation_validation/metadata.py \
  packages/animation-validation/animation_validation/artifacts.py \
  packages/animation-validation/animation_validation/paths.py \
  configs/animation/animation-output-cards-response.example.json; do
  if [ ! -f "$path" ]; then
    echo "missing animation output card API dependency: $path" >&2
    exit 1
  fi
done

if grep -R 'parents\[3\]\|parents\[4\]' apps/gateway-api/app/media_3d_output_cards.py apps/gateway-api/app/media_animation_output_cards.py packages/animation-validation >/dev/null; then
  echo "fragile parent-index repo root usage found" >&2
  exit 1
fi

if grep -R 'FileResponse\|base64\|subprocess\|render-preview\|execute-animation\|^import bpy\|^from bpy\|mathutils' apps/gateway-api/app/media_animation_output_cards.py packages/animation-validation >/dev/null; then
  echo "animation output card API introduced binary serving or execution surface" >&2
  exit 1
fi

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api:packages/animation-validation" "$PYTHON_BIN" - <<'PY'
import copy
import importlib.util
import json
import struct
import ast
from pathlib import Path

from app.media_3d_output_cards import build_3d_output_cards
from app.media_animation_output_cards import _build_animation_output_cards_from_root

tmp = Path("/tmp/moe-animation-output-cards.fixture")
if tmp.exists():
    import shutil
    shutil.rmtree(tmp)
runtime = tmp / "runtime"
metadata_dir = runtime / "media" / "animation" / "metadata"
reports_dir = runtime / "media" / "animation" / "reports"
frames_dir = runtime / "media" / "animation" / "previews" / "object-transform-demo-preview" / "frames"
metadata_dir.mkdir(parents=True)
reports_dir.mkdir(parents=True)
frames_dir.mkdir(parents=True)

missing = _build_animation_output_cards_from_root(tmp / "missing-runtime")
assert missing["status"] == "ok"
assert missing["cards"] == []
assert missing["metadata_dir_available"] is False

empty_runtime = tmp / "empty-runtime"
empty_runtime.mkdir()
empty = _build_animation_output_cards_from_root(empty_runtime)
assert empty["status"] == "ok"
assert empty["cards"] == []

metadata = json.loads(Path("configs/animation/animation-metadata.example.json").read_text(encoding="utf-8"))
metadata_path = metadata_dir / "object-transform-demo.json"
metadata_path.write_text(json.dumps(metadata, sort_keys=True), encoding="utf-8")
(metadata_dir / "nested").mkdir()
(metadata_dir / ".hidden.json").write_text("{}", encoding="utf-8")
(metadata_dir / "ignore.txt").write_text("{}", encoding="utf-8")
(metadata_dir / "bad.json").write_text("{", encoding="utf-8")
(metadata_dir / "array.json").write_text("[]", encoding="utf-8")
(metadata_dir / "bad-utf8.json").write_bytes(b"\xff")
(metadata_dir / "oversized.json").write_text('{"x":"' + ("a" * (513 * 1024)) + '"}', encoding="utf-8")
try:
    (metadata_dir / "link.json").symlink_to(metadata_path)
except OSError:
    pass

metadata_only = _build_animation_output_cards_from_root(runtime)
assert metadata_only["status"] == "ok"
assert metadata_only["metadata_dir_available"] is True
assert metadata_only["reports_dir_available"] is True
assert metadata_only["card_count"] == 1
assert metadata_only["invalid_count"] >= 4
card = metadata_only["cards"][0]
assert card["id"] == "animation:media/animation/metadata/object-transform-demo.json"
assert card["type"] == "animation"
assert card["preview"]["available"] is False
assert card["preview"]["first_frame_relative_path"] is None
assert card["relative_runtime_paths"]["metadata"] == "media/animation/metadata/object-transform-demo.json"
assert card["relative_runtime_paths"]["declared_video_preview"] == "media/animation/previews/object-transform-demo.mp4"
assert card["relative_runtime_paths"]["report"] is None
assert card["verification"]["metadata_valid"] is True
assert card["verification"]["provenance_checked"] is False
assert "/home/cuneyt" not in json.dumps(metadata_only, sort_keys=True)
assert "MoE_Models_Backup" not in json.dumps(metadata_only, sort_keys=True)

report_plan = json.loads(Path("configs/animation/preview-render-operation-plan.example.json").read_text(encoding="utf-8"))
report_plan["safety_flags"] = {
    **{
        "bpy_imported": False,
        "blender_execution_attempted": False,
        "runtime_assets_written": False,
        "source_assets_modified": False,
        "scene_modified": False,
        "preview_render_attempted": False,
        "external_process_started": False,
        "ffmpeg_started": False,
        "video_written": False,
        "blend_file_saved": False,
        "render_settings_restored": False,
    },
    **report_plan.get("safety_flags", {}),
}
plan_report = {
    "schema_version": "1.0",
    "report_type": "animation_preview_renderer",
    "status": "planned",
    "planned": True,
    "rendered": False,
    "preview_request_path": "configs/animation/preview-render-request.example.json",
    "adapter_request_path": "configs/animation/blender-animation-adapter-request.example.json",
    "operation_plan": report_plan,
    "render_result": None,
    "errors": [],
    "warnings": [],
    "safety_flags": {
        "bpy_imported": False,
        "blender_execution_attempted": False,
        "runtime_assets_written": False,
        "source_assets_modified": False,
        "scene_modified": False,
        "preview_render_attempted": False,
        "external_process_started": False,
        "ffmpeg_started": False,
        "video_written": False,
        "blend_file_saved": False,
    },
}
(reports_dir / "plan-report.json").write_text(json.dumps(plan_report, sort_keys=True), encoding="utf-8")
plan_response = _build_animation_output_cards_from_root(runtime)
assert plan_response["preview_report_count"] == 1
assert plan_response["cards"][0]["preview"]["available"] is False

def png_bytes(width: int, height: int) -> bytes:
    return (
        b"\x89PNG\r\n\x1a\n"
        + struct.pack(">I", 13)
        + b"IHDR"
        + struct.pack(">II", width, height)
        + b"\x08\x02\x00\x00\x00"
        + b"payload"
    )

width = 1280
height = 720
frames = report_plan["frames"]
total = 0
for frame in frames:
    frame_path = frames_dir / f"frame-{frame:06d}.png"
    payload = png_bytes(width, height)
    frame_path.write_bytes(payload)
    total += len(payload)

render_result = {
    "schema_version": "1.0",
    "result_type": "animation_preview_render_result",
    "status": "rendered",
    "preview_id": report_plan["preview_id"],
    "render_mode": "sampled_frames",
    "engine": "BLENDER_EEVEE_NEXT",
    "format": "PNG",
    "width": width,
    "height": height,
    "frames": frames,
    "frame_count": len(frames),
    "relative_output_directory": report_plan["relative_output_directory"],
    "total_output_bytes": total,
    "final_output_published": True,
    "partial_output_available": False,
    "execution": {
        "animation_applied": True,
        "preview_rendered": True,
        "video_encoded": False,
        "blend_file_saved": False,
    },
    "errors": [],
    "safety_flags": {
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
    },
}
rendered_report = copy.deepcopy(plan_report)
rendered_report.update(
    {
        "status": "rendered",
        "rendered": True,
        "render_result": render_result,
        "safety_flags": dict(render_result["safety_flags"]),
    }
)
(reports_dir / "rendered-report.json").write_text(json.dumps(rendered_report, sort_keys=True), encoding="utf-8")
preview_response = _build_animation_output_cards_from_root(runtime)
preview_card = preview_response["cards"][0]
assert preview_card["preview"]["available"] is True, json.dumps(preview_response, indent=2, sort_keys=True)
assert preview_card["preview"]["first_frame_relative_path"] == "media/animation/previews/object-transform-demo-preview/frames/frame-000001.png"
assert preview_card["relative_runtime_paths"]["report"] == "media/animation/reports/rendered-report.json"
assert preview_response["verified_preview_count"] == 1

mismatched = copy.deepcopy(rendered_report)
mismatched["operation_plan"]["source_kind"] = "camera_animation_plan"
(reports_dir / "mismatched-report.json").write_text(json.dumps(mismatched, sort_keys=True), encoding="utf-8")
still_one = _build_animation_output_cards_from_root(runtime)
assert still_one["cards"][0]["preview"]["available"] is True

ambiguous = copy.deepcopy(rendered_report)
(reports_dir / "rendered-report-copy.json").write_text(json.dumps(ambiguous, sort_keys=True), encoding="utf-8")
ambiguous_response = _build_animation_output_cards_from_root(runtime)
assert ambiguous_response["cards"][0]["preview"]["available"] is False
assert any("ambiguous_preview_reports" in warning for warning in ambiguous_response["warnings"])

(reports_dir / "rendered-report-copy.json").unlink()
bad_frame = frames_dir / f"frame-{frames[0]:06d}.png"
original = bad_frame.read_bytes()
bad_frame.write_bytes(b"not-a-png")
invalid_preview = _build_animation_output_cards_from_root(runtime)
assert invalid_preview["cards"][0]["preview"]["available"] is False
bad_frame.write_bytes(original)

response_a = json.dumps(_build_animation_output_cards_from_root(runtime), sort_keys=True)
response_b = json.dumps(_build_animation_output_cards_from_root(runtime), sort_keys=True)
assert response_a == response_b

assert build_3d_output_cards()["status"] == "ok"
spec = importlib.util.spec_from_file_location("shallow_media_3d_output_cards", "apps/gateway-api/app/media_3d_output_cards.py")
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
assert module.build_3d_output_cards()["status"] == "ok"

main_source = Path("apps/gateway-api/app/main.py").read_text(encoding="utf-8")
assert main_source.count('@app.get("/gateway/media/animation/cards")') == 1
tree = ast.parse(main_source)
route_functions = [
    node
    for node in tree.body
    if isinstance(node, ast.FunctionDef)
    and node.name == "media_animation_output_cards"
]
assert len(route_functions) == 1
assert len(route_functions[0].args.args) == 0
assert not any(isinstance(node, ast.AsyncFunctionDef) and node.name == "media_animation_output_cards" for node in tree.body)

assert not any("AnimationCards" in str(path) for path in Path("apps/dashboard-ui").rglob("*"))
assert not Path("runtime/media/animation").exists()

import shutil
shutil.rmtree(tmp)
PY

if find /tmp -maxdepth 1 -type d -name 'moe-animation-output-cards.fixture' -print -quit | grep -q .; then
  echo "animation output card fixture was not cleaned" >&2
  exit 1
fi

if rg -n "M37\\.0.*DONE|M38\\.0.*DONE" README.md docs scripts --glob '!scripts/test-animation-output-card-api.sh' --glob '!scripts/test-animation-output-card-api-plan.sh' --glob '!scripts/test-animation-preview-renderer.sh' --glob '!scripts/test-dashboard-animation-cards.sh' --glob '!scripts/test-animation-reference-board-selection.sh' --glob '!scripts/test-m36-phase-closure.sh' >/dev/null; then
  echo "future milestone state changed unexpectedly" >&2
  exit 1
fi

if find . -type d \( -name node_modules -o -name dist -o -name build -o -name .cache -o -name __pycache__ \) -print -quit | grep -q .; then
  echo "generated dependency/build/cache directory found in source checkout" >&2
  exit 1
fi

if git ls-files | grep -Ei '\.(mp4|webm|mov|gif|blend|glb|obj|fbx|mtl|safetensors|gguf|ckpt|pt|pth|zip|tar)$' >/dev/null; then
  echo "tracked animation/video/model/3D binary found" >&2
  exit 1
fi

echo "Animation output card API OK"
