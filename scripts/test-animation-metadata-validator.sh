#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
VALIDATOR="apps/media-worker/app/animation_metadata_validator.py"
WRITER="apps/media-worker/app/animation_metadata_sidecar.py"
EXAMPLE="configs/animation/animation-metadata.example.json"
ADAPTER_REQUEST="configs/animation/blender-animation-adapter-request.example.json"
SCHEMA="configs/animation/animation-metadata.schema.json"
TMP_DIR="$(mktemp -d /tmp/moe-animation-validator.XXXXXX)"
TMP_FILE_PREFIX="/tmp/moe-animation-validator.$$"

cleanup() {
  rm -rf "$TMP_DIR"
  rm -f "${TMP_FILE_PREFIX}"*.json
}
trap cleanup EXIT

for path in "$VALIDATOR" "$WRITER" "$EXAMPLE" "$ADAPTER_REQUEST" "$SCHEMA"; do
  if [ ! -f "$path" ]; then
    echo "missing animation metadata validator dependency: $path" >&2
    exit 1
  fi
done

jq empty "$SCHEMA"
jq -e '.["$schema"] == "https://json-schema.org/draft/2020-12/schema"' "$SCHEMA" >/dev/null
jq -e '.["$id"] == "urn:moe:animation-metadata-schema:1.0"' "$SCHEMA" >/dev/null
jq -e '.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.source_scene.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.timeline.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.animation_summary.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.adapter_summary.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.output_files.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.validation.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.safety_flags.additionalProperties == false' "$SCHEMA" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$EXAMPLE" --pretty >"$TMP_DIR/standalone-report.json"
jq -e '.report_type == "animation_metadata_validation"' "$TMP_DIR/standalone-report.json" >/dev/null
jq -e '.validation_mode == "standalone" and .provenance_checked == false' "$TMP_DIR/standalone-report.json" >/dev/null
jq -e '.valid == true and .error_count == 0' "$TMP_DIR/standalone-report.json" >/dev/null
jq -e '.summary.animation_id == "object-transform-demo-plan"' "$TMP_DIR/standalone-report.json" >/dev/null
jq -e '.summary.source_kind == "object_transform_animation_plan"' "$TMP_DIR/standalone-report.json" >/dev/null
jq -e '.summary.fps == 24 and .summary.start_frame == 1 and .summary.end_frame == 120' "$TMP_DIR/standalone-report.json" >/dev/null
jq -e '.summary.track_count == 1 and .summary.keyframe_count == 2 and .summary.operation_count == 14' "$TMP_DIR/standalone-report.json" >/dev/null
jq -e '.safety_flags.read_only == true and .safety_flags.runtime_assets_written == false and .safety_flags.blender_execution_attempted == false' "$TMP_DIR/standalone-report.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$EXAMPLE" --adapter-request "$ADAPTER_REQUEST" --pretty >"$TMP_DIR/provenance-report.json"
jq -e '.validation_mode == "provenance" and .provenance_checked == true' "$TMP_DIR/provenance-report.json" >/dev/null
jq -e '.valid == true and .error_count == 0' "$TMP_DIR/provenance-report.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$WRITER" --adapter-request "$ADAPTER_REQUEST" --write-metadata "$TMP_DIR/written.json" >/dev/null
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$TMP_DIR/written.json" --adapter-request "$ADAPTER_REQUEST" >"$TMP_DIR/written-validation.json"
jq -e '.valid == true and .summary.metadata_written == true' "$TMP_DIR/written-validation.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$EXAMPLE" >"$TMP_DIR/determinism-a.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$EXAMPLE" >"$TMP_DIR/determinism-b.json"
cmp "$TMP_DIR/determinism-a.json" "$TMP_DIR/determinism-b.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$EXAMPLE" --adapter-request "$ADAPTER_REQUEST" >"$TMP_DIR/prov-a.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$EXAMPLE" --adapter-request "$ADAPTER_REQUEST" >"$TMP_DIR/prov-b.json"
cmp "$TMP_DIR/prov-a.json" "$TMP_DIR/prov-b.json"

