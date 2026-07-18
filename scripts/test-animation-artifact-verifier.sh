#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
SCRIPT="apps/media-worker/app/animation_artifact_verifier.py"
METADATA="configs/animation/animation-metadata.example.json"
ADAPTER="configs/animation/blender-animation-adapter-request.example.json"
PREVIEW_REQUEST="configs/animation/preview-render-request.example.json"
TMP_DIR="$(mktemp -d /tmp/moe-animation-artifact-verifier.XXXXXX)"
TMP_FILE_PREFIX="/tmp/moe-animation-artifact-verifier-$$"

cleanup() {
  rm -rf "$TMP_DIR"
  rm -f "${TMP_FILE_PREFIX}"*.json
}
trap cleanup EXIT

run_verifier() {
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$SCRIPT" "$@"
}

expect_fail() {
  local expected_code="$1"
  local output_file="$2"
  shift 2
  local status=0
  run_verifier "$@" >"$output_file" || status=$?
  if [ "$status" -eq 0 ]; then
    echo "verifier unexpectedly succeeded: $*" >&2
    exit 1
  fi
  jq -e --arg code "$expected_code" '.valid == false and (.errors[]?.code == $code)' "$output_file" >/dev/null
}

run_verifier --metadata "$METADATA" --pretty >"$TMP_DIR/metadata-only.json"
jq -e '.report_type == "animation_artifact_verification"' "$TMP_DIR/metadata-only.json" >/dev/null
jq -e '.valid == true' "$TMP_DIR/metadata-only.json" >/dev/null
jq -e '.verification_mode == "metadata_only"' "$TMP_DIR/metadata-only.json" >/dev/null
jq -e '.artifacts | length == 0' "$TMP_DIR/metadata-only.json" >/dev/null
jq -e '.safety_flags.read_only == true' "$TMP_DIR/metadata-only.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/metadata-only.json" >/dev/null
jq -e '.safety_flags.blender_execution_attempted == false' "$TMP_DIR/metadata-only.json" >/dev/null

run_verifier --metadata "$METADATA" --adapter-request "$ADAPTER" >"$TMP_DIR/provenance.json"
jq -e '.valid == true' "$TMP_DIR/provenance.json" >/dev/null
jq -e '.verification_mode == "metadata_provenance"' "$TMP_DIR/provenance.json" >/dev/null
jq -e '.provenance_checked == true' "$TMP_DIR/provenance.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - <<'PY' >"$TMP_DIR/import.json"
import json
import sys
sys.path.insert(0, "apps/media-worker/app")
import animation_artifact_verifier
print(json.dumps({"imported": True, "has_bpy": "bpy" in sys.modules}))
PY
jq -e '.imported == true and .has_bpy == false' "$TMP_DIR/import.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" apps/media-worker/app/animation_preview_renderer.py \
  --preview-request "$PREVIEW_REQUEST" \
  --adapter-request "$ADAPTER" >"${TMP_FILE_PREFIX}-preview-plan.json"
run_verifier --metadata "$METADATA" --adapter-request "$ADAPTER" --preview-report "${TMP_FILE_PREFIX}-preview-plan.json" \
  >"$TMP_DIR/preview-plan-verified.json"
jq -e '.valid == true' "$TMP_DIR/preview-plan-verified.json" >/dev/null
jq -e '.verification_mode == "preview_plan"' "$TMP_DIR/preview-plan-verified.json" >/dev/null
jq -e '.runtime_artifacts_checked == false' "$TMP_DIR/preview-plan-verified.json" >/dev/null

