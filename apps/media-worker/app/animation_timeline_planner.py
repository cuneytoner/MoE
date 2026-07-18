#!/usr/bin/env python3
"""Blender-independent animation timeline/keyframe planner for M36.3."""

from __future__ import annotations

import argparse
import copy
import json
import sys
from dataclasses import dataclass
from typing import Any

sys.dont_write_bytecode = True

from animation_plan_validator import (  # noqa: E402
    SAFETY_FLAGS as VALIDATOR_SAFETY_FLAGS,
    ValidationIssue,
    _sanitize_plan_path,
    load_animation_plan,
    load_animation_plan_schema,
    validate_animation_plan_semantics,
    validate_animation_plan_structure,
)


ANIMATED_FIELDS = ("location", "rotation_euler", "scale", "visibility")
PLANNER_SAFETY_FLAGS = {
    **VALIDATOR_SAFETY_FLAGS,
    "interpolation_evaluated": False,
    "keyframes_written": False,
}


@dataclass(frozen=True)
class PlannedKeyframe:
    sequence: int
    frame: int
    time_seconds: float
    normalized_progress: float
    values: tuple[tuple[str, Any], ...]


@dataclass(frozen=True)
class PlannedSegment:
    sequence: int
    start_frame: int
    end_frame: int
    frame_delta: int
    start_time_seconds: float
    end_time_seconds: float
    duration_seconds: float
    normalized_start: float
    normalized_end: float
    interpolation: str


@dataclass(frozen=True)
class PlannedTrack:
    sequence: int
    track_id: str
    target_type: str
    target_id: str
    property: str
    interpolation: str
    keyframes: tuple[PlannedKeyframe, ...]
    segments: tuple[PlannedSegment, ...]


@dataclass(frozen=True)
class PlannerResult:
    valid: bool
    plan: dict[str, Any] | None
    issues: tuple[ValidationIssue, ...]
    exit_code: int = 0


def _round_float(value: float) -> float:
    rounded = round(float(value), 9)
    return 0.0 if rounded == 0 else rounded


