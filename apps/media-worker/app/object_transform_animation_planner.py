#!/usr/bin/env python3
"""Source-only deterministic object transform animation planner for M36.5."""

from __future__ import annotations

import argparse
import copy
import json
import math
import re
import sys
from dataclasses import dataclass
from typing import Any

sys.dont_write_bytecode = True

from animation_plan_validator import (  # noqa: E402
    ValidationIssue,
    _sanitize_plan_path,
    load_animation_plan,
    validate_animation_plan_semantics,
    validate_animation_plan_structure,
)
from animation_timeline_planner import (  # noqa: E402
    build_timeline_keyframe_plan,
    canonical_plan_hash,
)


TRANSFORM_FIELD_ORDER = ("location", "rotation_euler", "scale")
REQUEST_TRANSFORM_FIELDS = ("location", "rotation_euler_degrees", "scale")
REQUEST_TO_CANONICAL_FIELD = {
    "location": "location",
    "rotation_euler_degrees": "rotation_euler",
    "scale": "scale",
}
OBJECT_SAFETY_FLAGS = {
    "read_only": True,
    "runtime_assets_written": False,
    "source_assets_modified": False,
    "generation_triggered": False,
    "blender_execution_attempted": False,
    "preview_render_attempted": False,
    "external_process_started": False,
    "constraints_created": False,
    "keyframes_written": False,
    "objects_created": False,
    "objects_deleted": False,
    "scene_modified": False,
    "interpolation_evaluated": False,
}
COORDINATE_SYSTEM = {
    "handedness": "right_handed",
    "world_up_axis": "+Z",
    "euler_order": "XYZ",
    "request_rotation_unit": "degrees",
    "canonical_rotation_unit": "radians",
}
BLOCKED_MARKERS = ("/", "\\", "..", "://", "/home/", "/mnt/", "/media/", "/workspace/", "/app/", "MoE_Models_Backup")


@dataclass(frozen=True)
class ObjectPlannerIssue:
    code: str
    path: str
    message: str

    def as_report_item(self) -> dict[str, str]:
        return {"code": self.code, "path": self.path, "message": self.message}


@dataclass(frozen=True)
class ObjectTransformState:
    location: tuple[float, float, float] | None
    rotation_euler: tuple[float, float, float] | None
    scale: tuple[float, float, float] | None


@dataclass(frozen=True)
class ObjectPlannerResult:
    valid: bool
    object_plan: dict[str, Any] | None
    canonical_animation_plan: dict[str, Any] | None
    timeline_plan: dict[str, Any] | None
    issues: tuple[ObjectPlannerIssue | ValidationIssue, ...]
    warnings: tuple[ObjectPlannerIssue, ...] = tuple()
    exit_code: int = 0


def _issue(code: str, path: str, message: str) -> ObjectPlannerIssue:
    return ObjectPlannerIssue(code=code, path=path, message=message)


def _sort_issues(issues: list[ObjectPlannerIssue | ValidationIssue] | tuple[ObjectPlannerIssue | ValidationIssue, ...]) -> tuple[ObjectPlannerIssue | ValidationIssue, ...]:
    return tuple(sorted(issues, key=lambda item: (item.path, item.code, item.message)))


def _round_float(value: float) -> float:
    rounded = round(float(value), 9)
    return 0.0 if rounded == 0 else rounded


def _is_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def _canonical_request_hash(request: dict[str, Any]) -> str:
    return canonical_plan_hash(request)


def _check_unknown(value: dict[str, Any], allowed: set[str], path: str, issues: list[ObjectPlannerIssue]) -> None:
    for key in sorted(set(value) - allowed):
        issues.append(_issue("unknown_field", f"{path}.{key}", "field is not allowed"))


def _check_required(value: dict[str, Any], required: list[str], path: str, issues: list[ObjectPlannerIssue]) -> None:
    for key in required:
        if key not in value:
            issues.append(_issue("missing_required_field", f"{path}.{key}", "field is required"))