printf '{"bad":' >"${TMP_FILE_PREFIX}-malformed.json"
expect_fail "malformed_json" "$TMP_DIR/malformed-report.json" --metadata "${TMP_FILE_PREFIX}-malformed.json"
printf '[]' >"${TMP_FILE_PREFIX}-root-array.json"
expect_fail "root_not_object" "$TMP_DIR/root-array-report.json" --metadata "${TMP_FILE_PREFIX}-root-array.json"
ln -s "$PWD/$METADATA" "${TMP_FILE_PREFIX}-metadata-link.json"
expect_fail "input_symlink_rejected" "$TMP_DIR/symlink-report.json" --metadata "${TMP_FILE_PREFIX}-metadata-link.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - "${TMP_FILE_PREFIX}-oversized.json" <<'PY'
from pathlib import Path
import sys
Path(sys.argv[1]).write_text('{"pad":"' + ("x" * (513 * 1024)) + '"}', encoding="utf-8")
PY
expect_fail "input_too_large" "$TMP_DIR/oversized-report.json" --metadata "${TMP_FILE_PREFIX}-oversized.json"
if run_verifier --metadata docs/not-allowed.json >/dev/null 2>&1; then
  echo "repo metadata path unexpectedly accepted" >&2
  exit 1
fi

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - "$TMP_DIR" "$METADATA" "$ADAPTER" "${TMP_FILE_PREFIX}-preview-plan.json" "$TMP_FILE_PREFIX" <<'PY'
import copy
import json
import os
from pathlib import Path
import struct
import sys

sys.path.insert(0, "apps/media-worker/app")
import animation_artifact_verifier as verifier

tmp = Path(sys.argv[1])
metadata_path = Path(sys.argv[2])
adapter = sys.argv[3]
preview_plan_report_path = Path(sys.argv[4])
direct_prefix = Path(sys.argv[5])
runtime = tmp / "runtime"
metadata_root = runtime / "media" / "animation" / "metadata"
frames_dir = runtime / "media" / "animation" / "previews" / "object-transform-demo-preview" / "frames"
metadata_root.mkdir(parents=True)
frames_dir.mkdir(parents=True)

metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
runtime_metadata_path = metadata_root / "object-transform-demo.json"
runtime_metadata_path.write_text(json.dumps(metadata, sort_keys=True), encoding="utf-8")

plan_report = json.loads(preview_plan_report_path.read_text(encoding="utf-8"))
operation_plan = plan_report["operation_plan"]
frames = operation_plan["frames"]
width = 1280
height = 720

def png_bytes(w, h):
    return (
        b"\x89PNG\r\n\x1a\n"
        + struct.pack(">I", 13)
        + b"IHDR"
        + struct.pack(">II", w, h)
        + b"\x08\x02\x00\x00\x00"
        + b"fake-png-payload"
    )

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
    "preview_id": operation_plan["preview_id"],
    "render_mode": "sampled_frames",
    "engine": "BLENDER_EEVEE_NEXT",
    "format": "PNG",
    "width": width,
    "height": height,
    "frames": frames,
    "frame_count": len(frames),
    "relative_output_directory": operation_plan["relative_output_directory"],
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
        "planned": True,
        "rendered": True,
        "render_result": render_result,
        "errors": [],
        "safety_flags": dict(render_result["safety_flags"]),
    }
)
rendered_report_path = Path(f"{direct_prefix}-rendered-preview-report.json")
rendered_report_path.write_text(json.dumps(rendered_report, sort_keys=True), encoding="utf-8")

report, code = verifier.verify_animation_artifact_set(
    str(runtime_metadata_path),
    adapter_request_path=adapter,
    preview_report_path=str(rendered_report_path),
    runtime_root=runtime,
)
(tmp / "full-report.json").write_text(json.dumps(report, sort_keys=True), encoding="utf-8")
if code != 0:
    raise SystemExit(json.dumps(report, indent=2, sort_keys=True))

report_a, _ = verifier.verify_animation_artifact_set(
    str(runtime_metadata_path),
    adapter_request_path=adapter,
    preview_report_path=str(rendered_report_path),
    runtime_root=runtime,
)
report_b, _ = verifier.verify_animation_artifact_set(
    str(runtime_metadata_path),
    adapter_request_path=adapter,
    preview_report_path=str(rendered_report_path),
    runtime_root=runtime,
)
if json.dumps(report_a, sort_keys=True) != json.dumps(report_b, sort_keys=True):
    raise SystemExit("full verification report is not deterministic")

