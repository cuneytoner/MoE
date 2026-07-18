#!/usr/bin/env python3
"""Shared read-only animation metadata validator for M36.9+."""

from __future__ import annotations

import argparse
import json
import math
import re
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

SOURCE_REPO_ROOT = Path("/home/cuneyt/DiskD/Projects/MoE/codebase")
DEPLOYED_REPO_ROOT = Path("/home/cuneyt/MoE/codebase")
CONTAINER_CONFIG_ROOT = Path("/app/configs/animation")
CONTAINER_WORKSPACE_ROOT = Path("/workspace")
CONFIG_ROOT_CANDIDATES = (
    CONTAINER_CONFIG_ROOT,
    Path.cwd() / "configs" / "animation",
    SOURCE_REPO_ROOT / "configs" / "animation",
    DEPLOYED_REPO_ROOT / "configs" / "animation",
    CONTAINER_WORKSPACE_ROOT / "configs" / "animation",
)
CONFIG_ROOT = next((path for path in CONFIG_ROOT_CANDIDATES if path.is_dir()), CONFIG_ROOT_CANDIDATES[0])
REPO_ROOT = CONFIG_ROOT.parent.parent
SCHEMA_PATH = CONFIG_ROOT / "animation-metadata.schema.json"
MAX_INPUT_BYTES = 512 * 1024
SAFE_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*$")
HASH_RE = re.compile(r"^[a-f0-9]{64}$")
CREATED_AT_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
SOURCE_KINDS = {"camera_animation_plan", "object_transform_animation_plan"}
TARGET_TYPES = {"camera", "object"}
PROPERTIES = {"transform", "location", "rotation_euler", "scale", "visibility"}
INTERPOLATIONS = {"constant", "linear", "bezier"}
OPERATION_TYPES = {
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
TOP_REQUIRED = {
    "schema_version",
    "metadata_type",
    "asset_type",
    "source",
    "generator_script",
    "generator_version",
    "animation_id",
    "title",
    "created_at",
    "source_kind",
    "source_request_sha256",
    "adapter_request_sha256",
    "canonical_plan_sha256",
    "operation_plan_sha256",
    "source_scene",
    "timeline",
    "animation_summary",
    "adapter_summary",
    "output_files",
    "preview_available",
    "visual_reference_only",
    "structural_certification",
    "operator_review_required",
    "generation_mode",
    "validation",
    "warnings",
    "safety_flags",
}
SAFETY_REQUIRED = {
    "metadata_written",
    "read_only_inputs",
    "runtime_assets_written",
    "source_assets_modified",
    "generation_triggered",
    "blender_execution_attempted",
    "keyframes_written",
    "scene_modified",
    "preview_render_attempted",
    "external_process_started",
    "blend_file_saved",
}
BLOCKED_ID_MARKERS = ("/", "\\", "..", "://", "/home/", "/mnt/", "/media/", "/workspace/", "/app/", "MoE_Models_Backup")
BLOCKED_PATH_MARKERS = ("/home/", "/mnt/", "/media/", "/workspace/", "/app/", "MoE_Models_Backup", "DiskD/Projects/MoE/codebase")


@dataclass(frozen=True)
class MetadataValidationIssue:
    code: str
    path: str
    message: str
    severity: str = "error"

    def as_report_item(self) -> dict[str, str]:
        return {"code": self.code, "path": self.path, "message": self.message}


def _issue(code: str, path: str, message: str, severity: str = "error") -> MetadataValidationIssue:
    return MetadataValidationIssue(code=code, path=path, message=message, severity=severity)


def _sort_issues(issues: list[MetadataValidationIssue] | tuple[MetadataValidationIssue, ...]) -> list[MetadataValidationIssue]:
    return sorted(issues, key=lambda item: (item.path, item.code, item.message))


def _items(issues: list[MetadataValidationIssue] | tuple[MetadataValidationIssue, ...]) -> list[dict[str, str]]:
    return [issue.as_report_item() for issue in _sort_issues(issues)]


def _sanitize_path(raw_path: str) -> str:
    raw = str(raw_path)
    path = Path(raw)
    if raw.startswith("configs/animation/"):
        return raw
    if raw.startswith("/tmp/"):
        return f"/tmp/{path.name}" if path.parent == Path("/tmp") else f"/tmp/{path.parent.name}/{path.name}"
    return path.name or "invalid-metadata-path"


def _safe_input_path(raw_metadata_path: str) -> tuple[Path | None, str, MetadataValidationIssue | None]:
    display_path = _sanitize_path(raw_metadata_path)
    raw = str(raw_metadata_path)
    path = Path(raw)
    if ".." in path.parts:
        return None, display_path, _issue("unsafe_input_path", "$.metadata_path", "metadata path must not contain traversal")
    if path.suffix.lower() != ".json":
        return None, display_path, _issue("unsupported_input_extension", "$.metadata_path", "metadata path must use .json")
    if raw.startswith("configs/animation/") and len(path.parts) == 3:
        candidate = REPO_ROOT / path
        display_path = raw
    elif path.is_absolute() and (path == Path("/tmp") or Path("/tmp") in path.parents):
        candidate = path
        display_path = _sanitize_path(raw)
    else:
        return None, display_path, _issue("input_path_not_allowlisted", "$.metadata_path", "metadata path must be configs/animation/<file>.json or /tmp/<file>.json")
    try:
        stat_result = candidate.lstat()
    except OSError:
        return None, display_path, _issue("input_file_unreadable", "$.metadata_path", "metadata file could not be inspected")
    if candidate.is_symlink():
        return None, display_path, _issue("input_symlink_rejected", "$.metadata_path", "metadata input symlinks are rejected")
    if not candidate.is_file():
        return None, display_path, _issue("input_not_regular_file", "$.metadata_path", "metadata input must be a regular file")
    if stat_result.st_size > MAX_INPUT_BYTES:
        return None, display_path, _issue("input_too_large", "$.metadata_path", "metadata input exceeds 512 KiB")
    return candidate, display_path, None


def load_animation_metadata(metadata_path: str) -> tuple[dict[str, Any] | None, str, list[MetadataValidationIssue], int]:
    candidate, display_path, path_issue = _safe_input_path(metadata_path)
    if path_issue is not None or candidate is None:
        return None, display_path, [path_issue] if path_issue else [], 2
    try:
        text = candidate.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None, display_path, [_issue("input_not_utf8", "$.metadata_path", "metadata must be valid UTF-8")], 2
    except OSError:
        return None, display_path, [_issue("input_file_unreadable", "$.metadata_path", "metadata file could not be read")], 2
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        return None, display_path, [_issue("malformed_json", "$.metadata_path", "metadata JSON is malformed")], 2
    if not isinstance(payload, dict):
        return None, display_path, [_issue("root_not_object", "$", "metadata root must be an object")], 1
    return payload, display_path, [], 0


def load_animation_metadata_schema() -> dict[str, Any]:
    try:
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError("animation metadata schema could not be loaded") from exc
    if not isinstance(schema, dict):
        raise ValueError("animation metadata schema root must be an object")
    return schema


def _is_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def _require_object(value: object, path: str, issues: list[MetadataValidationIssue]) -> dict[str, Any] | None:
    if not isinstance(value, dict):
        issues.append(_issue("type_mismatch", path, "value must be an object"))
        return None
    return value


def _check_unknown(value: dict[str, Any], allowed: set[str], path: str, issues: list[MetadataValidationIssue]) -> None:
    for key in sorted(set(value) - allowed):
        issues.append(_issue("unknown_field", f"{path}.{key}", "field is not allowed"))


def _check_required(value: dict[str, Any], required: set[str], path: str, issues: list[MetadataValidationIssue]) -> None:
    for key in sorted(required):
        if key not in value:
            issues.append(_issue("missing_required_field", f"{path}.{key}", "field is required"))


def _check_const(value: object, expected: object, path: str, issues: list[MetadataValidationIssue]) -> None:
    if value != expected or type(value) is not type(expected):  # noqa: E721
        issues.append(_issue("const_mismatch", path, f"value must be {json.dumps(expected)}"))


def _check_hash(value: object, path: str, issues: list[MetadataValidationIssue]) -> None:
    if not isinstance(value, str) or not HASH_RE.fullmatch(value):
        issues.append(_issue("invalid_sha256", path, "value must be 64 lowercase hex characters"))


def _check_safe_identifier(value: object, path: str, issues: list[MetadataValidationIssue]) -> None:
    if not isinstance(value, str):
        issues.append(_issue("type_mismatch", path, "value must be a string"))
        return
    if value.startswith(".") or re.match(r"^[A-Za-z]:", value) or value.startswith("//") or not SAFE_ID_RE.fullmatch(value):
        issues.append(_issue("unsafe_identifier", path, "identifier contains unsupported characters"))
        return
    if any(marker in value for marker in BLOCKED_ID_MARKERS):
        issues.append(_issue("unsafe_identifier", path, "identifier must not contain path, URL, runtime, repo, or model markers"))


def _check_timestamp(value: object, path: str, issues: list[MetadataValidationIssue]) -> None:
    if not isinstance(value, str) or not CREATED_AT_RE.fullmatch(value):
        issues.append(_issue("invalid_timestamp", path, "created_at must use YYYY-MM-DDTHH:MM:SSZ"))
        return
    try:
        datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=UTC)
    except ValueError:
        issues.append(_issue("invalid_timestamp", path, "created_at must be a real UTC calendar timestamp"))