if grep -F "$PWD" "$TMP_DIR/standalone-report.json" >/dev/null || grep -F "/home/cuneyt/MoE/runtime" "$TMP_DIR/standalone-report.json" >/dev/null || grep -F "/home/cuneyt/MoE_Models_Backup" "$TMP_DIR/standalone-report.json" >/dev/null; then
  echo "validator report leaked absolute repo/runtime/model path" >&2
  exit 1
fi

run_invalid() {
  local name="$1"
  local jq_filter="$2"
  local expected_code="$3"
  local expected_issue="$4"
  local fixture="${TMP_FILE_PREFIX}-${name}.json"
  local report="$TMP_DIR/${name}-report.json"
  jq "$jq_filter" "$EXAMPLE" >"$fixture"
  set +e
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$fixture" >"$report"
  local status=$?
  set -e
  if [ "$status" -ne "$expected_code" ]; then
    echo "$name expected exit $expected_code, got $status" >&2
    cat "$report" >&2
    exit 1
  fi
  jq -e '.valid == false and .error_count > 0' "$report" >/dev/null
  jq -e --arg code "$expected_issue" '.errors | map(.code) | index($code)' "$report" >/dev/null
}

run_invalid "unknown-top" '. + {"extra": true}' 1 "unknown_field"
run_invalid "unknown-nested" '.timeline.extra = true' 1 "unknown_field"
run_invalid "missing-required" 'del(.animation_id)' 1 "missing_required_field"
run_invalid "bad-schema-version" '.schema_version = "2.0"' 1 "const_mismatch"
run_invalid "bad-metadata-type" '.metadata_type = "bad"' 1 "const_mismatch"
run_invalid "bad-asset-type" '.asset_type = "bad"' 1 "const_mismatch"
run_invalid "bad-source" '.source = "bad"' 1 "const_mismatch"
run_invalid "absolute-generator" '.generator_script = "/home/cuneyt/DiskD/Projects/MoE/codebase/apps/media-worker/app/animation_metadata_sidecar.py"' 1 "const_mismatch"
run_invalid "bad-generator-version" '.generator_version = "9.9.9"' 1 "const_mismatch"
run_invalid "unsafe-animation-id" '.animation_id = "../bad"' 1 "unsafe_identifier"
run_invalid "bad-timestamp-format" '.created_at = "2026-01-01T00:00:00+00:00"' 1 "invalid_timestamp"
run_invalid "bad-calendar" '.created_at = "2026-13-01T00:00:00Z"' 1 "invalid_timestamp"
run_invalid "uppercase-hash" '.source_request_sha256 = (.source_request_sha256 | ascii_upcase)' 1 "invalid_sha256"
run_invalid "short-hash" '.adapter_request_sha256 = "abc"' 1 "invalid_sha256"
run_invalid "bad-source-kind" '.source_kind = "bad"' 1 "enum_mismatch"
run_invalid "unsafe-reference" '.source_scene.reference_id = "/home/bad"' 1 "unsafe_identifier"
run_invalid "bad-units" '.source_scene.units = "feet"' 1 "enum_mismatch"
run_invalid "bool-fps" '.timeline.fps = true' 1 "type_mismatch"
run_invalid "low-fps" '.timeline.fps = 0' 1 "type_mismatch"
run_invalid "bad-range" '.timeline.end_frame = 1' 1 "timeline_invalid_range"
run_invalid "bad-total" '.timeline.total_frames = 999' 1 "timeline_total_frames_mismatch"
run_invalid "bad-duration" '.timeline.duration_seconds = 99' 1 "timeline_duration_mismatch"
run_invalid "low-track-count" '.animation_summary.track_count = 0' 1 "type_mismatch"
run_invalid "low-keyframe-count" '.animation_summary.keyframe_count = 0' 1 "type_mismatch"
run_invalid "negative-segment-count" '.animation_summary.segment_count = -1' 1 "type_mismatch"
run_invalid "duplicate-target-types" '.animation_summary.target_types = ["object","object"]' 1 "duplicate_value"
run_invalid "unsorted-target-types" '.animation_summary.target_types = ["object","camera"]' 1 "array_not_sorted"
run_invalid "bad-target-type" '.animation_summary.target_types = ["mesh"]' 1 "enum_mismatch"
run_invalid "unsafe-target-id" '.animation_summary.target_ids = ["/home/bad"]' 1 "unsafe_identifier"
run_invalid "duplicate-target-id" '.animation_summary.target_ids = ["demo-object","demo-object"]' 1 "duplicate_value"
run_invalid "unsorted-target-id" '.animation_summary.target_ids = ["z-target","a-target"]' 1 "array_not_sorted"
run_invalid "bad-property" '.animation_summary.properties = ["bad"]' 1 "enum_mismatch"
run_invalid "bad-interpolation" '.animation_summary.interpolations = ["ease"]' 1 "enum_mismatch"
run_invalid "bad-operation-count" '.adapter_summary.operation_count = 0' 1 "type_mismatch"
run_invalid "bad-operation-type" '.adapter_summary.operation_types = ["bad"]' 1 "enum_mismatch"
run_invalid "duplicate-operation-type" '.adapter_summary.operation_types = ["resolve_target","resolve_target"]' 1 "duplicate_value"
run_invalid "unsafe-resolved-id" '.adapter_summary.resolved_target_ids = ["../bad"]' 1 "unsafe_identifier"
run_invalid "bad-execution-status" '.adapter_summary.execution_status = "executed"' 1 "const_mismatch"
run_invalid "absolute-preview" '.output_files.preview = "/tmp/out.mp4"' 1 "unsafe_output_path"
run_invalid "traversal-preview" '.output_files.preview = "media/animation/previews/../out.mp4"' 1 "unsafe_output_path"
run_invalid "backslash-preview" '.output_files.preview = "media\\\\animation\\\\previews\\\\out.mp4"' 1 "unsafe_output_path"
run_invalid "url-preview" '.output_files.preview = "http://example.test/out.mp4"' 1 "unsafe_output_path"
run_invalid "bad-metadata-path" '.output_files.metadata = "media/animation/previews/out.json"' 1 "unsafe_output_path"
run_invalid "non-null-report" '.output_files.report = "report.json"' 1 "const_mismatch"
run_invalid "preview-available" '.preview_available = true' 1 "const_mismatch"
run_invalid "visual-reference" '.visual_reference_only = false' 1 "const_mismatch"
run_invalid "structural" '.structural_certification = true' 1 "const_mismatch"
run_invalid "operator-review" '.operator_review_required = false' 1 "const_mismatch"
run_invalid "generation-mode" '.generation_mode = "render"' 1 "const_mismatch"
run_invalid "validation-flag" '.validation.operation_plan_valid = false' 1 "const_mismatch"
run_invalid "unsafe-safety" '.safety_flags.runtime_assets_written = true' 1 "const_mismatch"
run_invalid "read-only-inputs" '.safety_flags.read_only_inputs = false' 1 "const_mismatch"

