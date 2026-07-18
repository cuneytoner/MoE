#!/usr/bin/env python3
"""Read-only animation artifact verifier for M36.12."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

from animation_metadata_validator import (  # noqa: E402
    load_animation_metadata_schema,
    validate_animation_metadata_provenance,
    validate_animation_metadata_semantics,
    validate_animation_metadata_structure,
)
from animation_preview_renderer import validate_preview_render_operation_plan  # noqa: E402


REPO_ROOT = Path(__file__).resolve().parents[3]
CONFIG_ROOT = REPO_ROOT / "configs" / "animation"
RUNTIME_ROOT = Path("/home/cuneyt/MoE/runtime")
ANIMATION_ROOT_REL = Path("media/animation")
METADATA_ROOT_REL = ANIMATION_ROOT_REL / "metadata"
PREVIEW_ROOT_REL = ANIMATION_ROOT_REL / "previews"
REPORT_ROOT_REL = ANIMATION_ROOT_REL / "reports"
METADATA_ROOT = RUNTIME_ROOT / METADATA_ROOT_REL
PREVIEW_ROOT = RUNTIME_ROOT / PREVIEW_ROOT_REL
REPORT_ROOT = RUNTIME_ROOT / REPORT_ROOT_REL
MODEL_ROOT = Path("/home/cuneyt/MoE_Models_Backup")
MAX_METADATA_BYTES = 512 * 1024
MAX_PREVIEW_REPORT_BYTES = 1024 * 1024
MAX_FRAME_DIRECTORY_ENTRIES = 64
MAX_PIXEL_BUDGET = 24 * 1920 * 1080
MAX_TOTAL_OUTPUT_BYTES = 536870912
HASH_CHUNK_BYTES = 1024 * 1024
SAFE_ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
HASH_RE = re.compile(r"^[a-f0-9]{64}$")
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
REPORT_TOP_FIELDS = {
    "schema_version",
    "report_type",
    "status",
    "planned",
    "rendered",
    "preview_request_path",
    "adapter_request_path",
    "operation_plan",
    "render_result",
    "errors",
    "warnings",
    "safety_flags",
}
PLAN_ONLY_SAFETY = {
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
}
RENDERED_SAFETY = {
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
}


@dataclass(frozen=True)
class ArtifactVerificationIssue:
    code: str
    path: str
    message: str
    severity: str = "error"

    def as_report_item(self) -> dict[str, str]:
        return {
            "code": self.code,
            "path": self.path,
            "message": self.message,
            "severity": self.severity,
        }


@dataclass(frozen=True)
class LoadedJson:
    payload: dict[str, Any] | None
    display_path: str
    path: Path | None
    location: str
    issues: tuple[ArtifactVerificationIssue, ...]
    exit_code: int


def _issue(code: str, path: str, message: str, severity: str = "error") -> ArtifactVerificationIssue:
    return ArtifactVerificationIssue(code=code, path=path, message=message, severity=severity)


def _sort_issues(issues: list[ArtifactVerificationIssue] | tuple[ArtifactVerificationIssue, ...]) -> tuple[ArtifactVerificationIssue, ...]:
    return tuple(sorted(issues, key=lambda item: (item.path, item.code, item.message)))


def _issue_items(issues: list[ArtifactVerificationIssue] | tuple[ArtifactVerificationIssue, ...]) -> list[dict[str, str]]:
    return [issue.as_report_item() for issue in _sort_issues(issues)]


def _is_int(value: object) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _safe_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)


def _is_relative_to(path: Path, root: Path) -> bool:
    try:
        path.resolve(strict=False).relative_to(root.resolve(strict=False))
        return True
    except ValueError:
        return False


def _has_symlink_parent(path: Path, stop_at: Path) -> bool:
    current = path
    stop = stop_at.resolve(strict=False)
    while True:
        if current.exists() and current.is_symlink():
            return True
        if current.resolve(strict=False) == stop or current.parent == current:
            return False
        current = current.parent


def _display_runtime_path(path: Path, runtime_root: Path = RUNTIME_ROOT) -> str:
    try:
        return path.resolve(strict=False).relative_to(runtime_root.resolve(strict=False)).as_posix()
    except ValueError:
        return path.name


def _display_input_path(path: Path, *, runtime_root: Path = RUNTIME_ROOT) -> str:
    raw = path.as_posix()
    if raw.startswith("configs/animation/"):
        return raw
    if path.is_absolute() and path.parent == Path("/tmp"):
        return f"/tmp/{path.name}"
    if _is_relative_to(path, runtime_root):
        return _display_runtime_path(path, runtime_root)
    return path.name or "invalid-input.json"


def _load_json_file(path: Path, display_path: str, max_bytes: int, field_path: str) -> tuple[dict[str, Any] | None, tuple[ArtifactVerificationIssue, ...], int]:
    try:
        stat_result = path.lstat()
    except OSError:
        return None, (_issue("input_file_unreadable", field_path, "input file could not be inspected"),), 2
    if path.is_symlink():
        return None, (_issue("input_symlink_rejected", field_path, "input symlinks are rejected"),), 2
    if not path.is_file():
        return None, (_issue("input_not_regular_file", field_path, "input must be a regular file"),), 2
    if stat_result.st_size > max_bytes:
        return None, (_issue("input_too_large", field_path, "input exceeds maximum allowed size"),), 2
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None, (_issue("input_not_utf8", field_path, "input must be valid UTF-8"),), 2
    except OSError:
        return None, (_issue("input_file_unreadable", field_path, "input file could not be read"),), 2
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        return None, (_issue("malformed_json", field_path, "JSON is malformed"),), 2
    if not isinstance(payload, dict):
        return None, (_issue("root_not_object", "$", "JSON root must be an object"),), 1
    return payload, tuple(), 0


def _resolve_metadata_path(raw_path: str, *, runtime_root: Path = RUNTIME_ROOT) -> tuple[Path | None, str, str, ArtifactVerificationIssue | None]:
    raw = str(raw_path)
    path = Path(raw)
    display_path = _display_input_path(path, runtime_root=runtime_root)
    if ".." in path.parts:
        return None, display_path, "unknown", _issue("unsafe_input_path", "$.metadata_path", "metadata path must not contain traversal")
    if path.suffix.lower() != ".json":
        return None, display_path, "unknown", _issue("unsupported_input_extension", "$.metadata_path", "metadata path must use .json")
    if raw.startswith("configs/animation/") and len(path.parts) == 3:
        return REPO_ROOT / path, raw, "config", None
    if path.is_absolute() and path.parent == Path("/tmp"):
        return path, f"/tmp/{path.name}", "tmp", None
    metadata_root = runtime_root / METADATA_ROOT_REL
    if path.is_absolute() and path.parent.resolve(strict=False) == metadata_root.resolve(strict=False):
        return path, _display_runtime_path(path, runtime_root), "runtime", None
    return None, display_path, "unknown", _issue("input_path_not_allowlisted", "$.metadata_path", "metadata path must be configs/animation/<file>.json, /tmp/<file>.json, or a direct runtime metadata JSON")


def load_animation_metadata_for_verification(metadata_path: str, *, runtime_root: Path = RUNTIME_ROOT) -> LoadedJson:
    candidate, display_path, location, issue = _resolve_metadata_path(metadata_path, runtime_root=runtime_root)
    if issue is not None or candidate is None:
        return LoadedJson(None, display_path, candidate, location, tuple([issue] if issue else []), 2)
    payload, issues, exit_code = _load_json_file(candidate, display_path, MAX_METADATA_BYTES, "$.metadata_path")
    return LoadedJson(payload, display_path, candidate, location, issues, exit_code)


def _resolve_preview_report_path(raw_path: str, *, runtime_root: Path = RUNTIME_ROOT) -> tuple[Path | None, str, str, ArtifactVerificationIssue | None]:
    path = Path(str(raw_path))
    display_path = _display_input_path(path, runtime_root=runtime_root)
    if ".." in path.parts:
        return None, display_path, "unknown", _issue("unsafe_input_path", "$.preview_report_path", "preview report path must not contain traversal")
    if path.suffix.lower() != ".json":
        return None, display_path, "unknown", _issue("unsupported_input_extension", "$.preview_report_path", "preview report must use .json")
    if path.is_absolute() and path.parent == Path("/tmp"):
        return path, f"/tmp/{path.name}", "tmp", None
    report_root = runtime_root / REPORT_ROOT_REL
    if path.is_absolute() and path.parent.resolve(strict=False) == report_root.resolve(strict=False):
        return path, _display_runtime_path(path, runtime_root), "runtime", None
    return None, display_path, "unknown", _issue("input_path_not_allowlisted", "$.preview_report_path", "preview report path must be /tmp/<file>.json or a direct runtime report JSON")


def load_preview_renderer_report(preview_report_path: str, *, runtime_root: Path = RUNTIME_ROOT) -> LoadedJson:
    candidate, display_path, location, issue = _resolve_preview_report_path(preview_report_path, runtime_root=runtime_root)
    if issue is not None or candidate is None:
        return LoadedJson(None, display_path, candidate, location, tuple([issue] if issue else []), 2)
    payload, issues, exit_code = _load_json_file(candidate, display_path, MAX_PREVIEW_REPORT_BYTES, "$.preview_report_path")
    return LoadedJson(payload, display_path, candidate, location, issues, exit_code)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(HASH_CHUNK_BYTES)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest()


def _artifact_record(role: str, relative_path: str, media_type: str, path: Path, *, frame: int | None = None) -> dict[str, Any]:
    record: dict[str, Any] = {
        "role": role,
        "relative_path": relative_path,
        "media_type": media_type,
        "size_bytes": path.stat().st_size,
        "sha256": sha256_file(path),
        "verified": True,
    }
    if frame is not None:
        record["frame"] = frame
    return record


def _validate_metadata_payload(metadata: dict[str, Any] | None, *, adapter_request_path: str | None = None) -> tuple[bool, tuple[ArtifactVerificationIssue, ...], str | None, int]:
    if metadata is None:
        return False, (_issue("metadata_invalid", "$", "metadata could not be loaded"),), None, 2
    try:
        schema = load_animation_metadata_schema()
    except ValueError:
        return False, (_issue("metadata_invalid", "$.schema", "animation metadata schema could not be loaded"),), None, 2
    converted: list[ArtifactVerificationIssue] = []
    for item in validate_animation_metadata_structure(metadata, schema):
        converted.append(_issue("metadata_invalid", item.path, item.message, item.severity))
    if not [item for item in converted if item.severity == "error"]:
        for item in validate_animation_metadata_semantics(metadata):
            converted.append(_issue("metadata_invalid", item.path, item.message, item.severity))
    adapter_display = None
    provenance_exit = 0
    if adapter_request_path is not None and not [item for item in converted if item.severity == "error"]:
        provenance_issues, adapter_display, provenance_exit = validate_animation_metadata_provenance(metadata, adapter_request_path)
        for item in provenance_issues:
            converted.append(_issue("metadata_provenance_invalid", item.path, item.message, item.severity))
    errors = [item for item in converted if item.severity == "error"]
    if errors:
        return False, _sort_issues(converted), adapter_display, 2 if provenance_exit == 2 else 1
    return True, _sort_issues(converted), adapter_display, 0


def verify_runtime_metadata_file(loaded: LoadedJson, metadata: dict[str, Any], *, runtime_root: Path = RUNTIME_ROOT) -> tuple[list[dict[str, Any]], tuple[ArtifactVerificationIssue, ...]]:
    if loaded.location != "runtime" or loaded.path is None:
        return [], tuple()
    issues: list[ArtifactVerificationIssue] = []
    metadata_root = runtime_root / METADATA_ROOT_REL
    if loaded.path.is_symlink():
        issues.append(_issue("metadata_file_symlink", loaded.display_path, "metadata file must not be a symlink"))
    if not _is_relative_to(loaded.path, metadata_root):
        issues.append(_issue("metadata_file_outside_runtime_root", loaded.display_path, "metadata file must stay under metadata root"))
    if not loaded.path.is_file():
        issues.append(_issue("metadata_file_not_regular", loaded.display_path, "metadata file must be regular"))
    expected_rel = metadata.get("output_files", {}).get("metadata") if isinstance(metadata.get("output_files"), dict) else None
    expected_abs = runtime_root / expected_rel if isinstance(expected_rel, str) else None
    if expected_abs is None or expected_abs.resolve(strict=False) != loaded.path.resolve(strict=False):
        issues.append(_issue("metadata_runtime_path_mismatch", "$.output_files.metadata", "metadata output reference must match the runtime metadata file"))
    if issues:
        return [], _sort_issues(issues)
    return [_artifact_record("metadata", _display_runtime_path(loaded.path, runtime_root), "application/json", loaded.path)], tuple()


def _check_safety_flags(flags: Any, expected: dict[str, bool], prefix: str) -> list[ArtifactVerificationIssue]:
    issues: list[ArtifactVerificationIssue] = []
    if not isinstance(flags, dict):
        return [_issue("preview_report_invalid", prefix, "safety_flags must be an object")]
    for key, value in expected.items():
        if flags.get(key) is not value:
            issues.append(_issue("preview_report_invalid", f"{prefix}.{key}", f"safety flag {key} must be {value}"))
    return issues


def _validate_frames(frames: Any, path: str, start_frame: int | None, end_frame: int | None) -> tuple[list[int], list[ArtifactVerificationIssue]]:
    issues: list[ArtifactVerificationIssue] = []
    if not isinstance(frames, list) or not frames:
        return [], [_issue("preview_result_invalid", path, "frames must be a non-empty array")]
    parsed: list[int] = []
    for index, frame in enumerate(frames):
        if not _is_int(frame):
            issues.append(_issue("preview_result_invalid", f"{path}[{index}]", "frame must be an integer"))
            continue
        parsed.append(frame)
    if len(parsed) != len(set(parsed)):
        issues.append(_issue("preview_result_invalid", path, "frames must not contain duplicates"))
    if any(left >= right for left, right in zip(parsed, parsed[1:])):
        issues.append(_issue("preview_result_invalid", path, "frames must be strictly increasing"))
    if start_frame is not None and end_frame is not None:
        for frame in parsed:
            if frame < start_frame or frame > end_frame:
                issues.append(_issue("preview_result_invalid", path, "frames must stay inside metadata timeline"))
                break
    return parsed, issues


def _validate_preview_relative_directory(value: Any, preview_id: str | None, *, runtime_root: Path) -> tuple[Path | None, str | None, list[ArtifactVerificationIssue]]:
    issues: list[ArtifactVerificationIssue] = []
    if not isinstance(value, str):
        return None, None, [_issue("preview_output_path_invalid", "$.render_result.relative_output_directory", "relative output directory must be a string")]
    if value.startswith("/") or "\\" in value or "://" in value or re.match(r"^[A-Za-z]:", value):
        issues.append(_issue("preview_output_path_invalid", "$.render_result.relative_output_directory", "output directory must be POSIX relative"))
    if any(marker in value for marker in ("/home/", "/mnt/", "/media/", "/workspace/", "/app/", "MoE_Models_Backup", "DiskD/Projects/MoE/codebase")):
        issues.append(_issue("preview_output_path_invalid", "$.render_result.relative_output_directory", "output directory contains blocked path markers"))
    rel = Path(value)
    if any(part in {"", ".", ".."} for part in rel.parts) or rel.as_posix() != value:
        issues.append(_issue("preview_output_path_invalid", "$.render_result.relative_output_directory", "output directory contains unsafe path segments"))
    expected = f"media/animation/previews/{preview_id}/frames" if preview_id else None
    if expected is None or value != expected:
        issues.append(_issue("preview_output_path_invalid", "$.render_result.relative_output_directory", "output directory must be media/animation/previews/<preview-id>/frames"))
    final_dir = runtime_root / rel
    preview_root = runtime_root / PREVIEW_ROOT_REL
    if not _is_relative_to(final_dir, preview_root):
        issues.append(_issue("unsafe_runtime_path", "$.render_result.relative_output_directory", "output directory must stay under preview root"))
    return final_dir, value, issues


def _read_png_dimensions(path: Path) -> tuple[int | None, int | None, ArtifactVerificationIssue | None]:
    with path.open("rb") as handle:
        header = handle.read(33)
    if len(header) < 8 or header[:8] != PNG_SIGNATURE:
        return None, None, _issue("invalid_png_signature", path.name, "preview frame must start with PNG signature")
    if len(header) < 33:
        return None, None, _issue("missing_png_ihdr", path.name, "preview frame is missing IHDR header")
    length = int.from_bytes(header[8:12], "big")
    chunk_type = header[12:16]
    if length != 13 or chunk_type != b"IHDR":
        return None, None, _issue("missing_png_ihdr", path.name, "preview frame first chunk must be IHDR length 13")
    width = int.from_bytes(header[16:20], "big")
    height = int.from_bytes(header[20:24], "big")
    if width <= 0 or height <= 0:
        return width, height, _issue("invalid_png_dimensions", path.name, "PNG dimensions must be positive")
    return width, height, None


def verify_preview_frame_set(render_result: dict[str, Any], *, metadata: dict[str, Any], runtime_root: Path = RUNTIME_ROOT) -> tuple[list[dict[str, Any]], tuple[ArtifactVerificationIssue, ...], int]:
    issues: list[ArtifactVerificationIssue] = []
    artifacts: list[dict[str, Any]] = []
    preview_id = render_result.get("preview_id") if isinstance(render_result.get("preview_id"), str) else None
    final_dir, rel_dir, path_issues = _validate_preview_relative_directory(render_result.get("relative_output_directory"), preview_id, runtime_root=runtime_root)
    issues.extend(path_issues)
    if final_dir is None or rel_dir is None:
        return artifacts, _sort_issues(issues), 0
    preview_id_dir = final_dir.parent
    if preview_id_dir.exists() and preview_id_dir.is_symlink():
        issues.append(_issue("preview_directory_symlink", _display_runtime_path(preview_id_dir, runtime_root), "preview-id directory must not be a symlink"))
    if final_dir.exists() and final_dir.is_symlink():
        issues.append(_issue("preview_directory_symlink", rel_dir, "frames directory must not be a symlink"))
    if _has_symlink_parent(final_dir, runtime_root / PREVIEW_ROOT_REL):
        issues.append(_issue("preview_directory_symlink", rel_dir, "frames directory parents must not be symlinks"))
    if not final_dir.exists():
        issues.append(_issue("preview_directory_missing", rel_dir, "frames directory is missing"))
        return artifacts, _sort_issues(issues), 0
    if not final_dir.is_dir():
        issues.append(_issue("preview_output_path_invalid", rel_dir, "frames path must be a directory"))
        return artifacts, _sort_issues(issues), 0

    children = sorted(final_dir.iterdir(), key=lambda item: item.name)
    if len(children) > MAX_FRAME_DIRECTORY_ENTRIES:
        issues.append(_issue("preview_directory_entry_limit_exceeded", rel_dir, "frames directory contains more than 64 entries"))

    timeline = metadata.get("timeline") if isinstance(metadata.get("timeline"), dict) else {}
    frames, frame_issues = _validate_frames(render_result.get("frames"), "$.render_result.frames", timeline.get("start_frame"), timeline.get("end_frame"))
    issues.extend(frame_issues)
    width = render_result.get("width")
    height = render_result.get("height")
    if not _is_int(width) or not _is_int(height) or width < 64 or width > 1920 or height < 64 or height > 1080:
        issues.append(_issue("preview_result_invalid", "$.render_result.width", "rendered dimensions must stay within allowed bounds"))
    elif len(frames) * width * height > MAX_PIXEL_BUDGET:
        issues.append(_issue("preview_result_invalid", "$.render_result", "preview pixel budget exceeded"))

    expected_names = {f"frame-{frame:06d}.png": frame for frame in frames}
    seen_names: set[str] = set()
    total_bytes = 0
    for child in children:
        child_rel = f"{rel_dir}/{child.name}"
        if child.is_symlink():
            issues.append(_issue("preview_frame_symlink", child_rel, "preview frame artifact must not be a symlink"))
            continue
        if child.is_dir():
            issues.append(_issue("unexpected_preview_artifact", child_rel, "subdirectories are not allowed in frames directory"))
            continue
        if not child.is_file():
            issues.append(_issue("preview_frame_not_regular", child_rel, "preview artifact must be a regular file"))
            continue
        if child.name not in expected_names:
            issues.append(_issue("unexpected_preview_artifact", child_rel, "unexpected artifact found in frames directory"))
            continue
        if child.name in seen_names:
            issues.append(_issue("unexpected_preview_artifact", child_rel, "duplicate frame filename found"))
            continue
        seen_names.add(child.name)
        size = child.stat().st_size
        if size <= 0:
            issues.append(_issue("empty_preview_frame", child_rel, "preview frame must not be empty"))
            continue
        png_width, png_height, png_issue = _read_png_dimensions(child)
        if png_issue is not None:
            issues.append(_issue(png_issue.code, child_rel, png_issue.message))
            continue
        if png_width != width or png_height != height:
            issues.append(_issue("png_dimension_mismatch", child_rel, "PNG IHDR dimensions must match preview report"))
            continue
        total_bytes += size
        artifacts.append(_artifact_record("preview_frame", child_rel, "image/png", child, frame=expected_names[child.name]))
    for name in sorted(set(expected_names) - seen_names):
        issues.append(_issue("missing_preview_frame", f"{rel_dir}/{name}", "expected preview frame is missing"))
    reported_total = render_result.get("total_output_bytes")
    if not _is_int(reported_total) or reported_total <= 0 or total_bytes <= 0 or reported_total != total_bytes:
        issues.append(_issue("total_output_bytes_mismatch", "$.render_result.total_output_bytes", "reported preview bytes must match verified frame bytes"))
    if total_bytes > MAX_TOTAL_OUTPUT_BYTES or (_is_int(reported_total) and reported_total > MAX_TOTAL_OUTPUT_BYTES):
        issues.append(_issue("preview_output_size_limit_exceeded", "$.render_result.total_output_bytes", "preview output exceeds 512 MiB"))
    artifacts.sort(key=lambda item: item.get("frame", -1))
    return artifacts, _sort_issues(issues), total_bytes


def validate_preview_renderer_report(report: dict[str, Any], metadata: dict[str, Any]) -> tuple[str, bool, tuple[ArtifactVerificationIssue, ...]]:
    issues: list[ArtifactVerificationIssue] = []
    if not isinstance(report, dict):
        return "preview_plan", False, (_issue("preview_report_invalid", "$", "preview report must be an object"),)
    unknown = sorted(set(report) - REPORT_TOP_FIELDS)
    for key in unknown:
        issues.append(_issue("preview_report_invalid", f"$.{key}", "field is not allowed in preview report"))
    for key in sorted(REPORT_TOP_FIELDS):
        if key not in report:
            issues.append(_issue("preview_report_invalid", f"$.{key}", "field is required"))
    if report.get("schema_version") != "1.0" or report.get("report_type") != "animation_preview_renderer":
        issues.append(_issue("preview_report_invalid", "$.report_type", "preview report type/schema is invalid"))
    if not isinstance(report.get("errors"), list) or not isinstance(report.get("warnings"), list):
        issues.append(_issue("preview_report_invalid", "$.errors", "errors and warnings must be arrays"))
    operation_plan = report.get("operation_plan")
    if not isinstance(operation_plan, dict):
        issues.append(_issue("preview_operation_plan_invalid", "$.operation_plan", "operation_plan must be an object"))
    else:
        for item in validate_preview_render_operation_plan(operation_plan):
            issues.append(_issue("preview_operation_plan_invalid", item.path, item.message))
        if operation_plan.get("source_kind") != metadata.get("source_kind"):
            issues.append(_issue("preview_metadata_hash_mismatch", "$.operation_plan.source_kind", "preview source kind must match metadata"))
        if operation_plan.get("source_request_sha256") != metadata.get("source_request_sha256"):
            issues.append(_issue("preview_metadata_hash_mismatch", "$.operation_plan.source_request_sha256", "preview source request hash must match metadata"))
        if operation_plan.get("canonical_plan_sha256") != metadata.get("canonical_plan_sha256"):
            issues.append(_issue("preview_metadata_hash_mismatch", "$.operation_plan.canonical_plan_sha256", "preview canonical plan hash must match metadata"))
    status = report.get("status")
    planned = report.get("planned")
    rendered = report.get("rendered")
    render_result = report.get("render_result")
    if status == "planned":
        mode = "preview_plan"
        if planned is not True or rendered is not False or render_result is not None:
            issues.append(_issue("preview_report_invalid", "$.status", "planned preview report fields are inconsistent"))
        issues.extend(_check_safety_flags(report.get("safety_flags"), PLAN_ONLY_SAFETY, "$.safety_flags"))
        return mode, not issues, _sort_issues(issues)
    if status != "rendered":
        issues.append(_issue("preview_report_invalid", "$.status", "preview report status must be planned or rendered"))
        return "preview_plan", False, _sort_issues(issues)
    mode = "preview_artifacts"
    if planned is not True or rendered is not True or not isinstance(render_result, dict):
        issues.append(_issue("preview_report_invalid", "$.render_result", "rendered preview report fields are inconsistent"))
        return mode, False, _sort_issues(issues)
    issues.extend(_check_safety_flags(report.get("safety_flags"), RENDERED_SAFETY, "$.safety_flags"))
    issues.extend(_check_safety_flags(render_result.get("safety_flags"), RENDERED_SAFETY, "$.render_result.safety_flags"))
    expected_result = {
        "schema_version": "1.0",
        "result_type": "animation_preview_render_result",
        "status": "rendered",
        "render_mode": "sampled_frames",
        "engine": "BLENDER_EEVEE_NEXT",
        "format": "PNG",
        "final_output_published": True,
        "partial_output_available": False,
    }
    for key, value in expected_result.items():
        if render_result.get(key) is not value and render_result.get(key) != value:
            issues.append(_issue("preview_result_invalid", f"$.render_result.{key}", f"render result field {key} is invalid"))
    execution = render_result.get("execution")
    if not isinstance(execution, dict):
        issues.append(_issue("preview_result_invalid", "$.render_result.execution", "execution must be an object"))
    else:
        for key, value in {"animation_applied": True, "preview_rendered": True, "video_encoded": False, "blend_file_saved": False}.items():
            if execution.get(key) is not value:
                issues.append(_issue("preview_result_invalid", f"$.render_result.execution.{key}", f"execution flag {key} must be {value}"))
    if isinstance(operation_plan, dict):
        for key in ("preview_id", "frames", "relative_output_directory"):
            if operation_plan.get(key) != render_result.get(key):
                issues.append(_issue("preview_result_invalid", f"$.render_result.{key}", "render result must match operation plan"))
    result_preview_id = render_result.get("preview_id") if isinstance(render_result.get("preview_id"), str) else None
    result_rel_dir = render_result.get("relative_output_directory")
    if not isinstance(result_rel_dir, str):
        issues.append(_issue("preview_output_path_invalid", "$.render_result.relative_output_directory", "render result output directory must be a string"))
    else:
        expected_rel_dir = f"media/animation/previews/{result_preview_id}/frames" if result_preview_id else None
        rel_path = Path(result_rel_dir)
        if (
            expected_rel_dir is None
            or result_rel_dir != expected_rel_dir
            or result_rel_dir.startswith("/")
            or "\\" in result_rel_dir
            or "://" in result_rel_dir
            or re.match(r"^[A-Za-z]:", result_rel_dir)
            or any(part in {"", ".", ".."} for part in rel_path.parts)
            or rel_path.as_posix() != result_rel_dir
            or any(marker in result_rel_dir for marker in ("/home/", "/mnt/", "/media/", "/workspace/", "/app/", "MoE_Models_Backup", "DiskD/Projects/MoE/codebase"))
        ):
            issues.append(_issue("preview_output_path_invalid", "$.render_result.relative_output_directory", "render result output directory must be media/animation/previews/<preview-id>/frames"))
    frames, frame_issues = _validate_frames(render_result.get("frames"), "$.render_result.frames", metadata.get("timeline", {}).get("start_frame") if isinstance(metadata.get("timeline"), dict) else None, metadata.get("timeline", {}).get("end_frame") if isinstance(metadata.get("timeline"), dict) else None)
    issues.extend(frame_issues)
    if render_result.get("frame_count") != len(frames):
        issues.append(_issue("preview_result_invalid", "$.render_result.frame_count", "frame_count must equal frames length"))
    width = render_result.get("width")
    height = render_result.get("height")
    if not _is_int(width) or not _is_int(height) or width < 64 or width > 1920 or height < 64 or height > 1080:
        issues.append(_issue("preview_result_invalid", "$.render_result.width", "width and height must be within bounds"))
    elif len(frames) * width * height > MAX_PIXEL_BUDGET:
        issues.append(_issue("preview_result_invalid", "$.render_result", "preview pixel budget exceeded"))
    return mode, not issues, _sort_issues(issues)


def _mode(adapter_request_path: str | None, preview_report: dict[str, Any] | None, preview_mode: str | None) -> str:
    if preview_report is None:
        return "metadata_provenance" if adapter_request_path else "metadata_only"
    if adapter_request_path and preview_mode == "preview_artifacts":
        return "full"
    return preview_mode or "preview_plan"


def verify_animation_artifact_set(
    metadata_path: str,
    *,
    adapter_request_path: str | None = None,
    preview_report_path: str | None = None,
    runtime_root: Path = RUNTIME_ROOT,
) -> tuple[dict[str, Any], int]:
    metadata_loaded = load_animation_metadata_for_verification(metadata_path, runtime_root=runtime_root)
    issues: list[ArtifactVerificationIssue] = list(metadata_loaded.issues)
    metadata = metadata_loaded.payload
    metadata_valid = False
    adapter_display = None
    if not issues and metadata is not None:
        metadata_valid, metadata_issues, adapter_display, _ = _validate_metadata_payload(metadata, adapter_request_path=adapter_request_path)
        issues.extend(metadata_issues)
    if issues or metadata is None or not metadata_valid:
        report = build_animation_artifact_verification_report(
            metadata_loaded,
            adapter_display,
            None,
            None,
            metadata,
            [],
            issues,
            verification_mode="metadata_provenance" if adapter_request_path else "metadata_only",
            metadata_valid=False,
            provenance_checked=adapter_request_path is not None,
            preview_report_valid=False,
            runtime_artifacts_checked=False,
            total_frame_bytes=0,
        )
        return report, 2 if metadata_loaded.exit_code == 2 else 1

    artifacts, runtime_metadata_issues = verify_runtime_metadata_file(metadata_loaded, metadata, runtime_root=runtime_root)
    issues.extend(runtime_metadata_issues)
    preview_loaded: LoadedJson | None = None
    preview_mode: str | None = None
    preview_report_valid = False
    runtime_artifacts_checked = False
    total_frame_bytes = 0
    if preview_report_path is not None and not issues:
        preview_loaded = load_preview_renderer_report(preview_report_path, runtime_root=runtime_root)
        issues.extend(preview_loaded.issues)
        if preview_loaded.payload is not None and not preview_loaded.issues:
            preview_mode, preview_report_valid, preview_issues = validate_preview_renderer_report(preview_loaded.payload, metadata)
            issues.extend(preview_issues)
            if preview_report_valid and preview_mode == "preview_artifacts":
                render_result = preview_loaded.payload.get("render_result")
                frame_artifacts, frame_issues, total_frame_bytes = verify_preview_frame_set(render_result, metadata=metadata, runtime_root=runtime_root)
                artifacts.extend(frame_artifacts)
                issues.extend(frame_issues)
                runtime_artifacts_checked = True
            elif preview_report_valid:
                runtime_artifacts_checked = False
    mode = _mode(adapter_request_path, preview_loaded.payload if preview_loaded else None, preview_mode)
    report = build_animation_artifact_verification_report(
        metadata_loaded,
        adapter_display,
        preview_loaded.display_path if preview_loaded else None,
        preview_loaded.payload if preview_loaded else None,
        metadata,
        artifacts,
        issues,
        verification_mode=mode,
        metadata_valid=True,
        provenance_checked=adapter_request_path is not None,
        preview_report_valid=preview_report_valid,
        runtime_artifacts_checked=runtime_artifacts_checked,
        total_frame_bytes=total_frame_bytes,
    )
    return report, 0 if report["valid"] else 1


def build_animation_artifact_verification_report(
    metadata_loaded: LoadedJson,
    adapter_display: str | None,
    preview_display: str | None,
    preview_report: dict[str, Any] | None,
    metadata: dict[str, Any] | None,
    artifacts: list[dict[str, Any]],
    issues: list[ArtifactVerificationIssue] | tuple[ArtifactVerificationIssue, ...],
    *,
    verification_mode: str,
    metadata_valid: bool,
    provenance_checked: bool,
    preview_report_valid: bool,
    runtime_artifacts_checked: bool,
    total_frame_bytes: int,
) -> dict[str, Any]:
    sorted_issues = _sort_issues(list(issues))
    errors = [issue.as_report_item() for issue in sorted_issues if issue.severity == "error"]
    warnings = [issue.as_report_item() for issue in sorted_issues if issue.severity == "warning"]
    render_result = preview_report.get("render_result") if isinstance(preview_report, dict) and isinstance(preview_report.get("render_result"), dict) else {}
    summary = {
        "animation_id": metadata.get("animation_id") if isinstance(metadata, dict) else None,
        "source_kind": metadata.get("source_kind") if isinstance(metadata, dict) else None,
        "preview_id": render_result.get("preview_id") if isinstance(render_result, dict) else None,
        "frame_count": render_result.get("frame_count") if isinstance(render_result, dict) else 0,
        "artifact_count": len(artifacts),
        "total_frame_bytes": total_frame_bytes,
        "video_available": bool(metadata.get("preview_available")) if isinstance(metadata, dict) else False,
    }
    incomplete_codes = {"preview_directory_missing", "missing_preview_frame"}
    if not errors:
        status = "verified"
    elif any(error["code"] in incomplete_codes for error in errors):
        status = "incomplete"
    else:
        status = "invalid"
    artifacts_sorted = sorted(artifacts, key=lambda item: (item["role"] != "metadata", item.get("frame", -1), item["relative_path"]))
    return {
        "schema_version": "1.0",
        "report_type": "animation_artifact_verification",
        "status": status,
        "valid": not errors,
        "verification_mode": verification_mode,
        "metadata_path": metadata_loaded.display_path,
        "adapter_request_path": adapter_display,
        "preview_report_path": preview_display,
        "metadata_valid": metadata_valid and not any(error["code"] == "metadata_invalid" for error in errors),
        "provenance_checked": provenance_checked,
        "preview_report_valid": preview_report_valid,
        "runtime_artifacts_checked": runtime_artifacts_checked,
        "summary": summary,
        "artifacts": artifacts_sorted,
        "errors": errors,
        "warnings": warnings,
        "safety_flags": {
            "read_only": True,
            "runtime_assets_written": False,
            "runtime_assets_modified": False,
            "runtime_assets_deleted": False,
            "source_assets_modified": False,
            "generation_triggered": False,
            "blender_execution_attempted": False,
            "preview_render_attempted": False,
            "external_process_started": False,
        },
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Verify animation metadata and preview artifacts without writing files.")
    parser.add_argument("--metadata", required=True, help="Metadata JSON under configs/animation, /tmp, or runtime metadata root.")
    parser.add_argument("--adapter-request", help="Optional adapter request JSON under configs/animation or /tmp.")
    parser.add_argument("--preview-report", help="Optional preview renderer report JSON under /tmp or runtime reports root.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON verification report.")
    return parser


def run(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    report, exit_code = verify_animation_artifact_set(
        args.metadata,
        adapter_request_path=args.adapter_request,
        preview_report_path=args.preview_report,
    )
    print(json.dumps(report, indent=2 if args.pretty else None, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(run())