def _check_sorted_unique(values: object, path: str, issues: list[MetadataValidationIssue], *, allowed: set[str] | None = None, safe_ids: bool = False, require_sorted: bool = True) -> None:
    if not isinstance(values, list):
        issues.append(_issue("type_mismatch", path, "value must be an array"))
        return
    if not values:
        issues.append(_issue("array_too_short", path, "array must not be empty"))
    string_values = [item for item in values if isinstance(item, str)]
    if len(string_values) != len(set(string_values)):
        issues.append(_issue("duplicate_value", path, "array must not contain duplicates"))
    if require_sorted and string_values == values and values != sorted(values):
        issues.append(_issue("array_not_sorted", path, "array must be sorted ascending"))
    for index, item in enumerate(values):
        item_path = f"{path}[{index}]"
        if not isinstance(item, str):
            issues.append(_issue("type_mismatch", item_path, "array item must be a string"))
            continue
        if allowed is not None and item not in allowed:
            issues.append(_issue("enum_mismatch", item_path, "array item is not allowlisted"))
        if safe_ids:
            _check_safe_identifier(item, item_path, issues)


def _is_safe_output_path(value: object, *, prefix: str, suffixes: tuple[str, ...], path: str, issues: list[MetadataValidationIssue]) -> None:
    if not isinstance(value, str) or not value:
        issues.append(_issue("type_mismatch", path, "output path must be a non-empty string"))
        return
    if value.startswith("/") or "\\" in value or "://" in value or re.match(r"^[A-Za-z]:", value):
        issues.append(_issue("unsafe_output_path", path, "output path must be a POSIX runtime-relative path"))
        return
    if any(marker in value for marker in BLOCKED_PATH_MARKERS):
        issues.append(_issue("unsafe_output_path", path, "output path contains blocked repo/runtime/model markers"))
        return
    candidate = Path(value)
    if candidate.is_absolute() or candidate.as_posix() != value or any(part in {"", ".", ".."} for part in candidate.parts):
        issues.append(_issue("unsafe_output_path", path, "output path must be normalized and traversal-free"))
        return
    if not value.startswith(prefix) or not value.endswith(suffixes):
        issues.append(_issue("unsafe_output_path", path, f"output path must stay under {prefix} and use an allowed extension"))