def _check_const(value: object, expected: object, path: str, issues: list[ObjectPlannerIssue]) -> None:
    if value != expected or type(value) is not type(expected):  # noqa: E721
        issues.append(_issue("const_mismatch", path, f"value must be {json.dumps(expected)}"))


def _check_string(value: object, path: str, issues: list[ObjectPlannerIssue], *, min_length: int = 0, max_length: int = 160) -> str | None:
    if not isinstance(value, str):
        issues.append(_issue("type_mismatch", path, "value must be a string"))
        return None
    if len(value) < min_length:
        issues.append(_issue("string_too_short", path, f"value must be at least {min_length} character(s)"))
    if len(value) > max_length:
        issues.append(_issue("string_too_long", path, f"value must be at most {max_length} character(s)"))
    return value


def _check_safe_id(value: object, path: str, issues: list[ObjectPlannerIssue], *, max_length: int = 160, lowercase_only: bool = False) -> str | None:
    text = _check_string(value, path, issues, min_length=1, max_length=max_length)
    if text is None:
        return None
    if text.startswith(".") or re.match(r"^[A-Za-z]:", text) or text.startswith("//") or any(marker in text for marker in BLOCKED_MARKERS):
        issues.append(_issue("unsafe_identifier", path, "identifier must not contain path, URL, runtime, repo, or model markers"))
    pattern = r"^[a-z0-9][a-z0-9_-]*$" if lowercase_only else r"^[A-Za-z0-9][A-Za-z0-9_-]*$"
    if not re.fullmatch(pattern, text):
        issues.append(_issue("unsafe_identifier", path, "identifier contains unsupported characters"))
    return text


def _check_int(value: object, path: str, issues: list[ObjectPlannerIssue], *, minimum: int, maximum: int | None = None) -> int | None:
    if not _is_int(value):
        issues.append(_issue("type_mismatch", path, "value must be an integer"))
        return None
    if value < minimum:
        issues.append(_issue("number_below_minimum", path, f"value must be >= {minimum}"))
    if maximum is not None and value > maximum:
        issues.append(_issue("number_above_maximum", path, f"value must be <= {maximum}"))
    return value


def _check_vector3(
    value: object,
    path: str,
    issues: list[ObjectPlannerIssue],
    *,
    minimum: float | None = None,
    exclusive_minimum: float | None = None,
    maximum: float | None = None,
) -> tuple[float, float, float] | None:
    if not isinstance(value, list):
        issues.append(_issue("type_mismatch", path, "value must be an array"))
        return None
    if len(value) != 3:
        issues.append(_issue("vector_length_invalid", path, "vector must contain exactly 3 values"))
        return None
    numbers: list[float] = []
    for index, item in enumerate(value):
        item_path = f"{path}[{index}]"
        if not _is_number(item):
            issues.append(_issue("type_mismatch", item_path, "vector value must be finite"))
            continue
        number = float(item)
        if minimum is not None and number < minimum:
            issues.append(_issue("number_below_minimum", item_path, f"value must be >= {minimum}"))
        if exclusive_minimum is not None and number <= exclusive_minimum:
            issues.append(_issue("number_below_minimum", item_path, f"value must be > {exclusive_minimum}"))
        if maximum is not None and number > maximum:
            issues.append(_issue("number_above_maximum", item_path, f"value must be <= {maximum}"))
        numbers.append(number)
    return tuple(numbers) if len(numbers) == 3 else None


def load_object_motion_request(request_path: str) -> tuple[dict[str, Any] | None, str, tuple[ObjectPlannerIssue | ValidationIssue, ...], int]:
    payload, display_path, load_issues = load_animation_plan(request_path)
    if load_issues or payload is None:
        return None, display_path, tuple(load_issues), 2
    return payload, display_path, tuple(), 0


