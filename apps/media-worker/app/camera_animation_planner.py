#!/usr/bin/env python3
"""Source-only deterministic camera animation planner for M36.4."""

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


CAMERA_SAFETY_FLAGS = {
    "read_only": True,
    "runtime_assets_written": False,
    "source_assets_modified": False,
    "generation_triggered": False,
    "blender_execution_attempted": False,
    "preview_render_attempted": False,
    "external_process_started": False,
    "constraints_created": False,
    "keyframes_written": False,
    "camera_created": False,
    "scene_modified": False,
}
COORDINATE_SYSTEM = {
    "handedness": "right_handed",
    "world_up_axis": "+Z",
    "orbit_plane": "XY",
    "camera_forward_axis": "-Z",
    "camera_up_axis": "+Y",
    "euler_order": "XYZ",
    "rotation_unit": "radians",
}
ANIMATION_FIELDS = ("location", "rotation_euler", "scale", "visibility")
BLOCKED_MARKERS = ("/", "\\", "..", "://", "/home/", "/mnt/", "/media/", "/workspace/", "/app/", "MoE_Models_Backup")


@dataclass(frozen=True)
class CameraPlannerIssue:
    code: str
    path: str
    message: str

    def as_report_item(self) -> dict[str, str]:
        return {"code": self.code, "path": self.path, "message": self.message}


@dataclass(frozen=True)
class CameraPose:
    sequence: int
    frame: int
    angle_degrees: float
    angle_radians: float
    location: tuple[float, float, float]
    rotation_euler: tuple[float, float, float]


@dataclass(frozen=True)
class CameraPlanResult:
    valid: bool
    camera_plan: dict[str, Any] | None
    canonical_animation_plan: dict[str, Any] | None
    timeline_plan: dict[str, Any] | None
    issues: tuple[CameraPlannerIssue | ValidationIssue, ...]
    exit_code: int = 0


def _issue(code: str, path: str, message: str) -> CameraPlannerIssue:
    return CameraPlannerIssue(code=code, path=path, message=message)


def _sort_issues(issues: list[CameraPlannerIssue | ValidationIssue] | tuple[CameraPlannerIssue | ValidationIssue, ...]) -> tuple[CameraPlannerIssue | ValidationIssue, ...]:
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


def _check_unknown(value: dict[str, Any], allowed: set[str], path: str, issues: list[CameraPlannerIssue]) -> None:
    for key in sorted(set(value) - allowed):
        issues.append(_issue("unknown_field", f"{path}.{key}", "field is not allowed"))


def _check_required(value: dict[str, Any], required: list[str], path: str, issues: list[CameraPlannerIssue]) -> None:
    for key in required:
        if key not in value:
            issues.append(_issue("missing_required_field", f"{path}.{key}", "field is required"))


def _check_const(value: object, expected: object, path: str, issues: list[CameraPlannerIssue]) -> None:
    if value != expected or type(value) is not type(expected):  # noqa: E721
        issues.append(_issue("const_mismatch", path, f"value must be {json.dumps(expected)}"))


def _check_string(value: object, path: str, issues: list[CameraPlannerIssue], *, min_length: int = 0, max_length: int = 160) -> str | None:
    if not isinstance(value, str):
        issues.append(_issue("type_mismatch", path, "value must be a string"))
        return None
    if len(value) < min_length:
        issues.append(_issue("string_too_short", path, f"value must be at least {min_length} character(s)"))
    if len(value) > max_length:
        issues.append(_issue("string_too_long", path, f"value must be at most {max_length} character(s)"))
    return value


def _check_safe_id(value: object, path: str, issues: list[CameraPlannerIssue], *, max_length: int = 160, lowercase_only: bool = False) -> str | None:
    text = _check_string(value, path, issues, min_length=1, max_length=max_length)
    if text is None:
        return None
    if text.startswith(".") or re.match(r"^[A-Za-z]:", text) or text.startswith("//") or any(marker in text for marker in BLOCKED_MARKERS):
        issues.append(_issue("unsafe_identifier", path, "identifier must not contain path, URL, runtime, repo, or model markers"))
    pattern = r"^[a-z0-9][a-z0-9_-]*$" if lowercase_only else r"^[A-Za-z0-9][A-Za-z0-9_-]*$"
    if not re.fullmatch(pattern, text):
        issues.append(_issue("unsafe_identifier", path, "identifier contains unsupported characters"))
    return text


def _check_number(value: object, path: str, issues: list[CameraPlannerIssue], *, minimum: float | None = None, exclusive_minimum: float | None = None, maximum: float | None = None) -> float | None:
    if not _is_number(value):
        issues.append(_issue("type_mismatch", path, "value must be a finite number"))
        return None
    number = float(value)
    if minimum is not None and number < minimum:
        issues.append(_issue("number_below_minimum", path, f"value must be >= {minimum}"))
    if exclusive_minimum is not None and number <= exclusive_minimum:
        issues.append(_issue("number_below_minimum", path, f"value must be > {exclusive_minimum}"))
    if maximum is not None and number > maximum:
        issues.append(_issue("number_above_maximum", path, f"value must be <= {maximum}"))
    return number