def validate_animation_metadata_structure(metadata: dict[str, Any], schema: dict[str, Any] | None = None) -> list[MetadataValidationIssue]:
    if schema is None:
        schema = load_animation_metadata_schema()
    issues: list[MetadataValidationIssue] = []
    if schema.get("$id") != "urn:moe:animation-metadata-schema:1.0":
        issues.append(_issue("schema_invalid", "$.schema", "metadata schema id is invalid"))

    _check_unknown(metadata, TOP_REQUIRED, "$", issues)
    _check_required(metadata, TOP_REQUIRED, "$", issues)
    _check_const(metadata.get("schema_version"), "1.0", "$.schema_version", issues)
    _check_const(metadata.get("metadata_type"), "animation_sidecar", "$.metadata_type", issues)
    _check_const(metadata.get("asset_type"), "animation", "$.asset_type", issues)
    _check_const(metadata.get("source"), "blender_animation_adapter", "$.source", issues)
    _check_const(metadata.get("generator_script"), "apps/media-worker/app/animation_metadata_sidecar.py", "$.generator_script", issues)
    _check_const(metadata.get("generator_version"), "0.1.0", "$.generator_version", issues)
    _check_safe_identifier(metadata.get("animation_id"), "$.animation_id", issues)
    if not isinstance(metadata.get("title"), str) or not metadata.get("title"):
        issues.append(_issue("type_mismatch", "$.title", "title must be a non-empty string"))
    _check_timestamp(metadata.get("created_at"), "$.created_at", issues)
    if metadata.get("source_kind") not in SOURCE_KINDS:
        issues.append(_issue("enum_mismatch", "$.source_kind", "source_kind is not allowlisted"))
    for key in ("source_request_sha256", "adapter_request_sha256", "canonical_plan_sha256", "operation_plan_sha256"):
        _check_hash(metadata.get(key), f"$.{key}", issues)
    _check_const(metadata.get("preview_available"), False, "$.preview_available", issues)
    _check_const(metadata.get("visual_reference_only"), True, "$.visual_reference_only", issues)
    _check_const(metadata.get("structural_certification"), False, "$.structural_certification", issues)
    _check_const(metadata.get("operator_review_required"), True, "$.operator_review_required", issues)
    _check_const(metadata.get("generation_mode"), "metadata_only", "$.generation_mode", issues)

    source_scene = _require_object(metadata.get("source_scene"), "$.source_scene", issues)
    if source_scene is not None:
        _check_unknown(source_scene, {"type", "reference_id", "units"}, "$.source_scene", issues)
        _check_required(source_scene, {"type", "reference_id", "units"}, "$.source_scene", issues)
        _check_const(source_scene.get("type"), "existing_runtime_3d_asset", "$.source_scene.type", issues)
        _check_safe_identifier(source_scene.get("reference_id"), "$.source_scene.reference_id", issues)
        if source_scene.get("units") not in {"meters", "centimeters", "millimeters"}:
            issues.append(_issue("enum_mismatch", "$.source_scene.units", "units are not allowlisted"))

    timeline = _require_object(metadata.get("timeline"), "$.timeline", issues)
    if timeline is not None:
        _check_unknown(timeline, {"fps", "start_frame", "end_frame", "total_frames", "duration_seconds"}, "$.timeline", issues)
        _check_required(timeline, {"fps", "start_frame", "end_frame", "total_frames", "duration_seconds"}, "$.timeline", issues)
        if not _is_int(timeline.get("fps")) or not 1 <= timeline.get("fps", 0) <= 120:
            issues.append(_issue("type_mismatch", "$.timeline.fps", "fps must be an integer in range 1..120"))
        if not _is_int(timeline.get("start_frame")) or timeline.get("start_frame", -1) < 0:
            issues.append(_issue("type_mismatch", "$.timeline.start_frame", "start_frame must be an integer >= 0"))
        if not _is_int(timeline.get("end_frame")):
            issues.append(_issue("type_mismatch", "$.timeline.end_frame", "end_frame must be an integer"))
        if not _is_int(timeline.get("total_frames")) or timeline.get("total_frames", 0) < 2:
            issues.append(_issue("type_mismatch", "$.timeline.total_frames", "total_frames must be an integer >= 2"))
        if not _is_number(timeline.get("duration_seconds")) or timeline.get("duration_seconds", 0) <= 0:
            issues.append(_issue("type_mismatch", "$.timeline.duration_seconds", "duration_seconds must be a finite number > 0"))

    summary = _require_object(metadata.get("animation_summary"), "$.animation_summary", issues)
    if summary is not None:
        _check_unknown(summary, {"track_count", "keyframe_count", "segment_count", "target_types", "target_ids", "properties", "interpolations"}, "$.animation_summary", issues)
        _check_required(summary, {"track_count", "keyframe_count", "segment_count", "target_types", "target_ids", "properties", "interpolations"}, "$.animation_summary", issues)
        for key, minimum in (("track_count", 1), ("keyframe_count", 1), ("segment_count", 0)):
            if not _is_int(summary.get(key)) or summary.get(key, -1) < minimum:
                issues.append(_issue("type_mismatch", f"$.animation_summary.{key}", f"{key} must be an integer >= {minimum}"))
        _check_sorted_unique(summary.get("target_types"), "$.animation_summary.target_types", issues, allowed=TARGET_TYPES)
        _check_sorted_unique(summary.get("target_ids"), "$.animation_summary.target_ids", issues, safe_ids=True)
        _check_sorted_unique(summary.get("properties"), "$.animation_summary.properties", issues, allowed=PROPERTIES)
        _check_sorted_unique(summary.get("interpolations"), "$.animation_summary.interpolations", issues, allowed=INTERPOLATIONS)

    adapter = _require_object(metadata.get("adapter_summary"), "$.adapter_summary", issues)
    if adapter is not None:
        _check_unknown(adapter, {"operation_count", "operation_types", "resolved_target_ids", "execution_status"}, "$.adapter_summary", issues)
        _check_required(adapter, {"operation_count", "operation_types", "resolved_target_ids", "execution_status"}, "$.adapter_summary", issues)
        if not _is_int(adapter.get("operation_count")) or adapter.get("operation_count", 0) < 1:
            issues.append(_issue("type_mismatch", "$.adapter_summary.operation_count", "operation_count must be an integer >= 1"))
        _check_sorted_unique(adapter.get("operation_types"), "$.adapter_summary.operation_types", issues, allowed=OPERATION_TYPES)
        _check_sorted_unique(adapter.get("resolved_target_ids"), "$.adapter_summary.resolved_target_ids", issues, safe_ids=True, require_sorted=False)
        _check_const(adapter.get("execution_status"), "not_executed", "$.adapter_summary.execution_status", issues)

    output_files = _require_object(metadata.get("output_files"), "$.output_files", issues)
    if output_files is not None:
        _check_unknown(output_files, {"preview", "metadata", "report"}, "$.output_files", issues)
        _check_required(output_files, {"preview", "metadata", "report"}, "$.output_files", issues)
        _is_safe_output_path(output_files.get("preview"), prefix="media/animation/previews/", suffixes=(".mp4", ".webm", ".gif"), path="$.output_files.preview", issues=issues)
        _is_safe_output_path(output_files.get("metadata"), prefix="media/animation/metadata/", suffixes=(".json",), path="$.output_files.metadata", issues=issues)
        _check_const(output_files.get("report"), None, "$.output_files.report", issues)

    validation = _require_object(metadata.get("validation"), "$.validation", issues)
    if validation is not None:
        allowed = {"adapter_request_valid", "canonical_plan_valid", "timeline_plan_valid", "operation_plan_valid"}
        _check_unknown(validation, allowed, "$.validation", issues)
        _check_required(validation, allowed, "$.validation", issues)
        for key in sorted(allowed):
            _check_const(validation.get(key), True, f"$.validation.{key}", issues)

    warnings = metadata.get("warnings")
    if not isinstance(warnings, list):
        issues.append(_issue("type_mismatch", "$.warnings", "warnings must be an array"))
    else:
        if len(warnings) > 100:
            issues.append(_issue("array_too_long", "$.warnings", "warnings must contain at most 100 items"))
        if len(warnings) != len(set(warnings)):
            issues.append(_issue("duplicate_warning", "$.warnings", "warnings must not contain duplicates", severity="warning"))
        for index, warning in enumerate(warnings):
            if not isinstance(warning, str) or len(warning) > 500:
                issues.append(_issue("type_mismatch", f"$.warnings[{index}]", "warning must be a string of at most 500 characters"))

    safety = _require_object(metadata.get("safety_flags"), "$.safety_flags", issues)
    if safety is not None:
        _check_unknown(safety, SAFETY_REQUIRED, "$.safety_flags", issues)
        _check_required(safety, SAFETY_REQUIRED, "$.safety_flags", issues)
        if not isinstance(safety.get("metadata_written"), bool):
            issues.append(_issue("type_mismatch", "$.safety_flags.metadata_written", "metadata_written must be boolean"))
        _check_const(safety.get("read_only_inputs"), True, "$.safety_flags.read_only_inputs", issues)
        for key in sorted(SAFETY_REQUIRED - {"metadata_written", "read_only_inputs"}):
            _check_const(safety.get(key), False, f"$.safety_flags.{key}", issues)
    return _sort_issues(issues)