def _validate_transform_state(value: object, path: str, issues: list[ObjectPlannerIssue]) -> dict[str, tuple[float, float, float]]:
    normalized: dict[str, tuple[float, float, float]] = {}
    if not isinstance(value, dict):
        issues.append(_issue("type_mismatch", path, "value must be an object"))
        return normalized
    _check_unknown(value, set(REQUEST_TRANSFORM_FIELDS), path, issues)
    if not any(field in value for field in REQUEST_TRANSFORM_FIELDS):
        issues.append(_issue("empty_transform", path, "at least one transform field is required"))
    if "location" in value:
        result = _check_vector3(value["location"], f"{path}.location", issues, minimum=-1000000, maximum=1000000)
        if result is not None:
            normalized["location"] = result
    if "rotation_euler_degrees" in value:
        result = _check_vector3(value["rotation_euler_degrees"], f"{path}.rotation_euler_degrees", issues, minimum=-36000, maximum=36000)
        if result is not None:
            normalized["rotation_euler_degrees"] = result
    if "scale" in value:
        result = _check_vector3(value["scale"], f"{path}.scale", issues, exclusive_minimum=0, maximum=1000000)
        if result is not None:
            normalized["scale"] = result
    return normalized


def validate_object_motion_request(request: dict[str, Any]) -> tuple[ObjectPlannerIssue, ...]:
    issues: list[ObjectPlannerIssue] = []
    required = [
        "schema_version",
        "request_id",
        "output_plan_id",
        "title",
        "description",
        "mode",
        "visual_reference_only",
        "structural_certification",
        "operator_review_required",
        "timeline",
        "scene",
        "object",
        "motion",
        "visibility",
        "outputs",
        "safety",
    ]
    _check_unknown(request, set(required), "$", issues)
    _check_required(request, required, "$", issues)
    _check_const(request.get("schema_version"), "1.0", "$.schema_version", issues)
    _check_safe_id(request.get("request_id"), "$.request_id", issues, max_length=80, lowercase_only=True)
    _check_safe_id(request.get("output_plan_id"), "$.output_plan_id", issues, max_length=80, lowercase_only=True)
    _check_string(request.get("title"), "$.title", issues, min_length=1, max_length=120)
    _check_string(request.get("description"), "$.description", issues, max_length=1000)
    _check_const(request.get("mode"), "dry_run", "$.mode", issues)
    _check_const(request.get("visual_reference_only"), True, "$.visual_reference_only", issues)
    _check_const(request.get("structural_certification"), False, "$.structural_certification", issues)
    _check_const(request.get("operator_review_required"), True, "$.operator_review_required", issues)

    timeline = request.get("timeline")
    if not isinstance(timeline, dict):
        issues.append(_issue("type_mismatch", "$.timeline", "value must be an object"))
        timeline = {}
    else:
        _check_unknown(timeline, {"fps", "start_frame", "end_frame"}, "$.timeline", issues)
        _check_required(timeline, ["fps", "start_frame", "end_frame"], "$.timeline", issues)
    _check_int(timeline.get("fps"), "$.timeline.fps", issues, minimum=1, maximum=120)
    start_frame = _check_int(timeline.get("start_frame"), "$.timeline.start_frame", issues, minimum=0)
    end_frame = _check_int(timeline.get("end_frame"), "$.timeline.end_frame", issues, minimum=1)
    if start_frame is not None and end_frame is not None and end_frame <= start_frame:
        issues.append(_issue("timeline_invalid_range", "$.timeline.end_frame", "end_frame must be greater than start_frame"))

    scene = request.get("scene")
    if not isinstance(scene, dict):
        issues.append(_issue("type_mismatch", "$.scene", "value must be an object"))
        scene = {}
    else:
        _check_unknown(scene, {"source_scene", "units"}, "$.scene", issues)
        _check_required(scene, ["source_scene", "units"], "$.scene", issues)
    source_scene = scene.get("source_scene")
    if not isinstance(source_scene, dict):
        issues.append(_issue("type_mismatch", "$.scene.source_scene", "value must be an object"))
    else:
        _check_unknown(source_scene, {"type", "reference_id"}, "$.scene.source_scene", issues)
        _check_required(source_scene, ["type", "reference_id"], "$.scene.source_scene", issues)
        _check_const(source_scene.get("type"), "existing_runtime_3d_asset", "$.scene.source_scene.type", issues)
        _check_safe_id(source_scene.get("reference_id"), "$.scene.source_scene.reference_id", issues)
    if scene.get("units") not in {"meters", "centimeters", "millimeters"}:
        issues.append(_issue("enum_mismatch", "$.scene.units", "units must be meters, centimeters, or millimeters"))

    object_block = request.get("object")
    if not isinstance(object_block, dict):
        issues.append(_issue("type_mismatch", "$.object", "value must be an object"))
        object_block = {}
    else:
        _check_unknown(object_block, {"object_id"}, "$.object", issues)
        _check_required(object_block, ["object_id"], "$.object", issues)
    _check_safe_id(object_block.get("object_id"), "$.object.object_id", issues)

    motion = request.get("motion")
    start_state: dict[str, tuple[float, float, float]] = {}
    end_state: dict[str, tuple[float, float, float]] = {}
    if not isinstance(motion, dict):
        issues.append(_issue("type_mismatch", "$.motion", "value must be an object"))
        motion = {}
    else:
        _check_unknown(motion, {"type", "interpolation", "start", "end"}, "$.motion", issues)
        _check_required(motion, ["type", "interpolation", "start", "end"], "$.motion", issues)
    if motion.get("type") != "transform_between":
        issues.append(_issue("unsupported_motion_type", "$.motion.type", "only transform_between motion is supported"))
    if motion.get("interpolation") not in {"constant", "linear", "bezier"}:
        issues.append(_issue("enum_mismatch", "$.motion.interpolation", "interpolation must be constant, linear, or bezier"))
    start_state = _validate_transform_state(motion.get("start"), "$.motion.start", issues)
    end_state = _validate_transform_state(motion.get("end"), "$.motion.end", issues)
    start_fields = set(start_state)
    end_fields = set(end_state)
    raw_start = motion.get("start") if isinstance(motion.get("start"), dict) else {}
    raw_end = motion.get("end") if isinstance(motion.get("end"), dict) else {}
    raw_start_fields = set(raw_start) & set(REQUEST_TRANSFORM_FIELDS)
    raw_end_fields = set(raw_end) & set(REQUEST_TRANSFORM_FIELDS)
    if raw_start_fields != raw_end_fields or start_fields != end_fields:
        issues.append(_issue("transform_field_mismatch", "$.motion", "start and end transform fields must match exactly"))

    visibility = request.get("visibility")
    if not isinstance(visibility, dict):
        issues.append(_issue("type_mismatch", "$.visibility", "value must be an object"))
        visibility = {}
    else:
        _check_unknown(visibility, {"enabled", "start_visible", "end_visible", "interpolation"}, "$.visibility", issues)
        _check_required(visibility, ["enabled", "start_visible", "end_visible", "interpolation"], "$.visibility", issues)
    for key in ("enabled", "start_visible", "end_visible"):
        if not isinstance(visibility.get(key), bool):
            issues.append(_issue("type_mismatch", f"$.visibility.{key}", "value must be a boolean"))
    if visibility.get("interpolation") != "constant":
        issues.append(_issue("enum_mismatch", "$.visibility.interpolation", "visibility interpolation must be constant"))

    outputs = request.get("outputs")
    safety = request.get("safety")
    if not isinstance(outputs, dict):
        issues.append(_issue("type_mismatch", "$.outputs", "value must be an object"))
    if not isinstance(safety, dict):
        issues.append(_issue("type_mismatch", "$.safety", "value must be an object"))
    else:
        for key in ("real_animation_enabled", "blender_execution_enabled", "preview_render_enabled", "source_assets_modified", "runtime_write_planned"):
            _check_const(safety.get(key), False, f"$.safety.{key}", issues)

    return _sort_issues(issues)  # type: ignore[return-value]