bad = copy.deepcopy(rendered_report)
bad["render_result"]["total_output_bytes"] = total + 1
bad_path = Path(f"{direct_prefix}-bad-total-report.json")
bad_path.write_text(json.dumps(bad, sort_keys=True), encoding="utf-8")
bad_report, bad_code = verifier.verify_animation_artifact_set(
    str(runtime_metadata_path),
    adapter_request_path=adapter,
    preview_report_path=str(bad_path),
    runtime_root=runtime,
)
(tmp / "bad-total-verification.json").write_text(json.dumps(bad_report, sort_keys=True), encoding="utf-8")
if bad_code == 0:
    raise SystemExit("bad total bytes unexpectedly verified")

for name, mutator in {
    "unknown-field": lambda data: data.update({"unexpected": True}),
    "source-kind-mismatch": lambda data: data["operation_plan"].update({"source_kind": "camera_animation_plan"}),
    "frame-count-mismatch": lambda data: data["render_result"].update({"frame_count": 99}),
    "unsafe-path": lambda data: data["render_result"].update({"relative_output_directory": "../bad"}),
}.items():
    fixture = copy.deepcopy(rendered_report)
    mutator(fixture)
    fixture_path = Path(f"{direct_prefix}-{name}.json")
    fixture_path.write_text(json.dumps(fixture, sort_keys=True), encoding="utf-8")
    result, result_code = verifier.verify_animation_artifact_set(
        str(runtime_metadata_path),
        adapter_request_path=adapter,
        preview_report_path=str(fixture_path),
        runtime_root=runtime,
    )
    (tmp / f"{name}-verification.json").write_text(json.dumps(result, sort_keys=True), encoding="utf-8")
    if result_code == 0:
        raise SystemExit(f"{name} unexpectedly verified")

missing_frame = frames_dir / f"frame-{frames[0]:06d}.png"
missing_frame.rename(tmp / missing_frame.name)
missing_report, missing_code = verifier.verify_animation_artifact_set(
    str(runtime_metadata_path),
    adapter_request_path=adapter,
    preview_report_path=str(rendered_report_path),
    runtime_root=runtime,
)
(tmp / "missing-frame-report.json").write_text(json.dumps(missing_report, sort_keys=True), encoding="utf-8")
if missing_code == 0:
    raise SystemExit("missing frame unexpectedly verified")
(tmp / missing_frame.name).rename(missing_frame)

bad_png = frames_dir / f"frame-{frames[1]:06d}.png"
original_bad_png = bad_png.read_bytes()
bad_png.write_bytes(b"not-a-png")
png_report, png_code = verifier.verify_animation_artifact_set(
    str(runtime_metadata_path),
    adapter_request_path=adapter,
    preview_report_path=str(rendered_report_path),
    runtime_root=runtime,
)
(tmp / "bad-png-report.json").write_text(json.dumps(png_report, sort_keys=True), encoding="utf-8")
if png_code == 0:
    raise SystemExit("bad PNG unexpectedly verified")
bad_png.write_bytes(original_bad_png)

unexpected = frames_dir / "unexpected.tmp"
unexpected.write_text("extra", encoding="utf-8")
unexpected_report, unexpected_code = verifier.verify_animation_artifact_set(
    str(runtime_metadata_path),
    adapter_request_path=adapter,
    preview_report_path=str(rendered_report_path),
    runtime_root=runtime,
)
(tmp / "unexpected-artifact-report.json").write_text(json.dumps(unexpected_report, sort_keys=True), encoding="utf-8")
if unexpected_code == 0:
    raise SystemExit("unexpected frame artifact verified")
unexpected.unlink()

symlink = frames_dir / "frame-999999.png"
try:
    symlink.symlink_to(frames_dir / f"frame-{frames[0]:06d}.png")
    symlink_report, symlink_code = verifier.verify_animation_artifact_set(
        str(runtime_metadata_path),
        adapter_request_path=adapter,
        preview_report_path=str(rendered_report_path),
        runtime_root=runtime,
    )
    (tmp / "frame-symlink-report.json").write_text(json.dumps(symlink_report, sort_keys=True), encoding="utf-8")
    if symlink_code == 0:
        raise SystemExit("frame symlink verified")
finally:
    if symlink.exists() or symlink.is_symlink():
        symlink.unlink()

