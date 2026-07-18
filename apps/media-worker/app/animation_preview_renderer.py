#!/usr/bin/env python3
"""Guarded sampled-frame animation preview renderer for M36.11."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

sys.dont_write_bytecode = True

from animation_timeline_planner import canonical_plan_hash  # noqa: E402
from blender_animation_adapter import (  # noqa: E402
    AdapterIssue,
    _execute_with_bpy_module,
    build_blender_animation_operation_plan,
    load_adapter_request,
    validate_adapter_request,
    validate_blender_animation_operation_plan,
)


REPO_ROOT = Path(__file__).resolve().parents[3]
CONFIG_ROOT = REPO_ROOT / "configs" / "animation"
SCHEMA_PATH = CONFIG_ROOT / "preview-render-request.schema.json"
RUNTIME_ROOT = Path("/home/cuneyt/MoE/runtime")
PREVIEW_ROOT = RUNTIME_ROOT / "media" / "animation" / "previews"
MAX_INPUT_BYTES = 512 * 1024
MAX_PIXEL_BUDGET = 24 * 1920 * 1080
MAX_OUTPUT_BYTES = 536870912
REQUEST_TYPE = "animation_preview_render_request"
PLAN_TYPE = "animation_preview_render_operation_plan"
RESULT_TYPE = "animation_preview_render_result"
REPORT_TYPE = "animation_preview_renderer"
SAFE_ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
OPERATION_ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
HASH_RE = re.compile(r"^[a-f0-9]{64}$")
SOURCE_KINDS = {"camera_animation_plan", "object_transform_animation_plan"}
OPERATION_ORDER = [
    "validate_preview_request",
    "validate_adapter_request",
    "resolve_camera",
    "select_preview_frames",
    "validate_output_directory",
    "snapshot_render_settings",
    "apply_animation_operations",
    "configure_preview_render",
    "render_preview_frame",
    "verify_preview_frame",
    "restore_render_settings",
    "publish_preview_directory",
]
FORBIDDEN_OPERATION_TYPES = {
    "run_ffmpeg",
    "encode_video",
    "save_blend",
    "create_camera",
    "create_object",
    "delete_object",
    "run_shell",
    "execute_python",
    "launch_blender",
    "upload_artifact",
}
BLOCKED_MARKERS = (
    "/home/",
    "/mnt/",
    "/media/",
    "/workspace/",
    "/app/",
    "MoE_Models_Backup",
    "DiskD/Projects/MoE/codebase",
)
SAFETY_FLAGS = {
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
}


@dataclass(frozen=True)
class PreviewIssue:
    code: str
    path: str
    message: str

    def as_report_item(self) -> dict[str, str]:
        return {"code": self.code, "path": self.path, "message": self.message}


@dataclass(frozen=True)
class PreviewRequestResult:
    request: dict[str, Any] | None
    display_path: str
    issues: tuple[PreviewIssue, ...]
    exit_code: int = 0


def _issue(code: str, path: str, message: str) -> PreviewIssue:
    return PreviewIssue(code=code, path=path, message=message)


def _sort_issues(issues: list[Any] | tuple[Any, ...]) -> tuple[Any, ...]:
    return tuple(sorted(issues, key=lambda item: (item.path, item.code, item.message)))


def _issue_items(issues: list[Any] | tuple[Any, ...]) -> list[dict[str, str]]:
    return [issue.as_report_item() for issue in _sort_issues(issues)]


def _is_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_bool(value: object) -> bool:
    return isinstance(value, bool)


def _sanitize_path(raw_path: str) -> str:
    raw = str(raw_path)
    path = Path(raw)
    if raw.startswith("configs/animation/"):
        return raw
    if path.is_absolute() and path.parent == Path("/tmp"):
        return f"/tmp/{path.name}"
    return path.name or "invalid-preview-request-path"


def _safe_input_path(raw_request_path: str) -> tuple[Path | None, str, PreviewIssue | None]:
    raw = str(raw_request_path)
    path = Path(raw)
    display_path = _sanitize_path(raw)
    if ".." in path.parts:
        return None, display_path, _issue("unsafe_input_path", "$.preview_request", "request path must not contain traversal")
    if path.suffix.lower() != ".json":
        return None, display_path, _issue("unsupported_input_extension", "$.preview_request", "preview request must use .json")
    if raw.startswith("configs/animation/") and len(path.parts) == 3:
        candidate = REPO_ROOT / path
        display_path = raw
    elif path.is_absolute() and path.parent == Path("/tmp"):
        candidate = path
        display_path = f"/tmp/{path.name}"
    else:
        return None, display_path, _issue("input_path_not_allowlisted", "$.preview_request", "request path must be configs/animation/<file>.json or /tmp/<file>.json")
    try:
        stat_result = candidate.lstat()
    except OSError:
        return None, display_path, _issue("input_file_unreadable", "$.preview_request", "request file could not be inspected")
    if candidate.is_symlink():
        return None, display_path, _issue("input_symlink_rejected", "$.preview_request", "preview request symlinks are rejected")
    if not candidate.is_file():
        return None, display_path, _issue("input_not_regular_file", "$.preview_request", "preview request must be a regular file")
    if stat_result.st_size > MAX_INPUT_BYTES:
        return None, display_path, _issue("input_too_large", "$.preview_request", "preview request exceeds 512 KiB")
    return candidate, display_path, None


def load_preview_render_request(request_path: str) -> PreviewRequestResult:
    candidate, display_path, path_issue = _safe_input_path(request_path)
    if path_issue is not None or candidate is None:
        return PreviewRequestResult(None, display_path, tuple([path_issue] if path_issue else []), 2)
    try:
        text = candidate.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return PreviewRequestResult(None, display_path, (_issue("input_not_utf8", "$.preview_request", "preview request must be valid UTF-8"),), 2)
    except OSError:
        return PreviewRequestResult(None, display_path, (_issue("input_file_unreadable", "$.preview_request", "preview request could not be read"),), 2)
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        return PreviewRequestResult(None, display_path, (_issue("malformed_json", "$.preview_request", "preview request JSON is malformed"),), 2)
    if not isinstance(payload, dict):
        return PreviewRequestResult(None, display_path, (_issue("root_not_object", "$", "preview request root must be an object"),), 1)
    return PreviewRequestResult(payload, display_path, tuple(), 0)


def load_preview_render_schema() -> dict[str, Any]:
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


def _check_unknown(value: dict[str, Any], allowed: set[str], path: str, issues: list[PreviewIssue]) -> None:
    for key in sorted(set(value) - allowed):
        issues.append(_issue("unknown_field", f"{path}.{key}", "field is not allowed"))


def _check_required(value: dict[str, Any], required: set[str], path: str, issues: list[PreviewIssue]) -> None:
    for key in sorted(required):
        if key not in value:
            issues.append(_issue("missing_required_field", f"{path}.{key}", "field is required"))


def _check_const(value: object, expected: object, path: str, issues: list[PreviewIssue]) -> None:
    if value != expected or type(value) is not type(expected):  # noqa: E721
        issues.append(_issue("const_mismatch", path, f"value must be {json.dumps(expected)}"))


def _check_hash(value: object, path: str, issues: list[PreviewIssue]) -> None:
    if not isinstance(value, str) or not HASH_RE.fullmatch(value):
        issues.append(_issue("invalid_sha256", path, "value must be 64 lowercase hex characters"))


def _check_safe_id(value: object, path: str, issues: list[PreviewIssue]) -> str | None:
    if not isinstance(value, str):
        issues.append(_issue("type_mismatch", path, "value must be a string"))
        return None
    if len(value) > 80 or not SAFE_ID_RE.fullmatch(value) or any(marker in value for marker in ("/", "\\", "..", "://", "/home/", "/mnt/", "/media/", "/workspace/", "/app/", "MoE_Models_Backup")):
        issues.append(_issue("unsafe_identifier", path, "identifier must match ^[a-z0-9][a-z0-9-]*$ and contain no path markers"))
    return value


def _check_runtime_relative_directory(value: object, preview_id: str | None, path: str, issues: list[PreviewIssue]) -> str | None:
    if not isinstance(value, str):
        issues.append(_issue("type_mismatch", path, "relative runtime directory must be a string"))
        return None
    if value.startswith("/") or "\\" in value or "://" in value or re.match(r"^[A-Za-z]:", value):
        issues.append(_issue("unsafe_output_path", path, "relative runtime directory must be POSIX relative"))
        return value
    if any(marker in value for marker in BLOCKED_MARKERS):
        issues.append(_issue("unsafe_output_path", path, "relative runtime directory contains a blocked path marker"))
    parts = Path(value).parts
    if any(part in {"", ".", ".."} for part in parts) or Path(value).as_posix() != value:
        issues.append(_issue("unsafe_output_path", path, "relative runtime directory must not contain empty, dot, or traversal segments"))
    expected = f"media/animation/previews/{preview_id}/frames" if preview_id else None
    if expected is not None and value != expected:
        issues.append(_issue("preview_output_mismatch", path, "output directory must be media/animation/previews/<preview_id>/frames"))
    return value


def validate_preview_render_request_structure(request: dict[str, Any]) -> tuple[PreviewIssue, ...]:
    issues: list[PreviewIssue] = []
    if not isinstance(request, dict):
        return (_issue("type_mismatch", "$", "preview request must be an object"),)
    root_required = {"schema_version", "request_type", "preview_id", "source_kind", "source_request_sha256", "canonical_plan_sha256", "camera_id", "render_mode", "frame_selection", "render", "output", "limits", "safety"}
    _check_unknown(request, root_required, "$", issues)
    _check_required(request, root_required, "$", issues)
    _check_const(request.get("schema_version"), "1.0", "$.schema_version", issues)
    _check_const(request.get("request_type"), REQUEST_TYPE, "$.request_type", issues)
    preview_id = _check_safe_id(request.get("preview_id"), "$.preview_id", issues)
    _check_safe_id(request.get("camera_id"), "$.camera_id", issues)
    if request.get("source_kind") not in SOURCE_KINDS:
        issues.append(_issue("enum_mismatch", "$.source_kind", "source_kind must be camera_animation_plan or object_transform_animation_plan"))
    _check_hash(request.get("source_request_sha256"), "$.source_request_sha256", issues)
    _check_hash(request.get("canonical_plan_sha256"), "$.canonical_plan_sha256", issues)
    _check_const(request.get("render_mode"), "sampled_frames", "$.render_mode", issues)

    frame_selection = request.get("frame_selection")
    if not isinstance(frame_selection, dict):
        issues.append(_issue("type_mismatch", "$.frame_selection", "frame_selection must be an object"))
    else:
        allowed = {"sample_count", "include_start_frame", "include_end_frame"}
        _check_unknown(frame_selection, allowed, "$.frame_selection", issues)
        _check_required(frame_selection, allowed, "$.frame_selection", issues)
        sample_count = frame_selection.get("sample_count")
        if not _is_int(sample_count) or sample_count < 2 or sample_count > 24:
            issues.append(_issue("invalid_sample_count", "$.frame_selection.sample_count", "sample_count must be an integer from 2 through 24"))
        _check_const(frame_selection.get("include_start_frame"), True, "$.frame_selection.include_start_frame", issues)
        _check_const(frame_selection.get("include_end_frame"), True, "$.frame_selection.include_end_frame", issues)

    render = request.get("render")
    if not isinstance(render, dict):
        issues.append(_issue("type_mismatch", "$.render", "render must be an object"))
    else:
        allowed = {"engine", "format", "width", "height", "resolution_percentage", "transparent_background"}
        _check_unknown(render, allowed, "$.render", issues)
        _check_required(render, allowed, "$.render", issues)
        _check_const(render.get("engine"), "BLENDER_EEVEE_NEXT", "$.render.engine", issues)
        _check_const(render.get("format"), "PNG", "$.render.format", issues)
        width = render.get("width")
        height = render.get("height")
        if not _is_int(width) or width < 64 or width > 1920:
            issues.append(_issue("invalid_resolution", "$.render.width", "width must be an integer from 64 through 1920"))
        if not _is_int(height) or height < 64 or height > 1080:
            issues.append(_issue("invalid_resolution", "$.render.height", "height must be an integer from 64 through 1080"))
        _check_const(render.get("resolution_percentage"), 100, "$.render.resolution_percentage", issues)
        if not _is_bool(render.get("transparent_background")):
            issues.append(_issue("type_mismatch", "$.render.transparent_background", "transparent_background must be a boolean"))

    output = request.get("output")
    if not isinstance(output, dict):
        issues.append(_issue("type_mismatch", "$.output", "output must be an object"))
    else:
        allowed = {"relative_runtime_directory", "filename_pattern", "overwrite_existing"}
        _check_unknown(output, allowed, "$.output", issues)
        _check_required(output, allowed, "$.output", issues)
        _check_runtime_relative_directory(output.get("relative_runtime_directory"), preview_id, "$.output.relative_runtime_directory", issues)
        _check_const(output.get("filename_pattern"), "frame-{frame:06d}.png", "$.output.filename_pattern", issues)
        _check_const(output.get("overwrite_existing"), False, "$.output.overwrite_existing", issues)

    limits = request.get("limits")
    if not isinstance(limits, dict):
        issues.append(_issue("type_mismatch", "$.limits", "limits must be an object"))
    else:
        allowed = {"max_frames", "max_total_output_bytes", "timeout_seconds"}
        _check_unknown(limits, allowed, "$.limits", issues)
        _check_required(limits, allowed, "$.limits", issues)
        _check_const(limits.get("max_frames"), 24, "$.limits.max_frames", issues)
        _check_const(limits.get("max_total_output_bytes"), MAX_OUTPUT_BYTES, "$.limits.max_total_output_bytes", issues)
        timeout = limits.get("timeout_seconds")
        if not _is_int(timeout) or timeout < 1 or timeout > 300:
            issues.append(_issue("invalid_timeout", "$.limits.timeout_seconds", "timeout_seconds must be an integer from 1 through 300"))

    safety = request.get("safety")
    if not isinstance(safety, dict):
        issues.append(_issue("type_mismatch", "$.safety", "safety must be an object"))
    else:
        allowed = {"real_animation_enabled", "preview_render_enabled", "runtime_write_planned", "blend_file_save_planned", "video_encode_planned", "external_process_planned"}
        _check_unknown(safety, allowed, "$.safety", issues)
        _check_required(safety, allowed, "$.safety", issues)
        for key in sorted(allowed):
            _check_const(safety.get(key), False, f"$.safety.{key}", issues)
    return _sort_issues(issues)


def select_preview_frames(start_frame: int, end_frame: int, sample_count: int) -> tuple[int, ...]:
    if not _is_int(start_frame) or not _is_int(end_frame) or not _is_int(sample_count):
        raise ValueError("frame inputs must be integers")
    if end_frame < start_frame:
        raise ValueError("end_frame must be greater than or equal to start_frame")
    total_frames = end_frame - start_frame + 1
    if sample_count < 2 or sample_count > 24 or sample_count > total_frames:
        raise ValueError("sample_count is outside allowed frame range")
    frames = tuple(start_frame + (index * (end_frame - start_frame)) // (sample_count - 1) for index in range(sample_count))
    if frames[0] != start_frame or frames[-1] != end_frame or any(left >= right for left, right in zip(frames, frames[1:])):
        raise ValueError("selected frames must include endpoints and be strictly increasing")
    return frames


def validate_preview_render_request_semantics(request: dict[str, Any], adapter_request: dict[str, Any] | None = None) -> tuple[PreviewIssue, ...]:
    issues: list[PreviewIssue] = []
    frame_selection = request.get("frame_selection", {}) if isinstance(request.get("frame_selection"), dict) else {}
    render = request.get("render", {}) if isinstance(request.get("render"), dict) else {}
    limits = request.get("limits", {}) if isinstance(request.get("limits"), dict) else {}
    sample_count = frame_selection.get("sample_count")
    width = render.get("width")
    height = render.get("height")
    if _is_int(sample_count) and _is_int(limits.get("max_frames")) and sample_count > limits["max_frames"]:
        issues.append(_issue("sample_count_exceeds_max_frames", "$.frame_selection.sample_count", "sample_count must not exceed limits.max_frames"))
    if _is_int(sample_count) and _is_int(width) and _is_int(height) and sample_count * width * height > MAX_PIXEL_BUDGET:
        issues.append(_issue("pixel_budget_exceeded", "$.render", "sample_count * width * height exceeds 49,766,400 pixels"))
    if adapter_request is not None:
        if request.get("source_kind") != adapter_request.get("source_kind"):
            issues.append(_issue("source_kind_mismatch", "$.source_kind", "preview source_kind must match adapter request"))
        if request.get("source_request_sha256") != adapter_request.get("source_request_sha256"):
            issues.append(_issue("source_request_hash_mismatch", "$.source_request_sha256", "preview source_request_sha256 must match adapter request"))
        canonical = adapter_request.get("canonical_animation_plan")
        if isinstance(canonical, dict):
            actual_hash = canonical_plan_hash(canonical)
            if request.get("canonical_plan_sha256") != actual_hash:
                issues.append(_issue("canonical_plan_hash_mismatch", "$.canonical_plan_sha256", "preview canonical_plan_sha256 must match canonical plan"))
            timeline = canonical.get("timeline", {})
            if isinstance(timeline, dict) and _is_int(sample_count):
                total_frames = timeline.get("end_frame", 0) - timeline.get("start_frame", 0) + 1
                if sample_count > total_frames:
                    issues.append(_issue("sample_count_exceeds_timeline", "$.frame_selection.sample_count", "sample_count must not exceed timeline total frames"))
                else:
                    try:
                        select_preview_frames(timeline["start_frame"], timeline["end_frame"], sample_count)
                    except (KeyError, ValueError) as exc:
                        issues.append(_issue("frame_selection_invalid", "$.frame_selection.sample_count", str(exc)))
    return _sort_issues(issues)


def _operation(operation_id: str, operation_type: str, **extra: Any) -> dict[str, Any]:
    payload = {"operation_id": operation_id, "operation_type": operation_type}
    payload.update(extra)
    return payload


def build_preview_render_operation_plan(request: dict[str, Any], adapter_request: dict[str, Any], adapter_operation_plan: dict[str, Any]) -> dict[str, Any]:
    timeline = adapter_request["canonical_animation_plan"]["timeline"]
    frames = select_preview_frames(timeline["start_frame"], timeline["end_frame"], request["frame_selection"]["sample_count"])
    operations = [
        _operation("validate-preview-request", "validate_preview_request"),
        _operation("validate-adapter-request", "validate_adapter_request"),
        _operation("resolve-camera-" + request["camera_id"], "resolve_camera", camera_id=request["camera_id"], fallback_allowed=False, create_if_missing=False),
        _operation("select-preview-frames", "select_preview_frames", formula="start_frame + (i * (end_frame - start_frame)) // (sample_count - 1)"),
        _operation("validate-output-directory", "validate_output_directory", overwrite_existing=False),
        _operation("snapshot-render-settings", "snapshot_render_settings"),
        _operation("apply-animation-operations", "apply_animation_operations", requires_m36_7_guards=True, adapter_operation_count=adapter_operation_plan["operation_count"]),
        _operation("configure-preview-render", "configure_preview_render", engine="BLENDER_EEVEE_NEXT", format="PNG", width=request["render"]["width"], height=request["render"]["height"]),
        _operation("render-preview-frame", "render_preview_frame", filename_pattern="frame-{frame:06d}.png"),
        _operation("verify-preview-frame", "verify_preview_frame"),
        _operation("restore-render-settings", "restore_render_settings"),
        _operation("publish-preview-directory", "publish_preview_directory", atomic_publish_required=True),
    ]
    return {
        "schema_version": "1.0",
        "plan_type": PLAN_TYPE,
        "status": "planned",
        "preview_id": request["preview_id"],
        "render_mode": "sampled_frames",
        "source_kind": request["source_kind"],
        "source_request_sha256": request["source_request_sha256"],
        "canonical_plan_sha256": request["canonical_plan_sha256"],
        "frames": list(frames),
        "relative_output_directory": request["output"]["relative_runtime_directory"],
        "operation_types": [operation["operation_type"] for operation in operations],
        "operation_count": len(operations),
        "operations": operations,
        "safety_flags": dict(SAFETY_FLAGS),
    }


def validate_preview_render_operation_plan(operation_plan: dict[str, Any]) -> tuple[PreviewIssue, ...]:
    issues: list[PreviewIssue] = []
    if not isinstance(operation_plan, dict):
        return (_issue("type_mismatch", "$", "operation plan must be an object"),)
    if operation_plan.get("schema_version") != "1.0":
        issues.append(_issue("const_mismatch", "$.schema_version", "schema_version must be 1.0"))
    if operation_plan.get("plan_type") != PLAN_TYPE:
        issues.append(_issue("const_mismatch", "$.plan_type", f"plan_type must be {PLAN_TYPE}"))
    if operation_plan.get("status") != "planned":
        issues.append(_issue("const_mismatch", "$.status", "status must be planned"))
    _check_safe_id(operation_plan.get("preview_id"), "$.preview_id", issues)
    _check_hash(operation_plan.get("source_request_sha256"), "$.source_request_sha256", issues)
    _check_hash(operation_plan.get("canonical_plan_sha256"), "$.canonical_plan_sha256", issues)
    frames = operation_plan.get("frames")
    if not isinstance(frames, list) or not frames or not all(_is_int(frame) for frame in frames):
        issues.append(_issue("type_mismatch", "$.frames", "frames must be a non-empty integer array"))
    elif any(left >= right for left, right in zip(frames, frames[1:])):
        issues.append(_issue("frames_not_increasing", "$.frames", "frames must be strictly increasing"))
    _check_runtime_relative_directory(operation_plan.get("relative_output_directory"), operation_plan.get("preview_id"), "$.relative_output_directory", issues)
    operations = operation_plan.get("operations")
    if not isinstance(operations, list):
        issues.append(_issue("type_mismatch", "$.operations", "operations must be an array"))
        return _sort_issues(issues)
    if operation_plan.get("operation_count") != len(operations):
        issues.append(_issue("operation_count_mismatch", "$.operation_count", "operation_count must match operations length"))
    operation_types = [operation.get("operation_type") if isinstance(operation, dict) else None for operation in operations]
    if operation_types != OPERATION_ORDER:
        issues.append(_issue("operation_order_invalid", "$.operation_types", "operation types must match the M36.10 order exactly"))
    if operation_plan.get("operation_types") != OPERATION_ORDER:
        issues.append(_issue("operation_summary_mismatch", "$.operation_types", "operation_types must match operations in order"))
    seen_ids: set[str] = set()
    for index, operation in enumerate(operations):
        path = f"$.operations[{index}]"
        if not isinstance(operation, dict):
            issues.append(_issue("type_mismatch", path, "operation must be an object"))
            continue
        operation_id = operation.get("operation_id")
        if not isinstance(operation_id, str) or not OPERATION_ID_RE.fullmatch(operation_id):
            issues.append(_issue("unsafe_operation_id", f"{path}.operation_id", "operation_id must be a safe deterministic id"))
        elif operation_id in seen_ids:
            issues.append(_issue("duplicate_operation_id", f"{path}.operation_id", "operation_id must be unique"))
        seen_ids.add(str(operation_id))
        operation_type = operation.get("operation_type")
        if operation_type in FORBIDDEN_OPERATION_TYPES or operation_type not in OPERATION_ORDER:
            issues.append(_issue("unsupported_operation", f"{path}.operation_type", "operation type is not allowlisted"))
        if operation_type == "resolve_camera" and (operation.get("fallback_allowed") is not False or operation.get("create_if_missing") is not False):
            issues.append(_issue("unsafe_camera_resolution", path, "camera resolution must not fallback or create cameras"))
        if operation_type == "apply_animation_operations" and operation.get("requires_m36_7_guards") is not True:
            issues.append(_issue("missing_animation_guard_requirement", path, "animation operation application must require M36.7 guards"))
        if operation_type == "configure_preview_render" and (operation.get("engine") != "BLENDER_EEVEE_NEXT" or operation.get("format") != "PNG"):
            issues.append(_issue("unsupported_render_config", path, "preview render must use BLENDER_EEVEE_NEXT PNG"))
        if operation_type == "render_preview_frame" and operation.get("filename_pattern") != "frame-{frame:06d}.png":
            issues.append(_issue("invalid_filename_pattern", path, "filename pattern must be fixed"))
        if operation_type == "publish_preview_directory" and operation.get("atomic_publish_required") is not True:
            issues.append(_issue("atomic_publish_required", path, "publish must require atomic directory rename"))
    flags = operation_plan.get("safety_flags")
    if not isinstance(flags, dict):
        issues.append(_issue("type_mismatch", "$.safety_flags", "safety_flags must be an object"))
    else:
        for key, value in SAFETY_FLAGS.items():
            if flags.get(key) is not value:
                issues.append(_issue("unsafe_safety_flag", f"$.safety_flags.{key}", "plan-only safety flags must remain false"))
    return _sort_issues(issues)


def _relative_output_to_final_dir(request: dict[str, Any], runtime_root: Path) -> tuple[Path, Path]:
    preview_root = runtime_root / "media" / "animation" / "previews"
    final_dir = runtime_root / request["output"]["relative_runtime_directory"]
    return preview_root, final_dir


def _is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except ValueError:
        return False


def _parent_symlink_issue(path: Path, stop_at: Path) -> bool:
    current = path
    stop = stop_at.resolve()
    while True:
        if current.exists() and current.is_symlink():
            return True
        if current == stop or current.parent == current:
            return False
        current = current.parent


def _render_engine_supported(bpy_module: Any, engine: str) -> bool:
    supported = getattr(bpy_module, "supported_render_engines", None)
    if supported is not None:
        return engine in set(supported)
    render = getattr(getattr(bpy_module, "context", None), "scene", None)
    render = getattr(render, "render", None)
    supported = getattr(render, "supported_engines", None)
    if supported is not None:
        return engine in set(supported)
    return True


def preflight_preview_render(request: dict[str, Any], preview_operation_plan: dict[str, Any], bpy_module: Any, *, runtime_root: Path = RUNTIME_ROOT) -> tuple[dict[str, Any], int]:
    issues = list(validate_preview_render_operation_plan(preview_operation_plan))
    scene = getattr(getattr(bpy_module, "context", None), "scene", None)
    if scene is None or not hasattr(scene, "render"):
        issues.append(_issue("scene_unavailable", "$.bpy.context.scene", "Blender scene with render settings is required"))
    camera = None
    try:
        camera = bpy_module.data.objects.get(request["camera_id"])
    except AttributeError:
        issues.append(_issue("camera_lookup_unavailable", "$.camera_id", "bpy.data.objects.get is required"))
    if camera is None:
        issues.append(_issue("camera_not_found", "$.camera_id", "camera_id was not found"))
    elif getattr(camera, "type", None) != "CAMERA":
        issues.append(_issue("camera_type_mismatch", "$.camera_id", "camera_id must resolve to a CAMERA object"))
    if not hasattr(getattr(getattr(bpy_module, "ops", None), "render", None), "render"):
        issues.append(_issue("render_operator_unavailable", "$.bpy.ops.render.render", "render operator is required"))
    if not _render_engine_supported(bpy_module, "BLENDER_EEVEE_NEXT"):
        issues.append(_issue("render_engine_unavailable", "$.render.engine", "BLENDER_EEVEE_NEXT is not available"))
    preview_root, final_dir = _relative_output_to_final_dir(request, runtime_root)
    preview_id_dir = preview_root / request["preview_id"]
    if not _is_relative_to(final_dir, preview_root):
        issues.append(_issue("output_path_escape", "$.output.relative_runtime_directory", "final directory must stay under preview root"))
    if _parent_symlink_issue(preview_root, runtime_root):
        issues.append(_issue("preview_root_symlink", "$.runtime.preview_root", "preview root or parent must not be a symlink"))
    if _parent_symlink_issue(final_dir.parent, preview_root):
        issues.append(_issue("output_parent_symlink", "$.output.relative_runtime_directory", "output parents must not be symlinks"))
    if preview_id_dir.exists():
        issues.append(_issue("preview_directory_exists", "$.output.relative_runtime_directory", "preview-id directory already exists"))
    status = "ok" if not issues else "preflight_failed"
    return {
        "status": status,
        "camera_resolved": camera is not None and getattr(camera, "type", None) == "CAMERA",
        "errors": _issue_items(issues),
        "safety_flags": dict(SAFETY_FLAGS),
    }, 0 if not issues else 1


def preview_render_enabled() -> bool:
    return os.getenv("REAL_ANIMATION_GENERATION") == "1" and os.getenv("REAL_ANIMATION_PREVIEW_RENDER") == "1"


def _snapshot_render_settings(scene: Any) -> dict[str, Any]:
    return {
        "engine": scene.render.engine,
        "resolution_x": scene.render.resolution_x,
        "resolution_y": scene.render.resolution_y,
        "resolution_percentage": scene.render.resolution_percentage,
        "file_format": scene.render.image_settings.file_format,
        "film_transparent": scene.render.film_transparent,
        "filepath": scene.render.filepath,
        "camera": getattr(scene, "camera", None),
        "frame_current": getattr(scene, "frame_current", None),
    }


def _restore_render_settings(scene: Any, snapshot: dict[str, Any]) -> bool:
    scene.render.engine = snapshot["engine"]
    scene.render.resolution_x = snapshot["resolution_x"]
    scene.render.resolution_y = snapshot["resolution_y"]
    scene.render.resolution_percentage = snapshot["resolution_percentage"]
    scene.render.image_settings.file_format = snapshot["file_format"]
    scene.render.film_transparent = snapshot["film_transparent"]
    scene.render.filepath = snapshot["filepath"]
    scene.camera = snapshot["camera"]
    if snapshot["frame_current"] is not None:
        scene.frame_set(snapshot["frame_current"])
    return True


def _cleanup_path(path: Path, preview_root: Path, preview_id: str) -> None:
    if path.exists() and _is_relative_to(path, preview_root) and not path.is_symlink() and preview_id in path.parts:
        shutil.rmtree(path)


def _verify_frame(path: Path, staging_dir: Path, frame: int) -> int:
    if path.name != f"frame-{frame:06d}.png":
        raise ValueError("rendered frame filename mismatch")
    if not _is_relative_to(path, staging_dir):
        raise ValueError("rendered frame path escaped staging directory")
    if path.is_symlink():
        raise ValueError("rendered frame must not be a symlink")
    if not path.is_file() or path.suffix.lower() != ".png":
        raise ValueError("rendered frame must be a regular .png file")
    size = path.stat().st_size
    if size <= 0:
        raise ValueError("rendered frame must be non-empty")
    return size


def _result(
    request: dict[str, Any],
    plan: dict[str, Any],
    status: str,
    *,
    total_output_bytes: int = 0,
    final_output_published: bool = False,
    partial_output_available: bool = False,
    animation_applied: bool = False,
    preview_rendered: bool = False,
    errors: list[dict[str, str]] | None = None,
    flags: dict[str, bool] | None = None,
) -> dict[str, Any]:
    safety_flags = dict(SAFETY_FLAGS)
    if flags:
        safety_flags.update(flags)
    return {
        "schema_version": "1.0",
        "result_type": RESULT_TYPE,
        "status": status,
        "preview_id": request.get("preview_id"),
        "render_mode": "sampled_frames",
        "engine": "BLENDER_EEVEE_NEXT",
        "format": "PNG",
        "width": request.get("render", {}).get("width"),
        "height": request.get("render", {}).get("height"),
        "frames": plan.get("frames", []),
        "frame_count": len(plan.get("frames", [])),
        "relative_output_directory": request.get("output", {}).get("relative_runtime_directory"),
        "total_output_bytes": total_output_bytes,
        "final_output_published": final_output_published,
        "partial_output_available": partial_output_available,
        "execution": {
            "animation_applied": animation_applied,
            "preview_rendered": preview_rendered,
            "video_encoded": False,
            "blend_file_saved": False,
        },
        "errors": errors or [],
        "safety_flags": safety_flags,
    }


def _execute_preview_with_bpy_module(
    preview_request: dict[str, Any],
    adapter_request: dict[str, Any],
    preview_operation_plan: dict[str, Any],
    adapter_operation_plan: dict[str, Any],
    bpy_module: Any,
    *,
    runtime_root: Path,
    monotonic: Callable[[], float] = time.monotonic,
) -> tuple[dict[str, Any], int]:
    preflight, preflight_code = preflight_preview_render(preview_request, preview_operation_plan, bpy_module, runtime_root=runtime_root)
    if preflight_code != 0:
        return _result(preview_request, preview_operation_plan, "preflight_failed", errors=preflight["errors"]), 1
    preview_root, final_dir = _relative_output_to_final_dir(preview_request, runtime_root)
    preview_id_dir = preview_root / preview_request["preview_id"]
    staging_dir = preview_id_dir / f".frames-staging-{os.getpid()}"
    scene = bpy_module.context.scene
    snapshot = _snapshot_render_settings(scene)
    restore_ok = False
    animation_applied = False
    total_size = 0
    start = monotonic()
    created_parent = False
    render_complete = False
    try:
        if monotonic() - start > preview_request["limits"]["timeout_seconds"]:
            return _result(preview_request, preview_operation_plan, "timeout"), 1
        preview_id_dir.mkdir(parents=False, exist_ok=False)
        created_parent = True
        staging_dir.mkdir(parents=False, exist_ok=False)
        animation_result, animation_exit = _execute_with_bpy_module(adapter_operation_plan, bpy_module)
        animation_applied = animation_result.get("status") == "executed"
        if animation_exit != 0 or not animation_applied:
            return _result(preview_request, preview_operation_plan, "preflight_failed", animation_applied=animation_applied, errors=animation_result.get("errors", []), flags={"bpy_imported": True, "blender_execution_attempted": True, "scene_modified": animation_applied}), 1
        camera = bpy_module.data.objects.get(preview_request["camera_id"])
        scene.render.engine = "BLENDER_EEVEE_NEXT"
        scene.render.resolution_x = preview_request["render"]["width"]
        scene.render.resolution_y = preview_request["render"]["height"]
        scene.render.resolution_percentage = 100
        scene.render.image_settings.file_format = "PNG"
        scene.render.film_transparent = preview_request["render"]["transparent_background"]
        scene.camera = camera
        for frame in preview_operation_plan["frames"]:
            if monotonic() - start > preview_request["limits"]["timeout_seconds"]:
                return _result(preview_request, preview_operation_plan, "timeout", animation_applied=animation_applied, flags={"bpy_imported": True, "blender_execution_attempted": True, "scene_modified": True, "preview_render_attempted": True}), 1
            frame_path = staging_dir / f"frame-{frame:06d}.png"
            scene.frame_set(frame)
            scene.render.filepath = str(frame_path)
            try:
                bpy_module.ops.render.render(write_still=True)
            except Exception as exc:  # noqa: BLE001
                return _result(preview_request, preview_operation_plan, "render_failed", animation_applied=animation_applied, errors=[_issue("render_failed", "$.render", str(exc)).as_report_item()], flags={"bpy_imported": True, "blender_execution_attempted": True, "scene_modified": True, "preview_render_attempted": True}), 1
            if monotonic() - start > preview_request["limits"]["timeout_seconds"]:
                return _result(preview_request, preview_operation_plan, "timeout", animation_applied=animation_applied, flags={"bpy_imported": True, "blender_execution_attempted": True, "scene_modified": True, "preview_render_attempted": True}), 1
            try:
                total_size += _verify_frame(frame_path, staging_dir, frame)
            except ValueError as exc:
                return _result(preview_request, preview_operation_plan, "verification_failed", animation_applied=animation_applied, errors=[_issue("frame_verification_failed", "$.frames", str(exc)).as_report_item()], flags={"bpy_imported": True, "blender_execution_attempted": True, "scene_modified": True, "preview_render_attempted": True}), 1
            if total_size > preview_request["limits"]["max_total_output_bytes"]:
                return _result(preview_request, preview_operation_plan, "output_limit_exceeded", total_output_bytes=total_size, animation_applied=animation_applied, flags={"bpy_imported": True, "blender_execution_attempted": True, "scene_modified": True, "preview_render_attempted": True}), 1
        return_status = "rendered"
        render_complete = True
    finally:
        try:
            restore_ok = _restore_render_settings(scene, snapshot)
        except Exception:
            restore_ok = False
        if not render_complete:
            _cleanup_path(staging_dir, preview_root, preview_request["preview_id"])
            if created_parent and preview_id_dir.exists() and not any(preview_id_dir.iterdir()):
                preview_id_dir.rmdir()
    if not restore_ok:
        _cleanup_path(staging_dir, preview_root, preview_request["preview_id"])
        if created_parent and preview_id_dir.exists() and not any(preview_id_dir.iterdir()):
            preview_id_dir.rmdir()
        return _result(preview_request, preview_operation_plan, "restore_failed", total_output_bytes=total_size, animation_applied=animation_applied, errors=[_issue("restore_failed", "$.render_settings", "render settings restore failed").as_report_item()], flags={"bpy_imported": True, "blender_execution_attempted": True, "scene_modified": animation_applied, "preview_render_attempted": True, "render_settings_restored": False}), 1
    try:
        if final_dir.exists():
            raise FileExistsError("final frames directory already exists")
        staging_dir.rename(final_dir)
    except OSError as exc:
        _cleanup_path(staging_dir, preview_root, preview_request["preview_id"])
        if created_parent and preview_id_dir.exists() and not any(preview_id_dir.iterdir()):
            preview_id_dir.rmdir()
        return _result(preview_request, preview_operation_plan, "publish_failed", total_output_bytes=total_size, animation_applied=animation_applied, errors=[_issue("publish_failed", "$.output", str(exc)).as_report_item()], flags={"bpy_imported": True, "blender_execution_attempted": True, "scene_modified": animation_applied, "preview_render_attempted": True, "render_settings_restored": True}), 1
    return _result(preview_request, preview_operation_plan, return_status, total_output_bytes=total_size, final_output_published=True, animation_applied=True, preview_rendered=True, flags={"bpy_imported": True, "blender_execution_attempted": True, "runtime_assets_written": True, "scene_modified": True, "preview_render_attempted": True, "render_settings_restored": True}), 0


def execute_animation_preview_render(preview_request: dict[str, Any], adapter_request: dict[str, Any], preview_operation_plan: dict[str, Any], adapter_operation_plan: dict[str, Any]) -> tuple[dict[str, Any], int]:
    import bpy  # type: ignore[import-not-found]  # noqa: PLC0415

    return _execute_preview_with_bpy_module(preview_request, adapter_request, preview_operation_plan, adapter_operation_plan, bpy, runtime_root=RUNTIME_ROOT, monotonic=time.monotonic)


def build_animation_preview_render_report(preview_request_path: str, adapter_request_path: str, *, execute_animation: bool = False, render_preview: bool = False) -> tuple[dict[str, Any], int]:
    empty_flags = dict(SAFETY_FLAGS)
    if execute_animation != render_preview:
        issue = _issue("inconsistent_cli_flags", "$.execution", "--execute-animation and --render-preview must be used together")
        return {"schema_version": "1.0", "report_type": REPORT_TYPE, "status": "guard_blocked", "planned": False, "rendered": False, "preview_request_path": _sanitize_path(preview_request_path), "adapter_request_path": _sanitize_path(adapter_request_path), "operation_plan": None, "render_result": None, "errors": [issue.as_report_item()], "warnings": [], "safety_flags": empty_flags}, 2
    loaded_preview = load_preview_render_request(preview_request_path)
    if loaded_preview.issues or loaded_preview.request is None:
        return {"schema_version": "1.0", "report_type": REPORT_TYPE, "status": "invalid", "planned": False, "rendered": False, "preview_request_path": loaded_preview.display_path, "adapter_request_path": _sanitize_path(adapter_request_path), "operation_plan": None, "render_result": None, "errors": _issue_items(loaded_preview.issues), "warnings": [], "safety_flags": empty_flags}, loaded_preview.exit_code
    loaded_adapter = load_adapter_request(adapter_request_path)
    if loaded_adapter.issues or loaded_adapter.request is None:
        return {"schema_version": "1.0", "report_type": REPORT_TYPE, "status": "invalid", "planned": False, "rendered": False, "preview_request_path": loaded_preview.display_path, "adapter_request_path": loaded_adapter.display_path, "operation_plan": None, "render_result": None, "errors": _issue_items(loaded_adapter.issues), "warnings": [], "safety_flags": empty_flags}, loaded_adapter.exit_code
    issues: list[Any] = list(validate_preview_render_request_structure(loaded_preview.request))
    if not issues:
        issues.extend(validate_adapter_request(loaded_adapter.request))
    adapter_plan_result = build_blender_animation_operation_plan(loaded_adapter.request) if not issues else None
    if adapter_plan_result is not None and adapter_plan_result.operation_plan is not None:
        issues.extend(validate_blender_animation_operation_plan(adapter_plan_result.operation_plan))
        issues.extend(validate_preview_render_request_semantics(loaded_preview.request, loaded_adapter.request))
    if issues or adapter_plan_result is None or adapter_plan_result.operation_plan is None or not adapter_plan_result.valid:
        errors = issues or list(adapter_plan_result.issues if adapter_plan_result is not None else [])
        return {"schema_version": "1.0", "report_type": REPORT_TYPE, "status": "invalid", "planned": False, "rendered": False, "preview_request_path": loaded_preview.display_path, "adapter_request_path": loaded_adapter.display_path, "operation_plan": None, "render_result": None, "errors": _issue_items(errors), "warnings": [], "safety_flags": empty_flags}, 1
    preview_operation_plan = build_preview_render_operation_plan(loaded_preview.request, loaded_adapter.request, adapter_plan_result.operation_plan)
    plan_issues = validate_preview_render_operation_plan(preview_operation_plan)
    if plan_issues:
        return {"schema_version": "1.0", "report_type": REPORT_TYPE, "status": "invalid", "planned": False, "rendered": False, "preview_request_path": loaded_preview.display_path, "adapter_request_path": loaded_adapter.display_path, "operation_plan": None, "render_result": None, "errors": _issue_items(plan_issues), "warnings": [], "safety_flags": empty_flags}, 1
    if execute_animation and render_preview:
        if not preview_render_enabled():
            issue = _issue("preview_render_guard_blocked", "$.execution", "REAL_ANIMATION_GENERATION=1 and REAL_ANIMATION_PREVIEW_RENDER=1 are required with render flags")
            return {"schema_version": "1.0", "report_type": REPORT_TYPE, "status": "guard_blocked", "planned": True, "rendered": False, "preview_request_path": loaded_preview.display_path, "adapter_request_path": loaded_adapter.display_path, "operation_plan": preview_operation_plan, "render_result": None, "errors": [issue.as_report_item()], "warnings": [], "safety_flags": empty_flags}, 2
        try:
            render_result, render_exit = execute_animation_preview_render(loaded_preview.request, loaded_adapter.request, preview_operation_plan, adapter_plan_result.operation_plan)
        except ImportError:
            issue = _issue("blender_context_unavailable", "$.execution", "Blender preview rendering requires running inside Blender.")
            return {"schema_version": "1.0", "report_type": REPORT_TYPE, "status": "blender_unavailable", "planned": True, "rendered": False, "preview_request_path": loaded_preview.display_path, "adapter_request_path": loaded_adapter.display_path, "operation_plan": preview_operation_plan, "render_result": None, "errors": [issue.as_report_item()], "warnings": [], "safety_flags": dict(empty_flags, bpy_imported=False, blender_execution_attempted=True)}, 2
        return {"schema_version": "1.0", "report_type": REPORT_TYPE, "status": render_result["status"], "planned": True, "rendered": render_result["status"] == "rendered", "preview_request_path": loaded_preview.display_path, "adapter_request_path": loaded_adapter.display_path, "operation_plan": preview_operation_plan, "render_result": render_result, "errors": render_result.get("errors", []), "warnings": [], "safety_flags": render_result["safety_flags"]}, render_exit
    return {"schema_version": "1.0", "report_type": REPORT_TYPE, "status": "planned", "planned": True, "rendered": False, "preview_request_path": loaded_preview.display_path, "adapter_request_path": loaded_adapter.display_path, "operation_plan": preview_operation_plan, "render_result": None, "errors": [], "warnings": [], "safety_flags": empty_flags}, 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build or guarded-execute an animation preview render plan.")
    parser.add_argument("--preview-request", required=True, help="Preview request JSON under configs/animation or /tmp.")
    parser.add_argument("--adapter-request", required=True, help="Adapter request JSON under configs/animation or /tmp.")
    parser.add_argument("--execute-animation", action="store_true", help="Required together with --render-preview for guarded execution.")
    parser.add_argument("--render-preview", action="store_true", help="Required together with --execute-animation for guarded execution.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON report.")
    return parser


def _argv_after_blender_separator(argv: list[str] | None) -> list[str] | None:
    if argv is None:
        argv = sys.argv[1:]
    if "--" in argv:
        return argv[argv.index("--") + 1 :]
    return argv


def run(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(_argv_after_blender_separator(argv))
    report, exit_code = build_animation_preview_render_report(args.preview_request, args.adapter_request, execute_animation=args.execute_animation, render_preview=args.render_preview)
    print(json.dumps(report, indent=2 if args.pretty else None, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(run())