def _normalize_vector(values: tuple[float, float, float]) -> tuple[float, float, float]:
    return tuple(_round_float(value) for value in values)


def _degrees_to_radians(values: tuple[float, float, float]) -> tuple[float, float, float]:
    return tuple(_round_float(value * math.pi / 180.0) for value in values)


def normalize_object_transform(state: dict[str, Any]) -> ObjectTransformState:
    return ObjectTransformState(
        location=_normalize_vector(tuple(float(item) for item in state["location"])) if "location" in state else None,
        rotation_euler=_degrees_to_radians(tuple(float(item) for item in state["rotation_euler_degrees"])) if "rotation_euler_degrees" in state else None,
        scale=_normalize_vector(tuple(float(item) for item in state["scale"])) if "scale" in state else None,
    )


def _transform_fields(start: ObjectTransformState, end: ObjectTransformState) -> tuple[str, ...]:
    fields: list[str] = []
    for field in TRANSFORM_FIELD_ORDER:
        if getattr(start, field) is not None and getattr(end, field) is not None:
            fields.append(field)
    return tuple(fields)


def _state_values(state: ObjectTransformState, fields: tuple[str, ...]) -> dict[str, list[float]]:
    return {field: list(getattr(state, field)) for field in fields}


def _track_id(object_id: str, suffix: str) -> str:
    safe = re.sub(r"[^a-z0-9_-]+", "-", object_id.lower()).strip("-")
    return f"object-{safe or 'object'}-{suffix}"