def _check_int(value: object, path: str, issues: list[CameraPlannerIssue], *, minimum: int, maximum: int | None = None) -> int | None:
    if not _is_int(value):
        issues.append(_issue("type_mismatch", path, "value must be an integer"))
        return None
    if value < minimum:
        issues.append(_issue("number_below_minimum", path, f"value must be >= {minimum}"))
    if maximum is not None and value > maximum:
        issues.append(_issue("number_above_maximum", path, f"value must be <= {maximum}"))
    return value


def _check_vector3(value: object, path: str, issues: list[CameraPlannerIssue]) -> tuple[float, float, float] | None:
    if not isinstance(value, list):
        issues.append(_issue("type_mismatch", path, "value must be an array"))
        return None
    if len(value) != 3:
        issues.append(_issue("vector_length_invalid", path, "vector must contain exactly 3 values"))
        return None
    numbers: list[float] = []
    for index, item in enumerate(value):
        if not _is_number(item):
            issues.append(_issue("type_mismatch", f"{path}[{index}]", "vector value must be finite"))
        else:
            numbers.append(float(item))
    return tuple(numbers) if len(numbers) == 3 else None


def load_camera_motion_request(request_path: str) -> tuple[dict[str, Any] | None, str, tuple[CameraPlannerIssue | ValidationIssue, ...], int]:
    payload, display_path, load_issues = load_animation_plan(request_path)
    if load_issues or payload is None:
        return None, display_path, tuple(load_issues), 2
    return payload, display_path, tuple(), 0


def validate_camera_motion_request(request: dict[str, Any]) -> tuple[CameraPlannerIssue, ...]:
    issues: list[CameraPlannerIssue] = []
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
        "camera",
        "motion",
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
    fps = _check_int(timeline.get("fps"), "$.timeline.fps", issues, minimum=1, maximum=120)
    start_frame = _check_int(timeline.get("start_frame"), "$.timeline.start_frame", issues, minimum=0)
    end_frame = _check_int(timeline.get("end_frame"), "$.timeline.end_frame", issues, minimum=1)
    total_frames = None
    if start_frame is not None and end_frame is not None:
        if end_frame <= start_frame:
            issues.append(_issue("timeline_invalid_range", "$.timeline.end_frame", "end_frame must be greater than start_frame"))
        else:
            total_frames = end_frame - start_frame + 1

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

    camera = request.get("camera")
    if not isinstance(camera, dict):
        issues.append(_issue("type_mismatch", "$.camera", "value must be an object"))
        camera = {}
    else:
        _check_unknown(camera, {"camera_id", "lens_mm"}, "$.camera", issues)
        _check_required(camera, ["camera_id", "lens_mm"], "$.camera", issues)
    _check_safe_id(camera.get("camera_id"), "$.camera.camera_id", issues)
    _check_number(camera.get("lens_mm"), "$.camera.lens_mm", issues, minimum=1.0, maximum=300.0)

    motion = request.get("motion")
    if not isinstance(motion, dict):
        issues.append(_issue("type_mismatch", "$.motion", "value must be an object"))
        motion = {}
    else:
        _check_unknown(motion, {"type", "center", "radius", "height_offset", "start_angle_degrees", "end_angle_degrees", "keyframe_count", "interpolation", "orientation"}, "$.motion", issues)
        _check_required(motion, ["type", "center", "radius", "height_offset", "start_angle_degrees", "end_angle_degrees", "keyframe_count", "interpolation", "orientation"], "$.motion", issues)
    if motion.get("type") != "orbit":
        issues.append(_issue("unsupported_motion_type", "$.motion.type", "only orbit motion is supported"))
    if motion.get("orientation") != "look_at_center":
        issues.append(_issue("unsupported_orientation", "$.motion.orientation", "only look_at_center orientation is supported"))
    center = _check_vector3(motion.get("center"), "$.motion.center", issues)
    radius = _check_number(motion.get("radius"), "$.motion.radius", issues, exclusive_minimum=0, maximum=1000000)
    height_offset = _check_number(motion.get("height_offset"), "$.motion.height_offset", issues, minimum=-1000000, maximum=1000000)
    start_angle = _check_number(motion.get("start_angle_degrees"), "$.motion.start_angle_degrees", issues, minimum=-36000, maximum=36000)
    end_angle = _check_number(motion.get("end_angle_degrees"), "$.motion.end_angle_degrees", issues, minimum=-36000, maximum=36000)
    keyframe_count = _check_int(motion.get("keyframe_count"), "$.motion.keyframe_count", issues, minimum=2, maximum=64)
    if motion.get("interpolation") not in {"constant", "linear", "bezier"}:
        issues.append(_issue("enum_mismatch", "$.motion.interpolation", "interpolation must be constant, linear, or bezier"))
    if start_angle is not None and end_angle is not None:
        if end_angle == start_angle:
            issues.append(_issue("orbit_angle_span_invalid", "$.motion.end_angle_degrees", "end angle must differ from start angle"))
        if abs(end_angle - start_angle) > 3600:
            issues.append(_issue("orbit_angle_span_invalid", "$.motion.end_angle_degrees", "absolute orbit angle span must be <= 3600 degrees"))
    if keyframe_count is not None and total_frames is not None and keyframe_count > total_frames:
        issues.append(_issue("keyframe_count_exceeds_timeline", "$.motion.keyframe_count", "keyframe_count must be <= total frame count"))
    if center is not None and radius is not None and height_offset is not None and radius == 0 and height_offset == 0:
        issues.append(_issue("look_at_collision", "$.motion.center", "camera position must not equal look-at center"))

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