def validate_animation_metadata_semantics(metadata: dict[str, Any]) -> list[MetadataValidationIssue]:
    issues: list[MetadataValidationIssue] = []
    timeline = metadata.get("timeline")
    if isinstance(timeline, dict):
        fps = timeline.get("fps")
        start = timeline.get("start_frame")
        end = timeline.get("end_frame")
        total = timeline.get("total_frames")
        duration = timeline.get("duration_seconds")
        if _is_int(start) and _is_int(end) and end <= start:
            issues.append(_issue("timeline_invalid_range", "$.timeline.end_frame", "end_frame must be greater than start_frame"))
        if _is_int(start) and _is_int(end) and _is_int(total) and total != end - start + 1:
            issues.append(_issue("timeline_total_frames_mismatch", "$.timeline.total_frames", "total_frames must equal end_frame - start_frame + 1"))
        if _is_int(fps) and fps > 0 and _is_int(total) and _is_number(duration):
            expected = total / fps
            tolerance = max(0.001, 0.5 / fps)
            if abs(float(duration) - expected) > tolerance:
                issues.append(_issue("timeline_duration_mismatch", "$.timeline.duration_seconds", "duration_seconds must match total_frames / fps"))
    summary = metadata.get("animation_summary")
    if isinstance(summary, dict):
        track_count = summary.get("track_count")
        keyframe_count = summary.get("keyframe_count")
        segment_count = summary.get("segment_count")
        if _is_int(track_count) and _is_int(keyframe_count) and keyframe_count < track_count:
            issues.append(_issue("summary_count_mismatch", "$.animation_summary.keyframe_count", "keyframe_count must be >= track_count"))
        if _is_int(segment_count) and _is_int(keyframe_count) and segment_count > keyframe_count:
            issues.append(_issue("summary_count_mismatch", "$.animation_summary.segment_count", "segment_count must be <= keyframe_count"))
    return _sort_issues(issues)