def _duration_seconds(timeline: dict[str, Any]) -> float:
    return _round_float((int(timeline["end_frame"]) - int(timeline["start_frame"]) + 1) / int(timeline["fps"]))


def _build_canonical_animation_plan(
    request: dict[str, Any],
    start_transform: ObjectTransformState,
    end_transform: ObjectTransformState,
    fields: tuple[str, ...],
) -> dict[str, Any]:
    object_id = request["object"]["object_id"]
    start_frame = int(request["timeline"]["start_frame"])
    end_frame = int(request["timeline"]["end_frame"])
    tracks: list[dict[str, Any]] = [
        {
            "track_id": _track_id(object_id, "transform"),
            "target_type": "object",
            "target_id": object_id,
            "property": "transform",
            "interpolation": request["motion"]["interpolation"],
            "keyframes": [
                {"frame": start_frame, **_state_values(start_transform, fields)},
                {"frame": end_frame, **_state_values(end_transform, fields)},
            ],
        }
    ]
    visibility = request["visibility"]
    if visibility["enabled"]:
        tracks.append(
            {
                "track_id": _track_id(object_id, "visibility"),
                "target_type": "object",
                "target_id": object_id,
                "property": "visibility",
                "interpolation": "constant",
                "keyframes": [
                    {"frame": start_frame, "visibility": bool(visibility["start_visible"])},
                    {"frame": end_frame, "visibility": bool(visibility["end_visible"])},
                ],
            }
        )
    return {
        "schema_version": "1.0",
        "plan_id": request["output_plan_id"],
        "title": request["title"],
        "description": request["description"],
        "mode": "dry_run",
        "visual_reference_only": True,
        "structural_certification": False,
        "operator_review_required": True,
        "timeline": {
            "fps": int(request["timeline"]["fps"]),
            "start_frame": start_frame,
            "end_frame": end_frame,
            "duration_seconds": _duration_seconds(request["timeline"]),
        },
        "scene": copy.deepcopy(request["scene"]),
        "tracks": tracks,
        "outputs": copy.deepcopy(request["outputs"]),
        "safety": copy.deepcopy(request["safety"]),
    }


def _same_transform(start: ObjectTransformState, end: ObjectTransformState, fields: tuple[str, ...]) -> bool:
    return all(getattr(start, field) == getattr(end, field) for field in fields)