jq '.safety_flags.metadata_written = true' "$EXAMPLE" >"${TMP_FILE_PREFIX}-metadata-written-true.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "${TMP_FILE_PREFIX}-metadata-written-true.json" >"$TMP_DIR/metadata-written-true-report.json"
jq -e '.valid == true and .summary.metadata_written == true' "$TMP_DIR/metadata-written-true-report.json" >/dev/null

run_provenance_invalid() {
  local name="$1"
  local jq_filter="$2"
  local expected_issue="$3"
  local fixture="${TMP_FILE_PREFIX}-${name}.json"
  local report="$TMP_DIR/${name}-report.json"
  jq "$jq_filter" "$EXAMPLE" >"$fixture"
  set +e
  PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$fixture" --adapter-request "$ADAPTER_REQUEST" >"$report"
  local status=$?
  set -e
  if [ "$status" -ne 1 ]; then
    echo "$name expected provenance exit 1, got $status" >&2
    cat "$report" >&2
    exit 1
  fi
  jq -e --arg code "$expected_issue" '.errors | map(.code) | index($code)' "$report" >/dev/null
}

run_provenance_invalid "adapter-hash-mismatch" '.adapter_request_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "adapter_request_hash_mismatch"
run_provenance_invalid "source-hash-mismatch" '.source_request_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "source_request_hash_mismatch"
run_provenance_invalid "canonical-hash-mismatch" '.canonical_plan_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "canonical_plan_hash_mismatch"
run_provenance_invalid "operation-hash-mismatch" '.operation_plan_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "operation_plan_hash_mismatch"
run_provenance_invalid "summary-tamper" '.animation_summary.keyframe_count = 3' "metadata_summary_mismatch"
run_provenance_invalid "output-tamper" '.output_files.preview = "media/animation/previews/tampered.mp4"' "metadata_output_reference_mismatch"
run_provenance_invalid "warning-tamper" '.warnings = ["changed"]' "metadata_rebuild_mismatch"
run_provenance_invalid "safety-tamper" '.safety_flags.blend_file_saved = true' "metadata_rebuild_mismatch"