def _canonical_json(value: dict[str, Any]) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)


def validate_animation_metadata_provenance(metadata: dict[str, Any], adapter_request_path: str) -> tuple[list[MetadataValidationIssue], str, int]:
    from animation_metadata_sidecar import build_animation_metadata_sidecar, canonical_payload_hash
    from blender_animation_adapter import (
        build_blender_animation_operation_plan,
        load_adapter_request,
        validate_adapter_request,
    )

    loaded = load_adapter_request(adapter_request_path)
    display_path = loaded.display_path
    if loaded.issues or loaded.request is None:
        return [_issue("adapter_request_invalid", "$.adapter_request", "adapter request could not be loaded or parsed")], display_path, loaded.exit_code
    adapter_issues = validate_adapter_request(loaded.request)
    if adapter_issues:
        issues = [_issue("adapter_request_invalid", "$.adapter_request", "adapter request failed M36.7 validation")]
        canonical = loaded.request.get("canonical_animation_plan")
        timeline = loaded.request.get("timeline_plan")
        if isinstance(canonical, dict) and isinstance(timeline, dict):
            try:
                canonical_hash = canonical_payload_hash(canonical)
            except (TypeError, ValueError):
                canonical_hash = None
            if canonical_hash is not None and timeline.get("source_plan_sha256") != canonical_hash:
                issues.append(_issue("timeline_plan_hash_mismatch", "$.timeline.source_plan_sha256", "adapter timeline source hash does not match canonical plan"))
        return _sort_issues(issues), display_path, 1
    plan_result = build_blender_animation_operation_plan(loaded.request)
    if not plan_result.valid or plan_result.operation_plan is None:
        return [_issue("adapter_request_invalid", "$.adapter_request", "operation plan could not be rebuilt")], display_path, 1

    issues: list[MetadataValidationIssue] = []
    adapter_hash = canonical_payload_hash(loaded.request)
    canonical_hash = canonical_payload_hash(loaded.request["canonical_animation_plan"])
    operation_hash = canonical_payload_hash(plan_result.operation_plan)
    if metadata.get("source_request_sha256") != loaded.request.get("source_request_sha256"):
        issues.append(_issue("source_request_hash_mismatch", "$.source_request_sha256", "source request hash does not match adapter request"))
    if metadata.get("adapter_request_sha256") != adapter_hash:
        issues.append(_issue("adapter_request_hash_mismatch", "$.adapter_request_sha256", "adapter request hash does not match regenerated value"))
    if metadata.get("canonical_plan_sha256") != canonical_hash:
        issues.append(_issue("canonical_plan_hash_mismatch", "$.canonical_plan_sha256", "canonical plan hash does not match regenerated value"))
    if metadata.get("operation_plan_sha256") != operation_hash:
        issues.append(_issue("operation_plan_hash_mismatch", "$.operation_plan_sha256", "operation plan hash does not match regenerated value"))
    if loaded.request["timeline_plan"].get("source_plan_sha256") != canonical_hash:
        issues.append(_issue("timeline_plan_hash_mismatch", "$.timeline.source_plan_sha256", "adapter timeline source hash does not match canonical plan"))

    try:
        rebuilt = build_animation_metadata_sidecar(
            loaded.request,
            plan_result.operation_plan,
            created_at=metadata.get("created_at"),
            metadata_written=metadata.get("safety_flags", {}).get("metadata_written", False),
        )
    except ValueError:
        issues.append(_issue("metadata_rebuild_mismatch", "$", "metadata could not be rebuilt from provenance inputs"))
        return _sort_issues(issues), display_path, 1
    if metadata.get("animation_summary") != rebuilt.get("animation_summary") or metadata.get("adapter_summary") != rebuilt.get("adapter_summary"):
        issues.append(_issue("metadata_summary_mismatch", "$.animation_summary", "metadata summaries do not match rebuilt metadata"))
    if metadata.get("output_files") != rebuilt.get("output_files"):
        issues.append(_issue("metadata_output_reference_mismatch", "$.output_files", "output references do not match rebuilt metadata"))
    if _canonical_json(metadata) != _canonical_json(rebuilt):
        issues.append(_issue("metadata_rebuild_mismatch", "$", "metadata does not exactly match rebuilt provenance metadata"))
    return _sort_issues(issues), display_path, 1 if issues else 0