nested_runtime_metadata = metadata_root / "nested" / "bad.json"
nested_runtime_metadata.parent.mkdir()
nested_runtime_metadata.write_text(json.dumps(metadata, sort_keys=True), encoding="utf-8")
nested_loaded = verifier.load_animation_metadata_for_verification(str(nested_runtime_metadata), runtime_root=runtime)
(tmp / "nested-runtime-metadata.json").write_text(
    json.dumps({"exit_code": nested_loaded.exit_code, "errors": [item.as_report_item() for item in nested_loaded.issues]}, sort_keys=True),
    encoding="utf-8",
)

tmp_metadata = Path(f"{direct_prefix}-tmp-metadata.json")
tmp_metadata.write_text(json.dumps(metadata, sort_keys=True), encoding="utf-8")
tmp_report, tmp_code = verifier.verify_animation_artifact_set(str(tmp_metadata), runtime_root=runtime)
(tmp / "tmp-metadata-report.json").write_text(json.dumps(tmp_report, sort_keys=True), encoding="utf-8")
if tmp_code != 0:
    raise SystemExit("tmp metadata did not verify")
PY

jq -e '.valid == true' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.verification_mode == "full"' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.runtime_artifacts_checked == true' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.artifacts | length == 9' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.artifacts[0].role == "metadata"' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.artifacts[1].role == "preview_frame" and .artifacts[1].frame == 1' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.artifacts[] | select(.role == "preview_frame") | .media_type == "image/png"' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.artifacts[] | select(.role == "preview_frame") | (.sha256 | test("^[a-f0-9]{64}$"))' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.errors | length == 0' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/full-report.json" >/dev/null
jq -e '.safety_flags.runtime_assets_deleted == false' "$TMP_DIR/full-report.json" >/dev/null

jq -e 'any(.errors[]?; .code == "total_output_bytes_mismatch")' "$TMP_DIR/bad-total-verification.json" >/dev/null
jq -e 'any(.errors[]?; .code == "preview_report_invalid")' "$TMP_DIR/unknown-field-verification.json" >/dev/null
jq -e 'any(.errors[]?; .code == "preview_metadata_hash_mismatch")' "$TMP_DIR/source-kind-mismatch-verification.json" >/dev/null
jq -e 'any(.errors[]?; .code == "preview_result_invalid")' "$TMP_DIR/frame-count-mismatch-verification.json" >/dev/null
jq -e 'any(.errors[]?; .code == "preview_output_path_invalid")' "$TMP_DIR/unsafe-path-verification.json" >/dev/null
jq -e 'any(.errors[]?; .code == "missing_preview_frame")' "$TMP_DIR/missing-frame-report.json" >/dev/null
jq -e '.status == "incomplete"' "$TMP_DIR/missing-frame-report.json" >/dev/null
jq -e 'any(.errors[]?; .code == "invalid_png_signature")' "$TMP_DIR/bad-png-report.json" >/dev/null
jq -e 'any(.errors[]?; .code == "unexpected_preview_artifact")' "$TMP_DIR/unexpected-artifact-report.json" >/dev/null
jq -e 'any(.errors[]?; .code == "preview_frame_symlink")' "$TMP_DIR/frame-symlink-report.json" >/dev/null
jq -e 'any(.errors[]?; .code == "input_path_not_allowlisted")' "$TMP_DIR/nested-runtime-metadata.json" >/dev/null
jq -e '.valid == true and (.artifacts | length == 0)' "$TMP_DIR/tmp-metadata-report.json" >/dev/null

if grep -R '^import bpy\|^from bpy\|mathutils\|subprocess\|execute_animation_preview_render\|_execute_preview_with_bpy_module\|_execute_with_bpy_module' apps/media-worker/app/animation_artifact_verifier.py >/dev/null; then
  echo "animation artifact verifier contains forbidden execution surface" >&2
  exit 1
fi

if find . -type f \( -name "frame-*.png" -o -name "*.mp4" -o -name "*.webm" -o -name "*.mov" -o -name "*.gif" -o -name "*.blend" \) -print -quit | grep -q .; then
  echo "generated animation artifact found in source checkout" >&2
  exit 1
fi

echo "Animation artifact verifier OK"