jq '.timeline_plan.source_plan_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "$ADAPTER_REQUEST" >"${TMP_FILE_PREFIX}-bad-adapter.json"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$EXAMPLE" --adapter-request "${TMP_FILE_PREFIX}-bad-adapter.json" >"$TMP_DIR/bad-adapter-report.json"
bad_adapter_status=$?
set -e
if [ "$bad_adapter_status" -ne 1 ]; then
  echo "invalid adapter provenance should exit 1" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("timeline_plan_hash_mismatch")' "$TMP_DIR/bad-adapter-report.json" >/dev/null

printf '{' >"${TMP_FILE_PREFIX}-malformed.json"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "${TMP_FILE_PREFIX}-malformed.json" >"$TMP_DIR/malformed-report.json"
malformed_status=$?
set -e
if [ "$malformed_status" -ne 2 ]; then
  echo "malformed metadata should exit 2" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("malformed_json")' "$TMP_DIR/malformed-report.json" >/dev/null

printf '[]' >"${TMP_FILE_PREFIX}-array.json"
set +e
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "${TMP_FILE_PREFIX}-array.json" >"$TMP_DIR/array-report.json"
array_status=$?
set -e
if [ "$array_status" -ne 1 ]; then
  echo "root array should exit 1" >&2
  exit 1
fi
jq -e '.errors | map(.code) | index("root_not_object")' "$TMP_DIR/array-report.json" >/dev/null

ln -s "$EXAMPLE" "$TMP_DIR/link.json"
if PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$TMP_DIR/link.json" >/dev/null 2>&1; then
  echo "metadata symlink input was accepted" >&2
  exit 1
fi

if PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata docs/bad.json >/dev/null 2>&1; then
  echo "metadata validator accepted arbitrary source path" >&2
  exit 1
fi

large_file="${TMP_FILE_PREFIX}-large.json"
PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - "$large_file" <<'PY'
from pathlib import Path
import sys
Path(sys.argv[1]).write_text('{"x":"' + ('a' * (513 * 1024)) + '"}', encoding='utf-8')
PY
if PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" "$VALIDATOR" --metadata "$large_file" >/dev/null 2>&1; then
  echo "oversized metadata was accepted" >&2
  exit 1
fi

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - <<'PY'
import ast
from pathlib import Path

path = Path("apps/media-worker/app/animation_metadata_validator.py")
tree = ast.parse(path.read_text(encoding="utf-8"))
blocked = {"bpy", "mathutils", "subprocess"}
for node in ast.walk(tree):
    if isinstance(node, (ast.Import, ast.ImportFrom)):
        names = {alias.name for alias in getattr(node, "names", [])}
        module = getattr(node, "module", None)
        assert not (names & blocked), (node.lineno, names)
        assert module not in blocked, (node.lineno, module)
text = path.read_text(encoding="utf-8")
assert "execute_blender_animation_operation_plan" not in text
assert "render-preview" not in text
assert "ffmpeg" not in text
assert "write_animation_metadata_sidecar" not in text
PY

if grep -R '^import bpy\|from bpy\|mathutils\|subprocess\|ffmpeg\|render-preview\|execute_blender_animation_operation_plan\|write_animation_metadata_sidecar' "$VALIDATOR" >/dev/null; then
  echo "validator contains forbidden Blender/execution/write surface" >&2
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

echo "Animation metadata validator OK"