def _summary(metadata: dict[str, Any] | None) -> dict[str, Any]:
    metadata = metadata or {}
    timeline = metadata.get("timeline") if isinstance(metadata.get("timeline"), dict) else {}
    animation_summary = metadata.get("animation_summary") if isinstance(metadata.get("animation_summary"), dict) else {}
    adapter_summary = metadata.get("adapter_summary") if isinstance(metadata.get("adapter_summary"), dict) else {}
    safety = metadata.get("safety_flags") if isinstance(metadata.get("safety_flags"), dict) else {}
    return {
        "animation_id": metadata.get("animation_id") if isinstance(metadata.get("animation_id"), str) else None,
        "source_kind": metadata.get("source_kind") if isinstance(metadata.get("source_kind"), str) else None,
        "fps": timeline.get("fps") if _is_int(timeline.get("fps")) else None,
        "start_frame": timeline.get("start_frame") if _is_int(timeline.get("start_frame")) else None,
        "end_frame": timeline.get("end_frame") if _is_int(timeline.get("end_frame")) else None,
        "track_count": animation_summary.get("track_count") if _is_int(animation_summary.get("track_count")) else None,
        "keyframe_count": animation_summary.get("keyframe_count") if _is_int(animation_summary.get("keyframe_count")) else None,
        "operation_count": adapter_summary.get("operation_count") if _is_int(adapter_summary.get("operation_count")) else None,
        "metadata_written": safety.get("metadata_written") if isinstance(safety.get("metadata_written"), bool) else None,
    }