def build_orbit_frame_numbers(start_frame: int, end_frame: int, keyframe_count: int) -> tuple[int, ...]:
    span = end_frame - start_frame
    return tuple(start_frame + (index * span) // (keyframe_count - 1) for index in range(keyframe_count))


def _normalize_angle_radians(value: float) -> float:
    wrapped = (value + math.pi) % (2 * math.pi) - math.pi
    return _round_float(wrapped)


def build_look_at_rotation_euler(location: tuple[float, float, float], center: tuple[float, float, float]) -> tuple[float, float, float]:
    dx = center[0] - location[0]
    dy = center[1] - location[1]
    dz = center[2] - location[2]
    horizontal = math.sqrt(dx * dx + dy * dy)
    if horizontal == 0 and dz == 0:
        raise ValueError("camera position equals look-at center")
    return (
        _round_float(math.atan2(horizontal, -dz)),
        0.0,
        _normalize_angle_radians(math.atan2(dy, dx) - math.pi / 2),
    )


def build_orbit_positions(request: dict[str, Any]) -> tuple[CameraPose, ...]:
    timeline = request["timeline"]
    motion = request["motion"]
    center = tuple(float(item) for item in motion["center"])
    radius = float(motion["radius"])
    height_offset = float(motion["height_offset"])
    start_angle = float(motion["start_angle_degrees"])
    end_angle = float(motion["end_angle_degrees"])
    keyframe_count = int(motion["keyframe_count"])
    frames = build_orbit_frame_numbers(int(timeline["start_frame"]), int(timeline["end_frame"]), keyframe_count)
    poses: list[CameraPose] = []
    for index, frame in enumerate(frames):
        fraction = index / (keyframe_count - 1)
        angle_degrees = _round_float(start_angle + fraction * (end_angle - start_angle))
        angle_radians_raw = math.radians(angle_degrees)
        angle_radians = _round_float(angle_radians_raw)
        location = (
            _round_float(center[0] + radius * math.cos(angle_radians_raw)),
            _round_float(center[1] + radius * math.sin(angle_radians_raw)),
            _round_float(center[2] + height_offset),
        )
        poses.append(
            CameraPose(
                sequence=index,
                frame=frame,
                angle_degrees=angle_degrees,
                angle_radians=angle_radians,
                location=location,
                rotation_euler=build_look_at_rotation_euler(location, center),
            )
        )
    return tuple(poses)


def _serialize_pose(pose: CameraPose) -> dict[str, Any]:
    return {
        "sequence": pose.sequence,
        "frame": pose.frame,
        "angle_degrees": pose.angle_degrees,
        "angle_radians": pose.angle_radians,
        "location": list(pose.location),
        "rotation_euler": list(pose.rotation_euler),
    }


def _track_id(camera_id: str) -> str:
    safe = re.sub(r"[^a-z0-9_-]+", "-", camera_id.lower()).strip("-")
    return f"camera-{safe or 'camera'}-transform"


def _duration_seconds(timeline: dict[str, Any]) -> float:
    return _round_float((int(timeline["end_frame"]) - int(timeline["start_frame"]) + 1) / int(timeline["fps"]))


def _build_canonical_animation_plan(request: dict[str, Any], poses: tuple[CameraPose, ...]) -> dict[str, Any]:
    camera_id = request["camera"]["camera_id"]
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
            "start_frame": int(request["timeline"]["start_frame"]),
            "end_frame": int(request["timeline"]["end_frame"]),
            "duration_seconds": _duration_seconds(request["timeline"]),
        },
        "scene": copy.deepcopy(request["scene"]),
        "tracks": [
            {
                "track_id": _track_id(camera_id),
                "target_type": "camera",
                "target_id": camera_id,
                "property": "transform",
                "interpolation": request["motion"]["interpolation"],
                "keyframes": [
                    {
                        "frame": pose.frame,
                        "location": list(pose.location),
                        "rotation_euler": list(pose.rotation_euler),
                    }
                    for pose in poses
                ],
            }
        ],
        "outputs": copy.deepcopy(request["outputs"]),
        "safety": copy.deepcopy(request["safety"]),
    }


