#!/usr/bin/env python3
"""Source-only animation plan validator for M36.2.

This module intentionally performs no runtime asset resolution, no Blender
imports, no rendering, and no writes. It validates source config or /tmp
fixture plans and emits deterministic JSON reports.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

try:
    import yaml
except ImportError:  # pragma: no cover - exercised only when tooling is absent.
    yaml = None  # type: ignore[assignment]


REPO_ROOT = Path(__file__).resolve().parents[3]
CONFIG_ROOT = REPO_ROOT / "configs" / "animation"
SCHEMA_PATH = CONFIG_ROOT / "animation-plan.schema.json"
MAX_INPUT_BYTES = 256 * 1024
ALLOWED_CONFIG_EXTENSIONS = {".yaml", ".yml", ".json"}
SAFETY_FLAGS = {
    "read_only": True,
    "runtime_assets_written": False,
    "source_assets_modified": False,
    "generation_triggered": False,
    "blender_execution_attempted": False,
    "preview_render_attempted": False,
    "external_process_started": False,
}
EMPTY_SUMMARY = {
    "plan_id": None,
    "fps": None,
    "start_frame": None,
    "end_frame": None,
    "duration_seconds": None,
    "track_count": 0,
    "keyframe_count": 0,
    "target_types": [],
    "properties": [],
    "interpolations": [],
}
BLOCKED_ID_MARKERS = (
    "/",
    "\\",
    "..",
    "://",
    "/home/",
    "/mnt/",
    "/media/",
    "/workspace/",
    "/app/",
    "MoE_Models_Backup",
)
BLOCKED_PATH_MARKERS = (
    "/home/",
    "/mnt/",
    "/media/",
    "/workspace/",
    "/app/",
    "MoE_Models_Backup",
    "DiskD/Projects/MoE/codebase",
)


@dataclass(frozen=True)
class ValidationIssue:
    code: str
    path: str
    message: str
    severity: str = "error"

    def as_report_item(self) -> dict[str, str]:
        return {
            "code": self.code,
            "path": self.path,
            "message": self.message,
        }


def _issue(code: str, path: str, message: str, severity: str = "error") -> ValidationIssue:
    return ValidationIssue(code=code, path=path, message=message, severity=severity)


def _sort_issues(issues: list[ValidationIssue]) -> list[ValidationIssue]:
    return sorted(issues, key=lambda issue: (issue.path, issue.code, issue.message))


def _is_bool(value: object) -> bool:
    return isinstance(value, bool)


def _is_integer(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def _mapping(value: object) -> dict[str, Any] | None:
    return value if isinstance(value, dict) else None


def _sanitize_plan_path(raw_path: str) -> str:
    raw = str(raw_path)
    path = Path(raw)
    if raw.startswith("/tmp/"):
        return f"/tmp/{path.name}"
    if raw.startswith("configs/animation/"):
        return raw
    return path.name or "invalid-plan-path"


def _is_safe_input_path(raw_plan_path: str) -> tuple[Path | None, str, ValidationIssue | None]:
    display_path = _sanitize_plan_path(raw_plan_path)
    raw = str(raw_plan_path)
    raw_path = Path(raw)

    if ".." in raw_path.parts:
        return None, display_path, _issue("unsafe_input_path", "$.plan_path", "plan path must not contain traversal")
    if raw_path.suffix.lower() not in ALLOWED_CONFIG_EXTENSIONS:
        return None, display_path, _issue("unsupported_input_extension", "$.plan_path", "plan must use .yaml, .yml, or .json")

    if raw.startswith("configs/animation/") and len(raw_path.parts) == 3:
        candidate = REPO_ROOT / raw_path
        display_path = raw
    elif raw_path.is_absolute() and raw_path.parent == Path("/tmp"):
        candidate = raw_path
        display_path = f"/tmp/{raw_path.name}"
    else:
        return None, display_path, _issue(
            "input_path_not_allowlisted",
            "$.plan_path",
            "plan path must be configs/animation/<file> or /tmp/<file>",
        )

    try:
        stat_result = candidate.lstat()
    except OSError:
        return None, display_path, _issue("input_file_unreadable", "$.plan_path", "plan file could not be inspected")
    if candidate.is_symlink():
        return None, display_path, _issue("input_symlink_rejected", "$.plan_path", "plan input symlinks are rejected")
    if not candidate.is_file():
        return None, display_path, _issue("input_not_regular_file", "$.plan_path", "plan input must be a regular file")
    if stat_result.st_size > MAX_INPUT_BYTES:
        return None, display_path, _issue("input_too_large", "$.plan_path", "plan input exceeds 256 KiB")
    return candidate, display_path, None


def load_animation_plan_schema() -> dict[str, Any]:
    try:
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError("canonical animation plan schema could not be loaded") from exc
    if not isinstance(schema, dict):
        raise ValueError("canonical animation plan schema root must be an object")
    return schema


def load_animation_plan(plan_path: str) -> tuple[dict[str, Any] | None, str, list[ValidationIssue]]:
    candidate, display_path, path_issue = _is_safe_input_path(plan_path)
    if path_issue is not None or candidate is None:
        return None, display_path, [path_issue] if path_issue else []

    try:
        text = candidate.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None, display_path, [_issue("input_not_utf8", "$.plan_path", "plan file must be valid UTF-8")]
    except OSError:
        return None, display_path, [_issue("input_file_unreadable", "$.plan_path", "plan file could not be read")]

    suffix = candidate.suffix.lower()
    try:
        if suffix == ".json":
            loaded = json.loads(text)
        else:
            if yaml is None:
                return None, display_path, [_issue("yaml_unavailable", "$.plan_path", "PyYAML is unavailable")]
            loaded = yaml.safe_load(text)
    except json.JSONDecodeError:
        return None, display_path, [_issue("malformed_json", "$.plan_path", "plan JSON is malformed")]
    except Exception:
        return None, display_path, [_issue("malformed_yaml", "$.plan_path", "plan YAML is malformed")]

    if loaded is None:
        loaded = {}
    if not isinstance(loaded, dict):
        return None, display_path, [_issue("root_not_object", "$", "animation plan root must be an object")]
    return loaded, display_path, []


def _enum(schema: dict[str, Any], ref: str) -> list[str]:
    current: Any = schema
    for part in ref.split("."):
        current = current[part]
    return list(current)


def _schema_constants(schema: dict[str, Any]) -> dict[str, Any]:
    defs = schema.get("$defs", {})
    return {
        "required": list(schema.get("required", [])),
        "track_max": schema["properties"]["tracks"]["maxItems"],
        "keyframe_max": defs["track"]["properties"]["keyframes"]["maxItems"],
        "fps_min": defs["timeline"]["properties"]["fps"]["minimum"],
        "fps_max": defs["timeline"]["properties"]["fps"]["maximum"],
        "plan_id_max": defs["safeIdentifier"]["maxLength"],
        "title_max": schema["properties"]["title"]["maxLength"],
        "description_max": schema["properties"]["description"]["maxLength"],
        "schema_version": schema["properties"]["schema_version"]["const"],
        "mode": schema["properties"]["mode"]["enum"],
        "target_types": _enum(schema, "$defs.track.properties.target_type.enum"),
        "properties": _enum(schema, "$defs.track.properties.property.enum"),
        "interpolations": _enum(schema, "$defs.track.properties.interpolation.enum"),
        "preview_formats": _enum(schema, "$defs.previewOutput.properties.format.enum"),
        "units": _enum(schema, "$defs.scene.properties.units.enum"),
    }


def _require_object(value: object, path: str, issues: list[ValidationIssue]) -> dict[str, Any] | None:
    if not isinstance(value, dict):
        issues.append(_issue("type_mismatch", path, "value must be an object"))
        return None
    return value


def _check_unknown_fields(value: dict[str, Any], allowed: set[str], path: str, issues: list[ValidationIssue]) -> None:
    for key in sorted(set(value) - allowed):
        issues.append(_issue("unknown_field", f"{path}.{key}", "field is not allowed"))


def _check_required(value: dict[str, Any], required: list[str], path: str, issues: list[ValidationIssue]) -> None:
    for key in required:
        if key not in value:
            issues.append(_issue("missing_required_field", f"{path}.{key}", "field is required"))


def _check_string(value: object, path: str, issues: list[ValidationIssue], *, min_length: int = 0, max_length: int | None = None) -> str | None:
    if not isinstance(value, str):
        issues.append(_issue("type_mismatch", path, "value must be a string"))
        return None
    if len(value) < min_length:
        issues.append(_issue("string_too_short", path, f"value must be at least {min_length} character(s)"))
    if max_length is not None and len(value) > max_length:
        issues.append(_issue("string_too_long", path, f"value must be at most {max_length} character(s)"))
    return value


def _check_const(value: object, expected: object, path: str, issues: list[ValidationIssue]) -> None:
    if value != expected or type(value) is not type(expected):  # noqa: E721 - exact bool/int distinction is intentional.
        issues.append(_issue("const_mismatch", path, f"value must be {json.dumps(expected)}"))


def _check_enum(value: object, allowed: list[str], path: str, issues: list[ValidationIssue]) -> None:
    if not isinstance(value, str) or value not in allowed:
        issues.append(_issue("enum_mismatch", path, f"value must be one of: {', '.join(allowed)}"))


def _check_int(value: object, path: str, issues: list[ValidationIssue], *, minimum: int | None = None, maximum: int | None = None) -> int | None:
    if not _is_integer(value):
        issues.append(_issue("type_mismatch", path, "value must be an integer"))
        return None
    if minimum is not None and value < minimum:
        issues.append(_issue("number_below_minimum", path, f"value must be >= {minimum}"))
    if maximum is not None and value > maximum:
        issues.append(_issue("number_above_maximum", path, f"value must be <= {maximum}"))
    return value


def _check_number(value: object, path: str, issues: list[ValidationIssue], *, exclusive_minimum: float | None = None, maximum: float | None = None) -> float | None:
    if not _is_number(value):
        issues.append(_issue("type_mismatch", path, "value must be a finite number"))
        return None
    number = float(value)
    if exclusive_minimum is not None and number <= exclusive_minimum:
        issues.append(_issue("number_below_minimum", path, f"value must be > {exclusive_minimum}"))
    if maximum is not None and number > maximum:
        issues.append(_issue("number_above_maximum", path, f"value must be <= {maximum}"))
    return number


def _check_safe_identifier(value: object, path: str, issues: list[ValidationIssue], *, max_length: int = 160, lowercase_only: bool = False) -> str | None:
    text = _check_string(value, path, issues, min_length=1, max_length=max_length)
    if text is None:
        return None
    if text.startswith("."):
        issues.append(_issue("unsafe_identifier", path, "identifier must not start with a dot"))
    if re.match(r"^[A-Za-z]:", text):
        issues.append(_issue("unsafe_identifier", path, "identifier must not use a drive prefix"))
    if text.startswith("//"):
        issues.append(_issue("unsafe_identifier", path, "identifier must not use a UNC prefix"))
    for marker in BLOCKED_ID_MARKERS:
        if marker in text:
            issues.append(_issue("unsafe_identifier", path, "identifier must not contain path, URL, runtime, repo, or model markers"))
            break
    pattern = r"^[a-z0-9][a-z0-9_-]*$" if lowercase_only else r"^[A-Za-z0-9][A-Za-z0-9 _:-]*$"
    if not re.fullmatch(pattern, text):
        issues.append(_issue("unsafe_identifier", path, "identifier contains unsupported characters"))
    return text


def _check_vector3(value: object, path: str, issues: list[ValidationIssue]) -> None:
    if not isinstance(value, list):
        issues.append(_issue("type_mismatch", path, "value must be an array"))
        return
    if len(value) != 3:
        issues.append(_issue("vector_length_invalid", path, "vector must contain exactly 3 values"))
    for index, item in enumerate(value):
        if not _is_number(item):
            issues.append(_issue("type_mismatch", f"{path}[{index}]", "vector value must be a finite number"))


def _is_safe_runtime_relative_path(value: str, *, prefix: str, extension: str) -> bool:
    if value.startswith("/") or "\\" in value or "://" in value or re.match(r"^[A-Za-z]:", value):
        return False
    if any(marker in value for marker in BLOCKED_PATH_MARKERS):
        return False
    path = Path(value)
    if path.is_absolute():
        return False
    if any(part in {"", ".", ".."} for part in path.parts):
        return False
    if path.as_posix() != value:
        return False
    if path.as_posix() != Path(path.as_posix()).as_posix():
        return False
    return value.startswith(prefix) and value.endswith(extension)


def _check_runtime_path(value: object, path: str, issues: list[ValidationIssue], *, prefix: str, extension: str) -> str | None:
    text = _check_string(value, path, issues, min_length=1, max_length=240)
    if text is None:
        return None
    if not _is_safe_runtime_relative_path(text, prefix=prefix, extension=extension):
        issues.append(_issue("unsafe_runtime_relative_path", path, f"path must stay under {prefix} and use {extension}"))
    return text


def validate_animation_plan_structure(plan: dict[str, Any], schema: dict[str, Any] | None = None) -> list[ValidationIssue]:
    schema = schema or load_animation_plan_schema()
    constants = _schema_constants(schema)
    issues: list[ValidationIssue] = []

    root_allowed = set(constants["required"])
    _check_unknown_fields(plan, root_allowed, "$", issues)
    _check_required(plan, constants["required"], "$", issues)
    _check_const(plan.get("schema_version"), constants["schema_version"], "$.schema_version", issues)
    _check_safe_identifier(plan.get("plan_id"), "$.plan_id", issues, max_length=constants["plan_id_max"], lowercase_only=True)
    _check_string(plan.get("title"), "$.title", issues, min_length=1, max_length=constants["title_max"])
    _check_string(plan.get("description"), "$.description", issues, max_length=constants["description_max"])
    _check_enum(plan.get("mode"), constants["mode"], "$.mode", issues)
    _check_const(plan.get("visual_reference_only"), True, "$.visual_reference_only", issues)
    _check_const(plan.get("structural_certification"), False, "$.structural_certification", issues)
    _check_const(plan.get("operator_review_required"), True, "$.operator_review_required", issues)

    timeline = _require_object(plan.get("timeline"), "$.timeline", issues)
    if timeline is not None:
        _check_unknown_fields(timeline, {"fps", "start_frame", "end_frame", "duration_seconds"}, "$.timeline", issues)
        _check_required(timeline, ["fps", "start_frame", "end_frame", "duration_seconds"], "$.timeline", issues)
        _check_int(timeline.get("fps"), "$.timeline.fps", issues, minimum=constants["fps_min"], maximum=constants["fps_max"])
        _check_int(timeline.get("start_frame"), "$.timeline.start_frame", issues, minimum=0)
        _check_int(timeline.get("end_frame"), "$.timeline.end_frame", issues, minimum=1)
        _check_number(timeline.get("duration_seconds"), "$.timeline.duration_seconds", issues, exclusive_minimum=0, maximum=86400)

    scene = _require_object(plan.get("scene"), "$.scene", issues)
    if scene is not None:
        _check_unknown_fields(scene, {"source_scene", "units"}, "$.scene", issues)
        _check_required(scene, ["source_scene", "units"], "$.scene", issues)
        _check_enum(scene.get("units"), constants["units"], "$.scene.units", issues)
        source_scene = _require_object(scene.get("source_scene"), "$.scene.source_scene", issues)
        if source_scene is not None:
            _check_unknown_fields(source_scene, {"type", "reference_id"}, "$.scene.source_scene", issues)
            _check_required(source_scene, ["type", "reference_id"], "$.scene.source_scene", issues)
            _check_enum(source_scene.get("type"), ["existing_runtime_3d_asset"], "$.scene.source_scene.type", issues)
            _check_safe_identifier(source_scene.get("reference_id"), "$.scene.source_scene.reference_id", issues)

    tracks = plan.get("tracks")
    if not isinstance(tracks, list):
        issues.append(_issue("type_mismatch", "$.tracks", "value must be an array"))
    else:
        if len(tracks) < 1:
            issues.append(_issue("array_too_short", "$.tracks", "tracks must contain at least 1 item"))
        if len(tracks) > constants["track_max"]:
            issues.append(_issue("array_too_long", "$.tracks", f"tracks must contain at most {constants['track_max']} items"))
        for track_index, track_value in enumerate(tracks):
            track_path = f"$.tracks[{track_index}]"
            track = _require_object(track_value, track_path, issues)
            if track is None:
                continue
            _check_unknown_fields(track, {"track_id", "target_type", "target_id", "property", "interpolation", "keyframes"}, track_path, issues)
            _check_required(track, ["track_id", "target_type", "target_id", "property", "interpolation", "keyframes"], track_path, issues)
            _check_safe_identifier(track.get("track_id"), f"{track_path}.track_id", issues, max_length=constants["plan_id_max"], lowercase_only=True)
            _check_enum(track.get("target_type"), constants["target_types"], f"{track_path}.target_type", issues)
            _check_safe_identifier(track.get("target_id"), f"{track_path}.target_id", issues)
            _check_enum(track.get("property"), constants["properties"], f"{track_path}.property", issues)
            _check_enum(track.get("interpolation"), constants["interpolations"], f"{track_path}.interpolation", issues)
            keyframes = track.get("keyframes")
            if not isinstance(keyframes, list):
                issues.append(_issue("type_mismatch", f"{track_path}.keyframes", "value must be an array"))
                continue
            if len(keyframes) < 1:
                issues.append(_issue("array_too_short", f"{track_path}.keyframes", "keyframes must contain at least 1 item"))
            if len(keyframes) > constants["keyframe_max"]:
                issues.append(_issue("array_too_long", f"{track_path}.keyframes", f"keyframes must contain at most {constants['keyframe_max']} items"))
            for keyframe_index, keyframe_value in enumerate(keyframes):
                keyframe_path = f"{track_path}.keyframes[{keyframe_index}]"
                keyframe = _require_object(keyframe_value, keyframe_path, issues)
                if keyframe is None:
                    continue
                _check_unknown_fields(keyframe, {"frame", "location", "rotation_euler", "scale", "visibility"}, keyframe_path, issues)
                _check_required(keyframe, ["frame"], keyframe_path, issues)
                _check_int(keyframe.get("frame"), f"{keyframe_path}.frame", issues, minimum=0)
                value_fields = [field for field in ("location", "rotation_euler", "scale", "visibility") if field in keyframe]
                if not value_fields:
                    issues.append(_issue("missing_required_field", keyframe_path, "keyframe must contain at least one animated value"))
                for field in ("location", "rotation_euler", "scale"):
                    if field in keyframe:
                        _check_vector3(keyframe[field], f"{keyframe_path}.{field}", issues)
                if "visibility" in keyframe and not _is_bool(keyframe["visibility"]):
                    issues.append(_issue("type_mismatch", f"{keyframe_path}.visibility", "value must be a boolean"))

    outputs = _require_object(plan.get("outputs"), "$.outputs", issues)
    if outputs is not None:
        _check_unknown_fields(outputs, {"preview", "metadata"}, "$.outputs", issues)
        _check_required(outputs, ["preview", "metadata"], "$.outputs", issues)
        preview = _require_object(outputs.get("preview"), "$.outputs.preview", issues)
        if preview is not None:
            _check_unknown_fields(preview, {"enabled", "format", "relative_runtime_path"}, "$.outputs.preview", issues)
            _check_required(preview, ["enabled", "format", "relative_runtime_path"], "$.outputs.preview", issues)
            _check_const(preview.get("enabled"), False, "$.outputs.preview.enabled", issues)
            _check_enum(preview.get("format"), constants["preview_formats"], "$.outputs.preview.format", issues)
            _check_runtime_path(preview.get("relative_runtime_path"), "$.outputs.preview.relative_runtime_path", issues, prefix="media/animation/previews/", extension=f".{preview.get('format')}" if isinstance(preview.get("format"), str) else ".mp4")
        metadata = _require_object(outputs.get("metadata"), "$.outputs.metadata", issues)
        if metadata is not None:
            _check_unknown_fields(metadata, {"relative_runtime_path"}, "$.outputs.metadata", issues)
            _check_required(metadata, ["relative_runtime_path"], "$.outputs.metadata", issues)
            _check_runtime_path(metadata.get("relative_runtime_path"), "$.outputs.metadata.relative_runtime_path", issues, prefix="media/animation/metadata/", extension=".json")

    safety = _require_object(plan.get("safety"), "$.safety", issues)
    if safety is not None:
        allowed_safety = {"real_animation_enabled", "blender_execution_enabled", "preview_render_enabled", "source_assets_modified", "runtime_write_planned"}
        _check_unknown_fields(safety, allowed_safety, "$.safety", issues)
        _check_required(safety, sorted(allowed_safety), "$.safety", issues)
        for key in sorted(allowed_safety):
            _check_const(safety.get(key), False, f"$.safety.{key}", issues)

    return _sort_issues(issues)


def validate_animation_plan_semantics(plan: dict[str, Any]) -> list[ValidationIssue]:
    issues: list[ValidationIssue] = []
    timeline = _mapping(plan.get("timeline"))
    tracks = plan.get("tracks")
    if timeline is None or not isinstance(tracks, list):
        return []

    fps = timeline.get("fps")
    start_frame = timeline.get("start_frame")
    end_frame = timeline.get("end_frame")
    duration_seconds = timeline.get("duration_seconds")
    timeline_numbers_valid = _is_integer(fps) and _is_integer(start_frame) and _is_integer(end_frame) and _is_number(duration_seconds)

    if _is_integer(start_frame) and _is_integer(end_frame) and end_frame <= start_frame:
        issues.append(_issue("timeline_invalid_range", "$.timeline.end_frame", "end_frame must be greater than start_frame"))
    if timeline_numbers_valid and end_frame > start_frame and fps > 0:
        expected = (end_frame - start_frame + 1) / fps
        tolerance = max(0.001, 0.5 / fps)
        if abs(float(duration_seconds) - expected) > tolerance:
            issues.append(_issue("timeline_duration_mismatch", "$.timeline.duration_seconds", "duration_seconds must match frame range and fps"))

    seen_tracks: dict[str, int] = {}
    for track_index, track in enumerate(tracks):
        if not isinstance(track, dict):
            continue
        track_path = f"$.tracks[{track_index}]"
        track_id = track.get("track_id")
        if isinstance(track_id, str):
            if track_id in seen_tracks:
                issues.append(_issue("duplicate_track_id", f"{track_path}.track_id", "track_id must be unique"))
            else:
                seen_tracks[track_id] = track_index

        prop = track.get("property")
        keyframes = track.get("keyframes")
        if not isinstance(keyframes, list):
            continue
        previous_frame: int | None = None
        seen_frames: set[int] = set()
        for keyframe_index, keyframe in enumerate(keyframes):
            if not isinstance(keyframe, dict):
                continue
            keyframe_path = f"{track_path}.keyframes[{keyframe_index}]"
            frame = keyframe.get("frame")
            if _is_integer(frame):
                if timeline_numbers_valid and (frame < start_frame or frame > end_frame):
                    issues.append(_issue("keyframe_outside_timeline", f"{keyframe_path}.frame", "keyframe frame must be inside the timeline range"))
                if frame in seen_frames:
                    issues.append(_issue("duplicate_keyframe_frame", f"{keyframe_path}.frame", "keyframe frame must be unique within the track"))
                seen_frames.add(frame)
                if previous_frame is not None and frame <= previous_frame:
                    issues.append(_issue("keyframes_not_strictly_increasing", f"{keyframe_path}.frame", "keyframe frames must be strictly increasing"))
                previous_frame = frame

            value_fields = {field for field in ("location", "rotation_euler", "scale", "visibility") if field in keyframe}
            if prop == "transform":
                if not value_fields.intersection({"location", "rotation_euler", "scale"}):
                    issues.append(_issue("keyframe_property_mismatch", keyframe_path, "transform keyframes require location, rotation_euler, or scale"))
                if "visibility" in value_fields:
                    issues.append(_issue("keyframe_property_mismatch", f"{keyframe_path}.visibility", "transform keyframes must not contain visibility"))
            elif prop in {"location", "rotation_euler", "scale"}:
                if prop not in value_fields:
                    issues.append(_issue("keyframe_property_mismatch", keyframe_path, f"{prop} keyframes require {prop}"))
                unrelated = value_fields - {prop}
                if unrelated:
                    issues.append(_issue("keyframe_property_mismatch", keyframe_path, f"{prop} keyframes must not contain unrelated animated values"))
            elif prop == "visibility":
                if "visibility" not in value_fields:
                    issues.append(_issue("keyframe_property_mismatch", keyframe_path, "visibility keyframes require visibility"))
                unrelated = value_fields - {"visibility"}
                if unrelated:
                    issues.append(_issue("keyframe_property_mismatch", keyframe_path, "visibility keyframes must not contain transform values"))

    outputs = _mapping(plan.get("outputs"))
    preview = _mapping(outputs.get("preview")) if outputs else None
    if preview is not None:
        preview_path = preview.get("relative_runtime_path")
        preview_format = preview.get("format")
        if isinstance(preview_path, str) and isinstance(preview_format, str):
            expected_suffix = f".{preview_format}"
            if not preview_path.endswith(expected_suffix):
                issues.append(_issue("preview_format_extension_mismatch", "$.outputs.preview.relative_runtime_path", "preview path extension must match outputs.preview.format"))

    return _sort_issues(issues)


def _build_summary(plan: dict[str, Any] | None) -> dict[str, Any]:
    summary = dict(EMPTY_SUMMARY)
    if not isinstance(plan, dict):
        return summary
    timeline = _mapping(plan.get("timeline")) or {}
    tracks = plan.get("tracks")
    tracks_list = tracks if isinstance(tracks, list) else []
    summary.update(
        {
            "plan_id": plan.get("plan_id") if isinstance(plan.get("plan_id"), str) else None,
            "fps": timeline.get("fps") if _is_integer(timeline.get("fps")) else None,
            "start_frame": timeline.get("start_frame") if _is_integer(timeline.get("start_frame")) else None,
            "end_frame": timeline.get("end_frame") if _is_integer(timeline.get("end_frame")) else None,
            "duration_seconds": timeline.get("duration_seconds") if _is_number(timeline.get("duration_seconds")) else None,
            "track_count": len(tracks_list),
            "keyframe_count": sum(len(track.get("keyframes", [])) for track in tracks_list if isinstance(track, dict) and isinstance(track.get("keyframes"), list)),
            "target_types": sorted({track.get("target_type") for track in tracks_list if isinstance(track, dict) and isinstance(track.get("target_type"), str)}),
            "properties": sorted({track.get("property") for track in tracks_list if isinstance(track, dict) and isinstance(track.get("property"), str)}),
            "interpolations": sorted({track.get("interpolation") for track in tracks_list if isinstance(track, dict) and isinstance(track.get("interpolation"), str)}),
        }
    )
    return summary


def build_animation_plan_validation_report(plan_path: str, plan: dict[str, Any] | None, issues: list[ValidationIssue]) -> dict[str, Any]:
    sorted_issues = _sort_issues(issues)
    errors = [issue.as_report_item() for issue in sorted_issues if issue.severity == "error"]
    warnings = [issue.as_report_item() for issue in sorted_issues if issue.severity == "warning"]
    return {
        "schema_version": "1.0",
        "report_type": "animation_plan_validation",
        "plan_path": _sanitize_plan_path(plan_path),
        "valid": len(errors) == 0,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "summary": _build_summary(plan),
        "safety_flags": dict(SAFETY_FLAGS),
    }


def validate_animation_plan(plan_path: str) -> tuple[dict[str, Any], int]:
    try:
        schema = load_animation_plan_schema()
    except ValueError:
        report = build_animation_plan_validation_report(plan_path, None, [_issue("schema_load_failed", "$.schema", "canonical schema could not be loaded")])
        return report, 2

    plan, display_path, load_issues = load_animation_plan(plan_path)
    if load_issues or plan is None:
        report = build_animation_plan_validation_report(display_path, plan, load_issues)
        return report, 2

    issues = validate_animation_plan_structure(plan, schema)
    if not issues:
        issues.extend(validate_animation_plan_semantics(plan))
    report = build_animation_plan_validation_report(display_path, plan, issues)
    return report, 0 if report["valid"] else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Validate a source-only animation plan.")
    parser.add_argument("--plan", required=True, help="Plan path under configs/animation or /tmp.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON validation report.")
    return parser


def run(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    report, exit_code = validate_animation_plan(args.plan)
    indent = 2 if args.pretty else None
    print(json.dumps(report, indent=indent, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(run())
