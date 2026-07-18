#!/usr/bin/env python3
"""Guarded Blender animation adapter for M36.7.

The module is importable without Blender. It builds and validates operation
plans in normal Python, and imports bpy only inside the public guarded
execution function.
"""

from __future__ import annotations

import argparse
import copy
import json
import math
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

from animation_plan_validator import (  # noqa: E402
    ValidationIssue,
    _sanitize_plan_path,
    validate_animation_plan_semantics,
    validate_animation_plan_structure,
)
from animation_timeline_planner import build_timeline_keyframe_plan, canonical_plan_hash  # noqa: E402


REPO_ROOT = Path(__file__).resolve().parents[3]
CONFIG_ROOT = REPO_ROOT / "configs" / "animation"
MAX_INPUT_BYTES = 512 * 1024
REQUEST_SCHEMA_VERSION = "1.0"
REQUEST_TYPE = "blender_animation_adapter_request"
SOURCE_KINDS = {"camera_animation_plan", "object_transform_animation_plan"}
SAFE_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*$")
OPERATION_ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
HASH_RE = re.compile(r"^[a-f0-9]{64}$")
ALLOWLISTED_OPERATIONS = {
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
FORBIDDEN_OPERATIONS = {
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
TRANSFORM_DATA_PATHS = ("location", "rotation_euler", "scale")
INTERPOLATION_MAP = {"constant": "CONSTANT", "linear": "LINEAR", "bezier": "BEZIER"}
PLAN_SAFETY_FLAGS = {
    "read_only": True,
    "bpy_imported": False,
    "blender_execution_attempted": False,
    "runtime_assets_written": False,
    "source_assets_modified": False,
    "keyframes_written": False,
    "scene_modified": False,
    "external_process_started": False,
    "preview_render_attempted": False,
    "blend_file_saved": False,
}


@dataclass(frozen=True)
class AdapterIssue:
    code: str
    path: str
    message: str

    def as_report_item(self) -> dict[str, str]:
        return {"code": self.code, "path": self.path, "message": self.message}


@dataclass(frozen=True)
class AdapterRequestResult:
    request: dict[str, Any] | None
    display_path: str
    issues: tuple[AdapterIssue | ValidationIssue, ...]
    exit_code: int = 0


@dataclass(frozen=True)
class AdapterPlanResult:
    valid: bool
    operation_plan: dict[str, Any] | None
    issues: tuple[AdapterIssue | ValidationIssue, ...]
    exit_code: int = 0


def _issue(code: str, path: str, message: str) -> AdapterIssue:
    return AdapterIssue(code=code, path=path, message=message)


def _sort_issues(issues: list[AdapterIssue | ValidationIssue] | tuple[AdapterIssue | ValidationIssue, ...]) -> tuple[AdapterIssue | ValidationIssue, ...]:
    return tuple(sorted(issues, key=lambda item: (item.path, item.code, item.message)))


def _issue_items(issues: tuple[AdapterIssue | ValidationIssue, ...]) -> list[dict[str, str]]:
    return [issue.as_report_item() for issue in _sort_issues(issues)]


def _is_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def _check_unknown(value: dict[str, Any], allowed: set[str], path: str, issues: list[AdapterIssue | ValidationIssue]) -> None:
    for key in sorted(set(value) - allowed):
        issues.append(_issue("unknown_field", f"{path}.{key}", "field is not allowed"))


def _check_required(value: dict[str, Any], required: list[str], path: str, issues: list[AdapterIssue | ValidationIssue]) -> None:
    for key in required:
        if key not in value:
            issues.append(_issue("missing_required_field", f"{path}.{key}", "field is required"))


def _check_const(value: object, expected: object, path: str, issues: list[AdapterIssue | ValidationIssue]) -> None:
    if value != expected or type(value) is not type(expected):  # noqa: E721
        issues.append(_issue("const_mismatch", path, f"value must be {json.dumps(expected)}"))


def _safe_id(value: object, path: str, issues: list[AdapterIssue | ValidationIssue]) -> str | None:
    if not isinstance(value, str):
        issues.append(_issue("type_mismatch", path, "value must be a string"))
        return None
    if not SAFE_ID_RE.fullmatch(value) or any(marker in value for marker in ("/", "\\", "..", "://", "/home/", "MoE_Models_Backup")):
        issues.append(_issue("unsafe_identifier", path, "identifier must be a safe Blender target id"))
    return value


def _safe_operation_id(value: object, path: str, issues: list[AdapterIssue | ValidationIssue]) -> str | None:
    if not isinstance(value, str) or not OPERATION_ID_RE.fullmatch(value):
        issues.append(_issue("unsafe_operation_id", path, "operation_id must match ^[a-z0-9][a-z0-9-]*$"))
        return None
    return value


def _safe_input_path(raw_request_path: str) -> tuple[Path | None, str, AdapterIssue | None]:
    display_path = _sanitize_plan_path(raw_request_path)
    raw = str(raw_request_path)
    raw_path = Path(raw)
    if ".." in raw_path.parts:
        return None, display_path, _issue("unsafe_input_path", "$.adapter_request", "request path must not contain traversal")
    if raw_path.suffix.lower() != ".json":
        return None, display_path, _issue("unsupported_input_extension", "$.adapter_request", "adapter request must use .json")
    if raw.startswith("configs/animation/") and len(raw_path.parts) == 3:
        candidate = REPO_ROOT / raw_path
        display_path = raw
    elif raw_path.is_absolute() and raw_path.parent == Path("/tmp"):
        candidate = raw_path
        display_path = f"/tmp/{raw_path.name}"
    else:
        return None, display_path, _issue("input_path_not_allowlisted", "$.adapter_request", "request path must be configs/animation/<file>.json or /tmp/<file>.json")
    try:
        stat_result = candidate.lstat()
    except OSError:
        return None, display_path, _issue("input_file_unreadable", "$.adapter_request", "request file could not be inspected")
    if candidate.is_symlink():
        return None, display_path, _issue("input_symlink_rejected", "$.adapter_request", "adapter request symlinks are rejected")
    if not candidate.is_file():
        return None, display_path, _issue("input_not_regular_file", "$.adapter_request", "adapter request must be a regular file")
    if stat_result.st_size > MAX_INPUT_BYTES:
        return None, display_path, _issue("input_too_large", "$.adapter_request", "adapter request exceeds 512 KiB")
    return candidate, display_path, None


def _canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)


def load_adapter_request(request_path: str) -> AdapterRequestResult:
    candidate, display_path, path_issue = _safe_input_path(request_path)
    if path_issue is not None or candidate is None:
        return AdapterRequestResult(None, display_path, tuple([path_issue] if path_issue else []), 2)
    try:
        text = candidate.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return AdapterRequestResult(None, display_path, (_issue("input_not_utf8", "$.adapter_request", "adapter request must be valid UTF-8"),), 2)
    except OSError:
        return AdapterRequestResult(None, display_path, (_issue("input_file_unreadable", "$.adapter_request", "adapter request could not be read"),), 2)
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        return AdapterRequestResult(None, display_path, (_issue("malformed_json", "$.adapter_request", "adapter request JSON is malformed"),), 2)
    if not isinstance(payload, dict):
        return AdapterRequestResult(None, display_path, (_issue("root_not_object", "$", "adapter request root must be an object"),), 1)
    return AdapterRequestResult(payload, display_path, tuple(), 0)


def validate_adapter_request(request: dict[str, Any]) -> tuple[AdapterIssue | ValidationIssue, ...]:
    issues: list[AdapterIssue | ValidationIssue] = []
    allowed_root = {
        "schema_version",
        "request_type",
        "source_kind",
        "source_request_sha256",
        "canonical_animation_plan",
        "timeline_plan",
        "planner_context",
        "safety",
    }
    _check_unknown(request, allowed_root, "$", issues)
    _check_required(request, sorted(allowed_root), "$", issues)
    _check_const(request.get("schema_version"), REQUEST_SCHEMA_VERSION, "$.schema_version", issues)
    _check_const(request.get("request_type"), REQUEST_TYPE, "$.request_type", issues)
    if request.get("source_kind") not in SOURCE_KINDS:
        issues.append(_issue("enum_mismatch", "$.source_kind", "source_kind must be camera_animation_plan or object_transform_animation_plan"))
    source_hash = request.get("source_request_sha256")
    if not isinstance(source_hash, str) or not HASH_RE.fullmatch(source_hash):
        issues.append(_issue("invalid_sha256", "$.source_request_sha256", "source_request_sha256 must be 64 lowercase hex characters"))

    context = request.get("planner_context")
    if not isinstance(context, dict):
        issues.append(_issue("type_mismatch", "$.planner_context", "planner_context must be an object"))
    else:
        _check_unknown(context, {"camera_settings"}, "$.planner_context", issues)
        camera_settings = context.get("camera_settings")
        if camera_settings is not None:
            if not isinstance(camera_settings, dict):
                issues.append(_issue("type_mismatch", "$.planner_context.camera_settings", "camera_settings must be an object"))
            else:
                _check_unknown(camera_settings, {"camera_id", "lens_mm"}, "$.planner_context.camera_settings", issues)
                _check_required(camera_settings, ["camera_id", "lens_mm"], "$.planner_context.camera_settings", issues)
                _safe_id(camera_settings.get("camera_id"), "$.planner_context.camera_settings.camera_id", issues)
                lens_mm = camera_settings.get("lens_mm")
                if not _is_number(lens_mm) or float(lens_mm) < 1.0 or float(lens_mm) > 300.0:
                    issues.append(_issue("invalid_camera_lens", "$.planner_context.camera_settings.lens_mm", "lens_mm must be finite and between 1.0 and 300.0"))

    safety = request.get("safety")
    if not isinstance(safety, dict):
        issues.append(_issue("type_mismatch", "$.safety", "safety must be an object"))
    else:
        allowed_safety = {"real_animation_enabled", "blender_execution_enabled", "runtime_write_planned"}
        _check_unknown(safety, allowed_safety, "$.safety", issues)
        _check_required(safety, sorted(allowed_safety), "$.safety", issues)
        for key in sorted(allowed_safety):
            _check_const(safety.get(key), False, f"$.safety.{key}", issues)

    canonical = request.get("canonical_animation_plan")
    timeline = request.get("timeline_plan")
    if not isinstance(canonical, dict):
        issues.append(_issue("type_mismatch", "$.canonical_animation_plan", "canonical_animation_plan must be an object"))
    if not isinstance(timeline, dict):
        issues.append(_issue("type_mismatch", "$.timeline_plan", "timeline_plan must be an object"))
    if not isinstance(canonical, dict) or not isinstance(timeline, dict):
        return _sort_issues(issues)

    plan_issues = validate_animation_plan_structure(canonical)
    if not plan_issues:
        plan_issues.extend(validate_animation_plan_semantics(canonical))
    issues.extend(plan_issues)
    if plan_issues:
        return _sort_issues(issues)

    expected_hash = canonical_plan_hash(canonical)
    if timeline.get("source_plan_sha256") != expected_hash:
        issues.append(_issue("canonical_plan_hash_mismatch", "$.timeline_plan.source_plan_sha256", "timeline source hash must match canonical animation plan"))
    rebuilt = build_timeline_keyframe_plan(canonical)
    if not rebuilt.valid or rebuilt.plan is None:
        issues.append(_issue("timeline_plan_invalid", "$.timeline_plan", "canonical plan could not produce a timeline plan"))
    elif _canonical_json(timeline) != _canonical_json(rebuilt.plan):
        issues.append(_issue("timeline_plan_mismatch", "$.timeline_plan", "timeline_plan must match M36.3 planner output for canonical_animation_plan"))
    return _sort_issues(issues)


def _slug(value: str) -> str:
    return re.sub(r"[^a-z0-9-]+", "-", value.lower()).strip("-") or "item"


def _vector(value: list[Any]) -> list[float]:
    return [float(item) for item in value]


def build_blender_animation_operation_plan(request: dict[str, Any]) -> AdapterPlanResult:
    issues = list(validate_adapter_request(request))
    if issues:
        return AdapterPlanResult(False, None, _sort_issues(issues), 1)

    canonical = copy.deepcopy(request["canonical_animation_plan"])
    timeline_plan = copy.deepcopy(request["timeline_plan"])
    timeline = canonical["timeline"]
    operations: list[dict[str, Any]] = [
        {
            "operation_id": "configure-scene-timeline",
            "operation_type": "configure_scene_timeline",
            "fps": timeline["fps"],
            "start_frame": timeline["start_frame"],
            "end_frame": timeline["end_frame"],
        }
    ]
    seen_targets: set[tuple[str, str]] = set()
    rotation_targets: set[str] = set()
    for track in canonical["tracks"]:
        key = (track["target_type"], track["target_id"])
        if key not in seen_targets:
            seen_targets.add(key)
            operations.append(
                {
                    "operation_id": f"resolve-target-{_slug(track['target_type'])}-{_slug(track['target_id'])}",
                    "operation_type": "resolve_target",
                    "target_type": track["target_type"],
                    "target_id": track["target_id"],
                    "required": True,
                    "create_if_missing": False,
                }
            )
        if any("rotation_euler" in keyframe for keyframe in track["keyframes"]):
            rotation_targets.add(track["target_id"])

    for target_id in sorted(rotation_targets):
        operations.append(
            {
                "operation_id": f"set-rotation-mode-{_slug(target_id)}",
                "operation_type": "set_rotation_mode",
                "target_id": target_id,
                "rotation_mode": "XYZ",
            }
        )

    camera_settings = request.get("planner_context", {}).get("camera_settings") if isinstance(request.get("planner_context"), dict) else None
    if isinstance(camera_settings, dict):
        operations.append(
            {
                "operation_id": f"set-camera-lens-{_slug(str(camera_settings['camera_id']))}",
                "operation_type": "set_camera_lens",
                "target_type": "camera",
                "target_id": camera_settings["camera_id"],
                "lens_mm": float(camera_settings["lens_mm"]),
                "animated": False,
            }
        )

    for track_index, track in enumerate(canonical["tracks"]):
        track_slug = _slug(track["track_id"])
        if track["property"] == "visibility":
            for keyframe_index, keyframe in enumerate(track["keyframes"]):
                visible = bool(keyframe["visibility"])
                operations.append(
                    {
                        "operation_id": f"set-visibility-{track_slug}-{keyframe_index}",
                        "operation_type": "set_visibility_value",
                        "target_type": track["target_type"],
                        "target_id": track["target_id"],
                        "frame": keyframe["frame"],
                        "visible": visible,
                        "blender_properties": ["hide_viewport", "hide_render"],
                    }
                )
                operations.append(
                    {
                        "operation_id": f"insert-visibility-keyframe-{track_slug}-{keyframe_index}",
                        "operation_type": "insert_visibility_keyframe",
                        "target_type": track["target_type"],
                        "target_id": track["target_id"],
                        "frame": keyframe["frame"],
                        "data_paths": ["hide_viewport", "hide_render"],
                    }
                )
            continue

        for keyframe_index, keyframe in enumerate(track["keyframes"]):
            values = {field: _vector(keyframe[field]) for field in TRANSFORM_DATA_PATHS if field in keyframe}
            if values:
                operations.append(
                    {
                        "operation_id": f"set-transform-values-{track_slug}-{keyframe_index}",
                        "operation_type": "set_transform_values",
                        "target_type": track["target_type"],
                        "target_id": track["target_id"],
                        "frame": keyframe["frame"],
                        "values": values,
                    }
                )
            for data_path in TRANSFORM_DATA_PATHS:
                if data_path in keyframe:
                    operations.append(
                        {
                            "operation_id": f"insert-transform-keyframe-{track_slug}-{keyframe_index}-{data_path.replace('_', '-')}",
                            "operation_type": "insert_transform_keyframe",
                            "target_type": track["target_type"],
                            "target_id": track["target_id"],
                            "frame": keyframe["frame"],
                            "data_path": data_path,
                        }
                    )

    for track in canonical["tracks"]:
        if track["property"] == "visibility":
            data_paths = ["hide_viewport", "hide_render"]
        elif track["property"] == "transform":
            present_paths: set[str] = set()
            for keyframe in track["keyframes"]:
                present_paths.update(field for field in TRANSFORM_DATA_PATHS if field in keyframe)
            data_paths = [field for field in TRANSFORM_DATA_PATHS if field in present_paths]
        else:
            data_paths = [track["property"]]
        for data_path in data_paths:
            operations.append(
                {
                    "operation_id": f"set-fcurve-interpolation-{_slug(track['track_id'])}-{data_path.replace('_', '-')}",
                    "operation_type": "set_fcurve_interpolation",
                    "target_type": track["target_type"],
                    "target_id": track["target_id"],
                    "data_path": data_path,
                    "interpolation": INTERPOLATION_MAP[track["interpolation"]],
                    "source_track_id": track["track_id"],
                }
            )

    plan = {
        "schema_version": "1.0",
        "plan_type": "blender_animation_operation_plan",
        "status": "planned",
        "mode": "dry_run",
        "source_kind": request["source_kind"],
        "source_request_sha256": request["source_request_sha256"],
        "source_plan_id": canonical["plan_id"],
        "source_plan_sha256": canonical_plan_hash(canonical),
        "timeline_plan_sha256": canonical_plan_hash(timeline_plan),
        "operation_count": len(operations),
        "operation_types": sorted({operation["operation_type"] for operation in operations}),
        "operations": operations,
        "safety_flags": dict(PLAN_SAFETY_FLAGS),
    }
    op_issues = validate_blender_animation_operation_plan(plan)
    if op_issues:
        return AdapterPlanResult(False, None, op_issues, 1)
    return AdapterPlanResult(True, plan, tuple(), 0)


def validate_blender_animation_operation_plan(operation_plan: dict[str, Any]) -> tuple[AdapterIssue | ValidationIssue, ...]:
    issues: list[AdapterIssue | ValidationIssue] = []
    if not isinstance(operation_plan, dict):
        return (_issue("type_mismatch", "$", "operation plan must be an object"),)
    operations = operation_plan.get("operations")
    if not isinstance(operations, list):
        return (_issue("type_mismatch", "$.operations", "operations must be an array"),)
    if operation_plan.get("operation_count") != len(operations):
        issues.append(_issue("operation_count_mismatch", "$.operation_count", "operation_count must match operations length"))
    if operations and operations[0].get("operation_type") != "configure_scene_timeline":
        issues.append(_issue("operation_order_invalid", "$.operations[0]", "first operation must configure scene timeline"))
    timeline_start = timeline_end = None
    seen_ids: set[str] = set()
    resolved_targets: set[tuple[str, str]] = set()
    for index, operation in enumerate(operations):
        path = f"$.operations[{index}]"
        if not isinstance(operation, dict):
            issues.append(_issue("type_mismatch", path, "operation must be an object"))
            continue
        operation_id = _safe_operation_id(operation.get("operation_id"), f"{path}.operation_id", issues)
        if operation_id:
            if operation_id in seen_ids:
                issues.append(_issue("duplicate_operation_id", f"{path}.operation_id", "operation_id must be unique"))
            seen_ids.add(operation_id)
        operation_type = operation.get("operation_type")
        if operation_type in FORBIDDEN_OPERATIONS or operation_type not in ALLOWLISTED_OPERATIONS:
            issues.append(_issue("unsupported_operation", f"{path}.operation_type", "operation type is not allowlisted"))
            continue
        if operation_type == "configure_scene_timeline":
            fps = operation.get("fps")
            start = operation.get("start_frame")
            end = operation.get("end_frame")
            if not _is_int(fps) or fps < 1 or fps > 240:
                issues.append(_issue("invalid_timeline", f"{path}.fps", "fps must be an integer between 1 and 240"))
            if not _is_int(start) or not _is_int(end) or end <= start:
                issues.append(_issue("invalid_timeline", path, "start_frame and end_frame must be valid integers"))
            else:
                timeline_start, timeline_end = start, end
            continue
        target_id = _safe_id(operation.get("target_id"), f"{path}.target_id", issues)
        target_type = operation.get("target_type")
        if target_type is not None and target_type not in {"camera", "object"}:
            issues.append(_issue("invalid_target_type", f"{path}.target_type", "target_type must be camera or object"))
        if operation_type == "resolve_target" and isinstance(target_id, str) and isinstance(target_type, str):
            if operation.get("required") is not True or operation.get("create_if_missing") is not False:
                issues.append(_issue("unsafe_target_resolution", path, "target resolution must require existing targets and create_if_missing=false"))
            resolved_targets.add((target_type, target_id))
            continue
        if isinstance(target_id, str):
            matches = {key for key in resolved_targets if key[1] == target_id}
            if not matches:
                issues.append(_issue("target_not_resolved_first", f"{path}.target_id", "target must be resolved before mutation/keyframe operations"))
        frame = operation.get("frame")
        if frame is not None:
            if not _is_int(frame) or (timeline_start is not None and (frame < timeline_start or frame > timeline_end)):
                issues.append(_issue("invalid_keyframe_frame", f"{path}.frame", "frame must be an integer inside timeline"))
        if operation_type == "set_rotation_mode" and operation.get("rotation_mode") != "XYZ":
            issues.append(_issue("invalid_rotation_mode", f"{path}.rotation_mode", "rotation_mode must be XYZ"))
        elif operation_type == "set_camera_lens":
            if operation.get("target_type") != "camera" or operation.get("animated") is not False:
                issues.append(_issue("invalid_camera_lens_operation", path, "camera lens operation must target camera and be static"))
            lens = operation.get("lens_mm")
            if not _is_number(lens) or float(lens) < 1.0 or float(lens) > 300.0:
                issues.append(_issue("invalid_camera_lens", f"{path}.lens_mm", "lens_mm must be finite and between 1.0 and 300.0"))
        elif operation_type == "set_transform_values":
            values = operation.get("values")
            if not isinstance(values, dict):
                issues.append(_issue("type_mismatch", f"{path}.values", "values must be an object"))
            else:
                _check_unknown(values, set(TRANSFORM_DATA_PATHS), f"{path}.values", issues)
                for field, vector in values.items():
                    if not isinstance(vector, list) or len(vector) != 3 or not all(_is_number(item) for item in vector):
                        issues.append(_issue("invalid_vector3", f"{path}.values.{field}", "transform vectors must contain exactly 3 finite numbers"))
        elif operation_type == "insert_transform_keyframe" and operation.get("data_path") not in TRANSFORM_DATA_PATHS:
            issues.append(_issue("unsupported_data_path", f"{path}.data_path", "transform keyframes support location, rotation_euler, and scale"))
        elif operation_type in {"set_visibility_value", "insert_visibility_keyframe"}:
            if operation.get("target_type") == "camera":
                issues.append(_issue("unsupported_visibility_target", path, "camera visibility animation is not supported"))
            if operation_type == "set_visibility_value" and (operation.get("blender_properties") != ["hide_viewport", "hide_render"] or not isinstance(operation.get("visible"), bool)):
                issues.append(_issue("invalid_visibility_operation", path, "visibility maps to hide_viewport/hide_render and requires a boolean visible value"))
            if operation_type == "insert_visibility_keyframe" and operation.get("data_paths") != ["hide_viewport", "hide_render"]:
                issues.append(_issue("invalid_visibility_operation", path, "visibility keyframes must insert hide_viewport and hide_render"))
        elif operation_type == "set_fcurve_interpolation":
            if operation.get("data_path") not in set(TRANSFORM_DATA_PATHS) | {"hide_viewport", "hide_render"}:
                issues.append(_issue("unsupported_data_path", f"{path}.data_path", "interpolation data_path is not allowlisted"))
            if operation.get("interpolation") not in set(INTERPOLATION_MAP.values()):
                issues.append(_issue("invalid_interpolation", f"{path}.interpolation", "interpolation must be CONSTANT, LINEAR, or BEZIER"))
    return _sort_issues(issues)


def preflight_blender_animation_operation_plan(operation_plan: dict[str, Any], bpy_module: Any) -> tuple[dict[str, Any], dict[str, Any], tuple[AdapterIssue | ValidationIssue, ...]]:
    issues = list(validate_blender_animation_operation_plan(operation_plan))
    resolved: dict[str, Any] = {}
    if not issues:
        for operation in operation_plan["operations"]:
            if operation["operation_type"] != "resolve_target":
                continue
            target_id = operation["target_id"]
            target = bpy_module.data.objects.get(target_id)
            if target is None:
                issues.append(_issue("target_not_found", f"$.targets.{target_id}", "target was not found in bpy.data.objects"))
                continue
            if operation["target_type"] == "camera" and getattr(target, "type", None) != "CAMERA":
                issues.append(_issue("target_type_mismatch", f"$.targets.{target_id}", "camera target must have Blender type CAMERA"))
                continue
            resolved[target_id] = target
    report = {
        "status": "ok" if not issues else "failed",
        "operations_applied": 0,
        "keyframes_written": False,
        "scene_modified": False,
        "resolved_targets": sorted(resolved),
    }
    return report, resolved if not issues else {}, _sort_issues(issues)


def _apply_interpolation(target: Any, data_path: str, interpolation: str) -> int:
    animation_data = getattr(target, "animation_data", None)
    action = getattr(animation_data, "action", None) if animation_data is not None else None
    fcurves = getattr(action, "fcurves", []) if action is not None else []
    updated = 0
    for fcurve in fcurves:
        if getattr(fcurve, "data_path", None) != data_path:
            continue
        for point in getattr(fcurve, "keyframe_points", []):
            point.interpolation = interpolation
            updated += 1
    return updated


def _execute_with_bpy_module(operation_plan: dict[str, Any], bpy_module: Any) -> tuple[dict[str, Any], int]:
    preflight, targets, issues = preflight_blender_animation_operation_plan(operation_plan, bpy_module)
    if issues:
        return (
            {
                "schema_version": "1.0",
                "result_type": "blender_animation_execution_result",
                "status": "preflight_failed",
                "operation_count": operation_plan.get("operation_count", 0),
                "operations_applied": 0,
                "resolved_targets": preflight["resolved_targets"],
                "keyframe_insert_count": 0,
                "interpolation_update_count": 0,
                "errors": _issue_items(issues),
                "safety_flags": dict(PLAN_SAFETY_FLAGS, bpy_imported=True, blender_execution_attempted=True),
            },
            1,
        )
    scene = bpy_module.context.scene
    operations_applied = 0
    keyframe_insert_count = 0
    interpolation_update_count = 0
    for operation in operation_plan["operations"]:
        operation_type = operation["operation_type"]
        if operation_type == "configure_scene_timeline":
            scene.render.fps = operation["fps"]
            scene.frame_start = operation["start_frame"]
            scene.frame_end = operation["end_frame"]
        elif operation_type == "resolve_target":
            pass
        else:
            target = targets[operation["target_id"]]
            if operation_type == "set_rotation_mode":
                target.rotation_mode = operation["rotation_mode"]
            elif operation_type == "set_camera_lens":
                target.data.lens = operation["lens_mm"]
            elif operation_type == "set_transform_values":
                for data_path, value in operation["values"].items():
                    setattr(target, data_path, list(value))
            elif operation_type == "set_visibility_value":
                hidden = not operation["visible"]
                target.hide_viewport = hidden
                target.hide_render = hidden
            elif operation_type == "insert_transform_keyframe":
                target.keyframe_insert(data_path=operation["data_path"], frame=operation["frame"])
                keyframe_insert_count += 1
            elif operation_type == "insert_visibility_keyframe":
                for data_path in operation["data_paths"]:
                    target.keyframe_insert(data_path=data_path, frame=operation["frame"])
                    keyframe_insert_count += 1
            elif operation_type == "set_fcurve_interpolation":
                interpolation_update_count += _apply_interpolation(target, operation["data_path"], operation["interpolation"])
        operations_applied += 1
    result = {
        "schema_version": "1.0",
        "result_type": "blender_animation_execution_result",
        "status": "executed",
        "operation_count": operation_plan["operation_count"],
        "operations_applied": operations_applied,
        "resolved_targets": sorted(targets),
        "keyframe_insert_count": keyframe_insert_count,
        "interpolation_update_count": interpolation_update_count,
        "errors": [],
        "safety_flags": dict(
            PLAN_SAFETY_FLAGS,
            bpy_imported=True,
            blender_execution_attempted=True,
            keyframes_written=keyframe_insert_count > 0,
            scene_modified=operations_applied > 0,
        ),
    }
    return result, 0


def execute_blender_animation_operation_plan(operation_plan: dict[str, Any]) -> tuple[dict[str, Any], int]:
    import bpy  # type: ignore[import-not-found]  # noqa: PLC0415

    return _execute_with_bpy_module(operation_plan, bpy)


def animation_generation_enabled() -> bool:
    return os.getenv("REAL_ANIMATION_GENERATION") == "1"


def build_blender_animation_adapter_report(request_path: str, *, execute_animation: bool = False) -> tuple[dict[str, Any], int]:
    loaded = load_adapter_request(request_path)
    if loaded.issues or loaded.request is None:
        return (
            {
                "schema_version": "1.0",
                "report_type": "blender_animation_adapter",
                "status": "invalid",
                "planned": False,
                "executed": False,
                "adapter_request_path": loaded.display_path,
                "operation_plan": None,
                "execution_result": None,
                "errors": _issue_items(loaded.issues),
                "warnings": [],
                "safety_flags": dict(PLAN_SAFETY_FLAGS),
            },
            loaded.exit_code,
        )
    plan_result = build_blender_animation_operation_plan(loaded.request)
    planned = plan_result.valid and plan_result.operation_plan is not None
    if not planned:
        return (
            {
                "schema_version": "1.0",
                "report_type": "blender_animation_adapter",
                "status": "invalid",
                "planned": False,
                "executed": False,
                "adapter_request_path": loaded.display_path,
                "operation_plan": None,
                "execution_result": None,
                "errors": _issue_items(plan_result.issues),
                "warnings": [],
                "safety_flags": dict(PLAN_SAFETY_FLAGS),
            },
            plan_result.exit_code,
        )
    if execute_animation:
        if not animation_generation_enabled():
            guard_issue = _issue("animation_generation_guard_blocked", "$.execution", "REAL_ANIMATION_GENERATION=1 is required with --execute-animation")
            return (
                {
                    "schema_version": "1.0",
                    "report_type": "blender_animation_adapter",
                    "status": "guard_blocked",
                    "planned": True,
                    "executed": False,
                    "adapter_request_path": loaded.display_path,
                    "operation_plan": plan_result.operation_plan,
                    "execution_result": None,
                    "errors": [guard_issue.as_report_item()],
                    "warnings": [],
                    "safety_flags": dict(PLAN_SAFETY_FLAGS),
                },
                2,
            )
        try:
            execution_result, execution_exit_code = execute_blender_animation_operation_plan(plan_result.operation_plan)
        except ImportError:
            issue = _issue("blender_context_unavailable", "$.execution", "bpy could not be imported; run guarded execution inside Blender")
            return (
                {
                    "schema_version": "1.0",
                    "report_type": "blender_animation_adapter",
                    "status": "blender_unavailable",
                    "planned": True,
                    "executed": False,
                    "adapter_request_path": loaded.display_path,
                    "operation_plan": plan_result.operation_plan,
                    "execution_result": None,
                    "errors": [issue.as_report_item()],
                    "warnings": [],
                    "safety_flags": dict(PLAN_SAFETY_FLAGS, bpy_imported=False, blender_execution_attempted=True),
                },
                2,
            )
        return (
            {
                "schema_version": "1.0",
                "report_type": "blender_animation_adapter",
                "status": execution_result["status"],
                "planned": True,
                "executed": execution_result["status"] == "executed",
                "adapter_request_path": loaded.display_path,
                "operation_plan": plan_result.operation_plan,
                "execution_result": execution_result,
                "errors": execution_result.get("errors", []),
                "warnings": [],
                "safety_flags": execution_result["safety_flags"],
            },
            execution_exit_code,
        )
    return (
        {
            "schema_version": "1.0",
            "report_type": "blender_animation_adapter",
            "status": "planned",
            "planned": True,
            "executed": False,
            "adapter_request_path": loaded.display_path,
            "operation_plan": plan_result.operation_plan,
            "execution_result": None,
            "errors": [],
            "warnings": [],
            "safety_flags": dict(PLAN_SAFETY_FLAGS),
        },
        0,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build or guarded-execute a Blender animation operation plan.")
    parser.add_argument("--adapter-request", required=True, help="Adapter request JSON under configs/animation or /tmp.")
    parser.add_argument("--execute-animation", action="store_true", help="Execute only when REAL_ANIMATION_GENERATION=1 and running inside Blender.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON adapter report.")
    return parser


def _argv_after_blender_separator(argv: list[str] | None) -> list[str] | None:
    if argv is None:
        argv = sys.argv[1:]
    if "--" in argv:
        return argv[argv.index("--") + 1 :]
    return argv


def run(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(_argv_after_blender_separator(argv))
    report, exit_code = build_blender_animation_adapter_report(args.adapter_request, execute_animation=args.execute_animation)
    print(json.dumps(report, indent=2 if args.pretty else None, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(run())
