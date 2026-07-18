#!/usr/bin/env python3
"""Plan-only animation metadata sidecar writer for M36.8."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True

from blender_animation_adapter import (  # noqa: E402
    AdapterIssue,
    AdapterRequestResult,
    build_blender_animation_operation_plan,
    load_adapter_request,
    validate_adapter_request,
)
from animation_timeline_planner import canonical_plan_hash  # noqa: E402


REPO_ROOT = Path(__file__).resolve().parents[3]
TMP_ROOT = Path("/tmp")
GENERATOR_SCRIPT = "apps/media-worker/app/animation_metadata_sidecar.py"
GENERATOR_VERSION = "0.1.0"
CREATED_AT_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
HASH_RE = re.compile(r"^[a-f0-9]{64}$")
SAFE_TARGET_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_-]*$")
OUTPUT_BLOCKED_MARKERS = (
    "/home/",
    "/mnt/",
    "/media/",
    "/workspace/",
    "/app/",
    "MoE_Models_Backup",
    "DiskD/Projects/MoE/codebase",
)
SAFETY_FLAGS = {
    "metadata_written": False,
    "read_only_inputs": True,
    "runtime_assets_written": False,
    "source_assets_modified": False,
    "generation_triggered": False,
    "blender_execution_attempted": False,
    "keyframes_written": False,
    "scene_modified": False,
    "preview_render_attempted": False,
    "external_process_started": False,
    "blend_file_saved": False,
}


@dataclass(frozen=True)
class MetadataIssue:
    code: str
    path: str
    message: str

    def as_report_item(self) -> dict[str, str]:
        return {"code": self.code, "path": self.path, "message": self.message}


def _issue(code: str, path: str, message: str) -> MetadataIssue:
    return MetadataIssue(code=code, path=path, message=message)


def _issue_items(issues: tuple[MetadataIssue | AdapterIssue, ...] | list[MetadataIssue | AdapterIssue]) -> list[dict[str, str]]:
    return [issue.as_report_item() for issue in sorted(issues, key=lambda item: (item.path, item.code, item.message))]


def canonical_payload_hash(payload: dict[str, Any]) -> str:
    return canonical_plan_hash(payload)


def _current_created_at() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _validate_created_at(created_at: str) -> None:
    if not CREATED_AT_RE.fullmatch(created_at):
        raise ValueError("created_at must use YYYY-MM-DDTHH:MM:SSZ")
    datetime.strptime(created_at, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=UTC)


def _safe_runtime_relative_path(value: object, *, prefix: str, suffix: str) -> str:
    if not isinstance(value, str) or not value:
        raise ValueError("runtime output path must be a non-empty string")
    if value.startswith("/") or "\\" in value or "://" in value or re.match(r"^[A-Za-z]:", value):
        raise ValueError("runtime output path must be relative POSIX")
    if any(marker in value for marker in OUTPUT_BLOCKED_MARKERS):
        raise ValueError("runtime output path contains blocked source/runtime/model marker")
    path = Path(value)
    if path.is_absolute() or any(part in {"", ".", ".."} for part in path.parts):
        raise ValueError("runtime output path must not contain empty, dot, or traversal segments")
    if path.as_posix() != value:
        raise ValueError("runtime output path must be normalized POSIX")
    if not value.startswith(prefix) or not value.endswith(suffix):
        raise ValueError(f"runtime output path must stay under {prefix} and use {suffix}")
    return value


def _safe_target_id(value: object) -> str:
    if not isinstance(value, str) or not SAFE_TARGET_ID_RE.fullmatch(value):
        raise ValueError("target id must be a safe identifier")
    if any(marker in value for marker in ("/", "\\", "..", "://", "/home/", "MoE_Models_Backup")):
        raise ValueError("target id must not contain path, URL, runtime, repo, or model markers")
    return value


def load_metadata_source_request(request_path: str) -> AdapterRequestResult:
    return load_adapter_request(request_path)


def _timeline_summary(canonical_plan: dict[str, Any], timeline_plan: dict[str, Any]) -> dict[str, Any]:
    canonical_timeline = canonical_plan["timeline"]
    normalized_timeline = timeline_plan["timeline"]
    expected = {
        "fps": canonical_timeline["fps"],
        "start_frame": canonical_timeline["start_frame"],
        "end_frame": canonical_timeline["end_frame"],
        "total_frames": canonical_timeline["end_frame"] - canonical_timeline["start_frame"] + 1,
        "duration_seconds": canonical_timeline["duration_seconds"],
    }
    for key, value in expected.items():
        if normalized_timeline.get(key) != value:
            raise ValueError(f"timeline mismatch for {key}")
    return expected


def _animation_summary(timeline_plan: dict[str, Any]) -> dict[str, Any]:
    tracks = timeline_plan["tracks"]
    target_ids = sorted({_safe_target_id(track["target_id"]) for track in tracks})
    return {
        "track_count": timeline_plan["summary"]["track_count"],
        "keyframe_count": timeline_plan["summary"]["keyframe_count"],
        "segment_count": timeline_plan["summary"]["segment_count"],
        "target_types": sorted(timeline_plan["summary"]["target_types"]),
        "target_ids": target_ids,
        "properties": sorted(timeline_plan["summary"]["properties"]),
        "interpolations": sorted(timeline_plan["summary"]["interpolations"]),
    }


def _adapter_summary(operation_plan: dict[str, Any]) -> dict[str, Any]:
    resolved_target_ids: list[str] = []
    seen: set[str] = set()
    for operation in operation_plan["operations"]:
        if operation["operation_type"] != "resolve_target":
            continue
        target_id = _safe_target_id(operation["target_id"])
        if target_id not in seen:
            seen.add(target_id)
            resolved_target_ids.append(target_id)
    return {
        "operation_count": operation_plan["operation_count"],
        "operation_types": sorted(operation_plan["operation_types"]),
        "resolved_target_ids": resolved_target_ids,
        "execution_status": "not_executed",
    }


def build_animation_metadata_sidecar(
    adapter_request: dict[str, Any],
    operation_plan: dict[str, Any],
    *,
    created_at: str | None = None,
    metadata_written: bool = False,
) -> dict[str, Any]:
    timestamp = created_at or _current_created_at()
    _validate_created_at(timestamp)
    canonical_plan = adapter_request["canonical_animation_plan"]
    timeline_plan = adapter_request["timeline_plan"]
    preview_path = _safe_runtime_relative_path(
        canonical_plan["outputs"]["preview"]["relative_runtime_path"],
        prefix="media/animation/previews/",
        suffix=f".{canonical_plan['outputs']['preview']['format']}",
    )
    metadata_path = _safe_runtime_relative_path(
        canonical_plan["outputs"]["metadata"]["relative_runtime_path"],
        prefix="media/animation/metadata/",
        suffix=".json",
    )
    canonical_hash = canonical_payload_hash(canonical_plan)
    if timeline_plan.get("source_plan_sha256") != canonical_hash:
        raise ValueError("timeline source hash does not match canonical plan")

    safety_flags = dict(SAFETY_FLAGS)
    safety_flags["metadata_written"] = metadata_written
    source_scene = canonical_plan["scene"]["source_scene"]
    return {
        "schema_version": "1.0",
        "metadata_type": "animation_sidecar",
        "asset_type": "animation",
        "source": "blender_animation_adapter",
        "generator_script": GENERATOR_SCRIPT,
        "generator_version": GENERATOR_VERSION,
        "animation_id": canonical_plan["plan_id"],
        "title": canonical_plan["title"],
        "created_at": timestamp,
        "source_kind": adapter_request["source_kind"],
        "source_request_sha256": adapter_request["source_request_sha256"],
        "adapter_request_sha256": canonical_payload_hash(adapter_request),
        "canonical_plan_sha256": canonical_hash,
        "operation_plan_sha256": canonical_payload_hash(operation_plan),
        "source_scene": {
            "type": source_scene["type"],
            "reference_id": source_scene["reference_id"],
            "units": canonical_plan["scene"]["units"],
        },
        "timeline": _timeline_summary(canonical_plan, timeline_plan),
        "animation_summary": _animation_summary(timeline_plan),
        "adapter_summary": _adapter_summary(operation_plan),
        "output_files": {
            "preview": preview_path,
            "metadata": metadata_path,
            "report": None,
        },
        "preview_available": False,
        "visual_reference_only": True,
        "structural_certification": False,
        "operator_review_required": True,
        "generation_mode": "metadata_only",
        "validation": {
            "adapter_request_valid": True,
            "canonical_plan_valid": True,
            "timeline_plan_valid": True,
            "operation_plan_valid": True,
        },
        "warnings": [],
        "safety_flags": safety_flags,
    }


def validate_metadata_output_path(output_path: str) -> Path:
    destination = Path(output_path)
    if not destination.is_absolute():
        raise ValueError("metadata output path must be absolute")
    if len(str(destination)) > 4096:
        raise ValueError("metadata output path is too long")
    if ".." in destination.parts:
        raise ValueError("metadata output path must not contain traversal")
    if destination.suffix.lower() != ".json":
        raise ValueError("metadata output path must use .json extension")
    for parent in [destination.parent, *destination.parent.parents]:
        if parent == parent.parent:
            break
        if parent.exists() and parent.is_symlink():
            raise ValueError("metadata output parent must not be a symlink")
    resolved = destination.resolve(strict=False)
    tmp_root = TMP_ROOT.resolve(strict=True)
    repo_root = REPO_ROOT.resolve(strict=True)
    if resolved == repo_root or repo_root in resolved.parents:
        raise ValueError("metadata output path must not be inside the repo")
    if str(resolved).startswith("/home/") or str(resolved).startswith("/mnt/") or str(resolved).startswith("/media/"):
        raise ValueError("metadata output path must stay under /tmp")
    if resolved != tmp_root and tmp_root not in resolved.parents:
        raise ValueError("metadata output path must stay under /tmp")
    parent = resolved.parent
    existing_parent = parent
    while not existing_parent.exists():
        if existing_parent == existing_parent.parent:
            raise ValueError("metadata output parent cannot be resolved")
        existing_parent = existing_parent.parent
    if existing_parent.is_symlink():
        raise ValueError("metadata output parent must not be a symlink")
    if destination.exists() and destination.is_symlink():
        raise ValueError("metadata output path must not be a symlink")
    return resolved


def write_animation_metadata_sidecar(metadata: dict[str, Any], output_path: str) -> str:
    destination = validate_metadata_output_path(output_path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.parent.is_symlink():
        raise ValueError("metadata output parent must not be a symlink")

    payload = dict(metadata)
    safety_flags = dict(payload["safety_flags"])
    safety_flags["metadata_written"] = True
    safety_flags["runtime_assets_written"] = False
    safety_flags["source_assets_modified"] = False
    safety_flags["generation_triggered"] = False
    safety_flags["blender_execution_attempted"] = False
    safety_flags["preview_render_attempted"] = False
    safety_flags["external_process_started"] = False
    payload["safety_flags"] = safety_flags

    tmp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            "w",
            encoding="utf-8",
            dir=destination.parent,
            prefix=f".{destination.name}.",
            suffix=".tmp",
            delete=False,
        ) as handle:
            tmp_path = Path(handle.name)
            json.dump(payload, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_path, destination)
    finally:
        if tmp_path is not None and tmp_path.exists():
            tmp_path.unlink()
    return str(destination)


def _base_report(status: str, metadata: dict[str, Any] | None, errors: list[dict[str, str]], *, metadata_path: str | None = None) -> dict[str, Any]:
    safety_flags = dict(SAFETY_FLAGS)
    safety_flags["metadata_written"] = status == "written"
    return {
        "schema_version": "1.0",
        "report_type": "animation_metadata_sidecar_writer",
        "status": status,
        "metadata_path": metadata_path,
        "metadata": metadata or {},
        "errors": errors,
        "warnings": [],
        "safety_flags": safety_flags,
    }


def build_animation_metadata_writer_report(
    adapter_request_path: str,
    *,
    write_metadata_path: str | None = None,
    created_at: str | None = None,
) -> tuple[dict[str, Any], int]:
    loaded = load_metadata_source_request(adapter_request_path)
    if loaded.issues or loaded.request is None:
        return _base_report("invalid", None, _issue_items(loaded.issues)), loaded.exit_code

    request_issues = validate_adapter_request(loaded.request)
    if request_issues:
        return _base_report("invalid", None, _issue_items(request_issues)), 1
    plan_result = build_blender_animation_operation_plan(loaded.request)
    if not plan_result.valid or plan_result.operation_plan is None:
        return _base_report("invalid", None, _issue_items(plan_result.issues)), 1
    try:
        metadata = build_animation_metadata_sidecar(
            loaded.request,
            plan_result.operation_plan,
            created_at=created_at,
            metadata_written=False,
        )
    except ValueError as exc:
        return _base_report("invalid", None, [_issue("metadata_contract_invalid", "$.metadata", str(exc)).as_report_item()]), 1

    if write_metadata_path is None:
        return _base_report("planned", metadata, []), 0

    try:
        written_path = write_animation_metadata_sidecar(metadata, write_metadata_path)
    except ValueError as exc:
        return _base_report("output_error", metadata, [_issue("metadata_output_path_invalid", "$.write_metadata", str(exc)).as_report_item()]), 2
    written_metadata = dict(metadata)
    written_safety = dict(written_metadata["safety_flags"])
    written_safety["metadata_written"] = True
    written_metadata["safety_flags"] = written_safety
    return _base_report("written", written_metadata, [], metadata_path=written_path), 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build or write a safe animation metadata sidecar.")
    parser.add_argument("--adapter-request", required=True, help="Adapter request JSON under configs/animation or /tmp.")
    parser.add_argument("--write-metadata", help="Write metadata sidecar JSON to an absolute /tmp path.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON writer report.")
    return parser


def run(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    report, exit_code = build_animation_metadata_writer_report(
        args.adapter_request,
        write_metadata_path=args.write_metadata,
    )
    print(json.dumps(report, indent=2 if args.pretty else None, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(run())