def canonical_plan_hash(plan: dict[str, Any]) -> str:
    import hashlib

    encoded = json.dumps(
        plan,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
        allow_nan=False,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def frame_to_time_seconds(frame: int, start_frame: int, fps: int) -> float:
    return _round_float((frame - start_frame) / fps)


def frame_to_normalized_progress(frame: int, start_frame: int, end_frame: int) -> float:
    frame_span = end_frame - start_frame
    if frame_span == 0:
        return 0.0
    return _round_float((frame - start_frame) / frame_span)


def _normalize_value(value: Any) -> Any:
    if isinstance(value, bool):
        return value
    if isinstance(value, list):
        return tuple(_round_float(float(item)) for item in value)
    return copy.deepcopy(value)


def _serialize_value(value: Any) -> Any:
    if isinstance(value, tuple):
        return [_serialize_value(item) for item in value]
    return value


def build_keyframe_plan(
    keyframe: dict[str, Any],
    *,
    sequence: int,
    start_frame: int,
    end_frame: int,
    fps: int,
) -> PlannedKeyframe:
    values = tuple(
        (field, _normalize_value(keyframe[field]))
        for field in ANIMATED_FIELDS
        if field in keyframe
    )
    frame = int(keyframe["frame"])
    return PlannedKeyframe(
        sequence=sequence,
        frame=frame,
        time_seconds=frame_to_time_seconds(frame, start_frame, fps),
        normalized_progress=frame_to_normalized_progress(frame, start_frame, end_frame),
        values=values,
    )


def build_segment_plan(
    start_keyframe: PlannedKeyframe,
    end_keyframe: PlannedKeyframe,
    *,
    sequence: int,
    fps: int,
    interpolation: str,
) -> PlannedSegment:
    frame_delta = end_keyframe.frame - start_keyframe.frame
    return PlannedSegment(
        sequence=sequence,
        start_frame=start_keyframe.frame,
        end_frame=end_keyframe.frame,
        frame_delta=frame_delta,
        start_time_seconds=start_keyframe.time_seconds,
        end_time_seconds=end_keyframe.time_seconds,
        duration_seconds=_round_float(frame_delta / fps),
        normalized_start=start_keyframe.normalized_progress,
        normalized_end=end_keyframe.normalized_progress,
        interpolation=interpolation,
    )


def build_track_plan(
    track: dict[str, Any],
    *,
    sequence: int,
    start_frame: int,
    end_frame: int,
    fps: int,
) -> PlannedTrack:
    keyframes = tuple(
        build_keyframe_plan(
            keyframe,
            sequence=index,
            start_frame=start_frame,
            end_frame=end_frame,
            fps=fps,
        )
        for index, keyframe in enumerate(track["keyframes"])
    )
    segments = tuple(
        build_segment_plan(
            keyframes[index],
            keyframes[index + 1],
            sequence=index,
            fps=fps,
            interpolation=track["interpolation"],
        )
        for index in range(max(0, len(keyframes) - 1))
    )
    return PlannedTrack(
        sequence=sequence,
        track_id=track["track_id"],
        target_type=track["target_type"],
        target_id=track["target_id"],
        property=track["property"],
        interpolation=track["interpolation"],
        keyframes=keyframes,
        segments=segments,
    )


def _serialize_keyframe(keyframe: PlannedKeyframe) -> dict[str, Any]:
    return {
        "sequence": keyframe.sequence,
        "frame": keyframe.frame,
        "time_seconds": keyframe.time_seconds,
        "normalized_progress": keyframe.normalized_progress,
        "values": {
            field: _serialize_value(value)
            for field, value in keyframe.values
        },
    }


def _serialize_segment(segment: PlannedSegment) -> dict[str, Any]:
    return {
        "sequence": segment.sequence,
        "start_frame": segment.start_frame,
        "end_frame": segment.end_frame,
        "frame_delta": segment.frame_delta,
        "start_time_seconds": segment.start_time_seconds,
        "end_time_seconds": segment.end_time_seconds,
        "duration_seconds": segment.duration_seconds,
        "normalized_start": segment.normalized_start,
        "normalized_end": segment.normalized_end,
        "interpolation": segment.interpolation,
    }


def _serialize_track(track: PlannedTrack) -> dict[str, Any]:
    first_frame = track.keyframes[0].frame if track.keyframes else None
    last_frame = track.keyframes[-1].frame if track.keyframes else None
    return {
        "sequence": track.sequence,
        "track_id": track.track_id,
        "target_type": track.target_type,
        "target_id": track.target_id,
        "property": track.property,
        "interpolation": track.interpolation,
        "keyframe_count": len(track.keyframes),
        "segment_count": len(track.segments),
        "first_frame": first_frame,
        "last_frame": last_frame,
        "keyframes": [_serialize_keyframe(keyframe) for keyframe in track.keyframes],
        "segments": [_serialize_segment(segment) for segment in track.segments],
    }


def build_timeline_keyframe_plan(plan: dict[str, Any]) -> PlannerResult:
    schema = load_animation_plan_schema()
    issues = validate_animation_plan_structure(plan, schema)
    if not issues:
        issues.extend(validate_animation_plan_semantics(plan))
    if issues:
        return PlannerResult(valid=False, plan=None, issues=tuple(sorted(issues, key=lambda item: (item.path, item.code, item.message))), exit_code=1)

    safe_plan = copy.deepcopy(plan)
    timeline = safe_plan["timeline"]
    fps = int(timeline["fps"])
    start_frame = int(timeline["start_frame"])
    end_frame = int(timeline["end_frame"])
    total_frames = end_frame - start_frame + 1
    frame_span = end_frame - start_frame
    tracks = tuple(
        build_track_plan(
            track,
            sequence=index,
            start_frame=start_frame,
            end_frame=end_frame,
            fps=fps,
        )
        for index, track in enumerate(safe_plan["tracks"])
    )
    serialized_tracks = [_serialize_track(track) for track in tracks]
    source_scene = safe_plan["scene"]["source_scene"]
    output_plan = {
        "schema_version": "1.0",
        "plan_type": "animation_timeline_keyframe_plan",
        "status": "planned",
        "mode": "dry_run",
        "source_plan_id": safe_plan["plan_id"],
        "source_plan_sha256": canonical_plan_hash(safe_plan),
        "title": safe_plan["title"],
        "visual_reference_only": True,
        "structural_certification": False,
        "operator_review_required": True,
        "timeline": {
            "fps": fps,
            "start_frame": start_frame,
            "end_frame": end_frame,
            "total_frames": total_frames,
            "frame_span": frame_span,
            "frame_duration_seconds": _round_float(1 / fps),
            "frame_span_seconds": _round_float(frame_span / fps),
            "duration_seconds": _round_float(total_frames / fps),
            "declared_duration_seconds": _round_float(float(timeline["duration_seconds"])),
        },
        "source_scene": {
            "type": source_scene["type"],
            "reference_id": source_scene["reference_id"],
            "units": safe_plan["scene"]["units"],
        },
        "tracks": serialized_tracks,
        "summary": {
            "track_count": len(serialized_tracks),
            "keyframe_count": sum(track["keyframe_count"] for track in serialized_tracks),
            "segment_count": sum(track["segment_count"] for track in serialized_tracks),
            "target_types": sorted({track["target_type"] for track in serialized_tracks}),
            "properties": sorted({track["property"] for track in serialized_tracks}),
            "interpolations": sorted({track["interpolation"] for track in serialized_tracks}),
        },
        "planned_outputs": {
            "preview_enabled": False,
            "preview_format": safe_plan["outputs"]["preview"]["format"],
            "preview_relative_runtime_path": safe_plan["outputs"]["preview"]["relative_runtime_path"],
            "metadata_relative_runtime_path": safe_plan["outputs"]["metadata"]["relative_runtime_path"],
        },
        "safety_flags": dict(PLANNER_SAFETY_FLAGS),
    }
    return PlannerResult(valid=True, plan=output_plan, issues=tuple(), exit_code=0)


def _issue_items(issues: tuple[ValidationIssue, ...]) -> list[dict[str, str]]:
    return [
        {
            "code": issue.code,
            "path": issue.path,
            "message": issue.message,
        }
        for issue in sorted(issues, key=lambda item: (item.path, item.code, item.message))
    ]


def build_timeline_planner_report(plan_path: str) -> tuple[dict[str, Any], int]:
    plan, display_path, load_issues = load_animation_plan(plan_path)
    if load_issues or plan is None:
        issues = tuple(issue for issue in load_issues if issue is not None)
        return (
            {
                "schema_version": "1.0",
                "report_type": "animation_timeline_planner",
                "status": "invalid",
                "planned": False,
                "source_plan_path": display_path,
                "timeline_plan": None,
                "errors": _issue_items(issues),
                "warnings": [],
                "safety_flags": dict(PLANNER_SAFETY_FLAGS),
            },
            2,
        )

    try:
        result = build_timeline_keyframe_plan(plan)
    except ValueError:
        issues = (ValidationIssue(code="schema_load_failed", path="$.schema", message="canonical schema could not be loaded"),)
        result = PlannerResult(valid=False, plan=None, issues=issues, exit_code=2)

    planned = result.valid and result.plan is not None
    return (
        {
            "schema_version": "1.0",
            "report_type": "animation_timeline_planner",
            "status": "planned" if planned else "invalid",
            "planned": planned,
            "source_plan_path": _sanitize_plan_path(display_path),
            "timeline_plan": result.plan if planned else None,
            "errors": _issue_items(result.issues),
            "warnings": [],
            "safety_flags": dict(PLANNER_SAFETY_FLAGS),
        },
        0 if planned else result.exit_code,
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Build a source-only animation timeline/keyframe plan.")
    parser.add_argument("--plan", required=True, help="Plan path under configs/animation or /tmp.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON planner report.")
    return parser


def run(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    report, exit_code = build_timeline_planner_report(args.plan)
    indent = 2 if args.pretty else None
    print(json.dumps(report, indent=indent, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(run())