def build_object_animation_plan(request: dict[str, Any]) -> ObjectPlannerResult:
    safe_request = copy.deepcopy(request)
    request_issues = validate_object_motion_request(safe_request)
    if request_issues:
        return ObjectPlannerResult(False, None, None, None, request_issues, tuple(), 1)
    start_transform = normalize_object_transform(safe_request["motion"]["start"])
    end_transform = normalize_object_transform(safe_request["motion"]["end"])
    fields = _transform_fields(start_transform, end_transform)
    warnings: tuple[ObjectPlannerIssue, ...] = tuple()
    if _same_transform(start_transform, end_transform, fields):
        warnings = (_issue("object_transform_unchanged", "$.motion", "start and end transform values are identical"),)
    canonical = _build_canonical_animation_plan(safe_request, start_transform, end_transform, fields)
    validation_issues = list(validate_animation_plan_structure(canonical))
    if not validation_issues:
        validation_issues.extend(validate_animation_plan_semantics(canonical))
    if validation_issues:
        return ObjectPlannerResult(False, None, canonical, None, _sort_issues(validation_issues), warnings, 1)
    timeline_result = build_timeline_keyframe_plan(canonical)
    if not timeline_result.valid or timeline_result.plan is None:
        return ObjectPlannerResult(False, None, canonical, None, timeline_result.issues, warnings, 1)

    transform_track_count = 1
    visibility_track_count = 1 if safe_request["visibility"]["enabled"] else 0
    object_plan = {
        "schema_version": "1.0",
        "plan_type": "object_transform_animation_plan",
        "status": "planned",
        "mode": "dry_run",
        "request_id": safe_request["request_id"],
        "request_sha256": _canonical_request_hash(safe_request),
        "motion_type": "transform_between",
        "coordinate_system": dict(COORDINATE_SYSTEM),
        "object_settings": {
            "object_id": safe_request["object"]["object_id"],
            "runtime_resolved": False,
        },
        "transform": {
            "animated_fields": list(fields),
            "start_frame": int(safe_request["timeline"]["start_frame"]),
            "end_frame": int(safe_request["timeline"]["end_frame"]),
        },
        "visibility": {
            "enabled": bool(safe_request["visibility"]["enabled"]),
            "track_created": bool(safe_request["visibility"]["enabled"]),
        },
        "canonical_animation_plan": canonical,
        "timeline_plan": timeline_result.plan,
        "summary": {
            "object_track_count": transform_track_count + visibility_track_count,
            "transform_track_count": transform_track_count,
            "visibility_track_count": visibility_track_count,
            "keyframe_count": 2 + (2 if visibility_track_count else 0),
        },
        "warnings": [warning.as_report_item() for warning in warnings],
        "safety_flags": dict(OBJECT_SAFETY_FLAGS),
    }
    return ObjectPlannerResult(True, object_plan, canonical, timeline_result.plan, tuple(), warnings, 0)


def _issue_items(issues: tuple[ObjectPlannerIssue | ValidationIssue, ...]) -> list[dict[str, str]]:
    return [issue.as_report_item() for issue in _sort_issues(issues)]


def build_object_planner_report(request_path: str) -> tuple[dict[str, Any], int]:
    request, display_path, load_issues, load_exit = load_object_motion_request(request_path)
    if load_issues or request is None:
        return (
            {
                "schema_version": "1.0",
                "report_type": "object_transform_animation_planner",
                "status": "invalid",
                "planned": False,
                "request_path": display_path,
                "object_plan": None,
                "errors": _issue_items(load_issues),
                "warnings": [],
                "safety_flags": dict(OBJECT_SAFETY_FLAGS),
            },
            load_exit,
        )
    result = build_object_animation_plan(request)
    planned = result.valid and result.object_plan is not None
    return (
        {
            "schema_version": "1.0",
            "report_type": "object_transform_animation_planner",
            "status": "planned" if planned else "invalid",
            "planned": planned,
            "request_path": _sanitize_plan_path(display_path),
            "object_plan": result.object_plan if planned else None,
            "errors": _issue_items(result.issues),
            "warnings": [warning.as_report_item() for warning in result.warnings],
            "safety_flags": dict(OBJECT_SAFETY_FLAGS),
        },
        0 if planned else result.exit_code,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build a source-only deterministic object transform animation plan.")
    parser.add_argument("--request", required=True, help="Object motion request under configs/animation or /tmp.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON planner report.")
    return parser


def run(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    report, exit_code = build_object_planner_report(args.request)
    print(json.dumps(report, indent=2 if args.pretty else None, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(run())