def build_animation_metadata_validation_report(
    metadata_path: str,
    adapter_request_path: str | None,
    metadata: dict[str, Any] | None,
    issues: list[MetadataValidationIssue],
    *,
    validation_mode: str,
    provenance_checked: bool,
) -> dict[str, Any]:
    sorted_issues = _sort_issues(issues)
    errors = [issue.as_report_item() for issue in sorted_issues if issue.severity == "error"]
    warnings = [issue.as_report_item() for issue in sorted_issues if issue.severity == "warning"]
    safety = metadata.get("safety_flags", {}) if isinstance(metadata, dict) and isinstance(metadata.get("safety_flags"), dict) else {}
    return {
        "schema_version": "1.0",
        "report_type": "animation_metadata_validation",
        "metadata_path": metadata_path,
        "adapter_request_path": adapter_request_path,
        "validation_mode": validation_mode,
        "provenance_checked": provenance_checked,
        "valid": len(errors) == 0,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "summary": _summary(metadata),
        "safety_flags": {
            "read_only": True,
            "metadata_written": safety.get("metadata_written") if isinstance(safety.get("metadata_written"), bool) else False,
            "runtime_assets_written": False,
            "source_assets_modified": False,
            "generation_triggered": False,
            "blender_execution_attempted": False,
            "preview_render_attempted": False,
            "external_process_started": False,
        },
    }