def build_camera_animation_plan(request: dict[str, Any]) -> CameraPlanResult:
    safe_request = copy.deepcopy(request)
    request_issues = validate_camera_motion_request(safe_request)
    if request_issues:
        return CameraPlanResult(False, None, None, None, request_issues, 1)
    try:
        poses = build_orbit_positions(safe_request)
    except ValueError as exc:
        return CameraPlanResult(False, None, None, None, (_issue("look_at_collision", "$.motion.center", str(exc)),), 1)
    canonical = _build_canonical_animation_plan(safe_request, poses)
    validation_issues = list(validate_animation_plan_structure(canonical))
    if not validation_issues:
        validation_issues.extend(validate_animation_plan_semantics(canonical))
    if validation_issues:
        return CameraPlanResult(False, None, canonical, None, _sort_issues(validation_issues), 1)
    timeline_result = build_timeline_keyframe_plan(canonical)
    if not timeline_result.valid or timeline_result.plan is None:
        return CameraPlanResult(False, None, canonical, None, timeline_result.issues, 1)

    camera_plan = {
        "schema_version": "1.0",
        "plan_type": "camera_animation_plan",
        "status": "planned",
        "mode": "dry_run",
        "request_id": safe_request["request_id"],
        "request_sha256": _canonical_request_hash(safe_request),
        "motion_type": "orbit",
        "coordinate_system": dict(COORDINATE_SYSTEM),
        "camera_settings": {
            "camera_id": safe_request["camera"]["camera_id"],
            "lens_mm": _round_float(float(safe_request["camera"]["lens_mm"])),
            "animated": False,
        },
        "orbit": {
            "center": [_round_float(float(item)) for item in safe_request["motion"]["center"]],
            "radius": _round_float(float(safe_request["motion"]["radius"])),
            "height_offset": _round_float(float(safe_request["motion"]["height_offset"])),
            "start_angle_degrees": _round_float(float(safe_request["motion"]["start_angle_degrees"])),
            "end_angle_degrees": _round_float(float(safe_request["motion"]["end_angle_degrees"])),
            "keyframe_count": int(safe_request["motion"]["keyframe_count"]),
        },
        "poses": [_serialize_pose(pose) for pose in poses],
        "canonical_animation_plan": canonical,
        "timeline_plan": timeline_result.plan,
        "summary": {
            "pose_count": len(poses),
            "first_frame": poses[0].frame,
            "last_frame": poses[-1].frame,
            "camera_track_count": 1,
        },
        "safety_flags": dict(CAMERA_SAFETY_FLAGS),
    }
    return CameraPlanResult(True, camera_plan, canonical, timeline_result.plan, tuple(), 0)


def _issue_items(issues: tuple[CameraPlannerIssue | ValidationIssue, ...]) -> list[dict[str, str]]:
    return [issue.as_report_item() for issue in _sort_issues(issues)]


def build_camera_planner_report(request_path: str) -> tuple[dict[str, Any], int]:
    request, display_path, load_issues, load_exit = load_camera_motion_request(request_path)
    if load_issues or request is None:
        return (
            {
                "schema_version": "1.0",
                "report_type": "camera_animation_planner",
                "status": "invalid",
                "planned": False,
                "request_path": display_path,
                "camera_plan": None,
                "errors": _issue_items(load_issues),
                "warnings": [],
                "safety_flags": dict(CAMERA_SAFETY_FLAGS),
            },
            load_exit,
        )
    result = build_camera_animation_plan(request)
    planned = result.valid and result.camera_plan is not None
    return (
        {
            "schema_version": "1.0",
            "report_type": "camera_animation_planner",
            "status": "planned" if planned else "invalid",
            "planned": planned,
            "request_path": _sanitize_plan_path(display_path),
            "camera_plan": result.camera_plan if planned else None,
            "errors": _issue_items(result.issues),
            "warnings": [],
            "safety_flags": dict(CAMERA_SAFETY_FLAGS),
        },
        0 if planned else result.exit_code,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build a source-only deterministic camera animation plan.")
    parser.add_argument("--request", required=True, help="Camera motion request under configs/animation or /tmp.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON planner report.")
    return parser


def run(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    report, exit_code = build_camera_planner_report(args.request)
    print(json.dumps(report, indent=2 if args.pretty else None, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(run())