def validate_animation_metadata(metadata_path: str, adapter_request_path: str | None = None) -> tuple[dict[str, Any], int]:
    try:
        schema = load_animation_metadata_schema()
    except ValueError:
        issue = _issue("schema_load_failed", "$.schema", "animation metadata schema could not be loaded")
        return build_animation_metadata_validation_report(_sanitize_path(metadata_path), None, None, [issue], validation_mode="standalone", provenance_checked=False), 2
    metadata, display_path, load_issues, load_exit = load_animation_metadata(metadata_path)
    if load_issues or metadata is None:
        return build_animation_metadata_validation_report(display_path, None, metadata, load_issues, validation_mode="standalone", provenance_checked=False), load_exit
    issues = validate_animation_metadata_structure(metadata, schema)
    if not [issue for issue in issues if issue.severity == "error"]:
        issues.extend(validate_animation_metadata_semantics(metadata))
    validation_mode = "standalone"
    provenance_checked = False
    adapter_display_path = None
    provenance_exit = 0
    if adapter_request_path is not None:
        validation_mode = "provenance"
        provenance_checked = True
        provenance_issues, adapter_display_path, provenance_exit = validate_animation_metadata_provenance(metadata, adapter_request_path)
        issues.extend(provenance_issues)
    report = build_animation_metadata_validation_report(display_path, adapter_display_path, metadata, issues, validation_mode=validation_mode, provenance_checked=provenance_checked)
    if report["valid"]:
        return report, 0
    return report, provenance_exit if provenance_exit == 2 else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Validate an animation metadata sidecar without writing files.")
    parser.add_argument("--metadata", required=True, help="Metadata JSON under configs/animation or /tmp.")
    parser.add_argument("--adapter-request", help="Optional adapter request JSON for full provenance validation.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON validation report.")
    return parser


def run(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    report, exit_code = validate_animation_metadata(args.metadata, adapter_request_path=args.adapter_request)
    print(json.dumps(report, indent=2 if args.pretty else None, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(run())
