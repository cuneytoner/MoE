from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


def _add_shared_package_path() -> None:
    candidates = (
        Path("/app/packages/animation-validation"),
        Path.cwd() / "packages" / "animation-validation",
        Path("/home/cuneyt/DiskD/Projects/MoE/codebase/packages/animation-validation"),
        Path("/home/cuneyt/MoE/codebase/packages/animation-validation"),
        Path("/workspace/packages/animation-validation"),
    )
    for candidate in candidates:
        if candidate.is_dir():
            sys.path.insert(0, str(candidate))
            return


_add_shared_package_path()

from animation_validation.artifacts import verify_animation_artifact_set  # noqa: E402
from animation_validation.metadata import (  # noqa: E402
    load_animation_metadata_schema,
    validate_animation_metadata_semantics,
    validate_animation_metadata_structure,
)
from animation_validation.paths import (  # noqa: E402
    ANIMATION_ROOT_REL,
    DEFAULT_RUNTIME_ROOT,
    DEPLOYED_REPO_ROOT,
    METADATA_ROOT_REL,
    MODEL_BACKUP_ROOT,
    PREVIEW_ROOT_REL,
    REPORT_ROOT_REL,
    SOURCE_REPO_ROOT,
)


DEFAULT_RUNTIME_ROOT = DEFAULT_RUNTIME_ROOT
RUNTIME_SCOPE = "runtime/media/animation"
MAX_METADATA_SIDECARS = 200
MAX_PREVIEW_REPORTS = 200
MAX_METADATA_BYTES = 512 * 1024
MAX_PREVIEW_REPORT_BYTES = 1024 * 1024
MAX_WARNINGS = 200
MAX_CARDS = 200


def build_animation_output_cards() -> dict[str, Any]:
    return _build_animation_output_cards_from_root(DEFAULT_RUNTIME_ROOT)


def _build_animation_output_cards_from_root(runtime_root: str | Path) -> dict[str, Any]:
    root = Path(runtime_root)
    response = _base_response()
    warnings: list[str] = response["warnings"]

    root_error = _root_error(root)
    if root_error is not None:
        _add_warning(warnings, root_error)
        return response

    animation_root = root / ANIMATION_ROOT_REL
    metadata_dir = root / METADATA_ROOT_REL
    reports_dir = root / REPORT_ROOT_REL
    preview_root = root / PREVIEW_ROOT_REL
    for rel, child in (
        (ANIMATION_ROOT_REL, animation_root),
        (METADATA_ROOT_REL, metadata_dir),
        (REPORT_ROOT_REL, reports_dir),
        (PREVIEW_ROOT_REL, preview_root),
    ):
        child_error = _child_root_error(root, child, rel.as_posix(), require_exists=rel != PREVIEW_ROOT_REL)
        if child_error is not None:
            _add_warning(warnings, child_error)
            if rel == METADATA_ROOT_REL:
                response["metadata_dir_available"] = False
                return response
            if rel == REPORT_ROOT_REL:
                response["reports_dir_available"] = False
    response["metadata_dir_available"] = metadata_dir.exists() and metadata_dir.is_dir() and not metadata_dir.is_symlink()
    response["reports_dir_available"] = reports_dir.exists() and reports_dir.is_dir() and not reports_dir.is_symlink()
    if not response["metadata_dir_available"]:
        return response

    reports = _load_preview_reports(root, reports_dir, warnings) if response["reports_dir_available"] else []
    response["preview_report_count"] = len(reports)
    seen_ids: set[str] = set()
    for metadata_path in _iter_json_children(metadata_dir, warnings, "metadata", MAX_METADATA_SIDECARS):
        metadata_rel = _runtime_relative(root, metadata_path)
        if metadata_rel is None:
            response["invalid_count"] += 1
            _add_warning(warnings, f"{_label('metadata', metadata_path)}: metadata path outside runtime scope")
            continue
        card_id = f"animation:{metadata_rel}"
        if card_id in seen_ids:
            response["invalid_count"] += 1
            _add_warning(warnings, f"metadata/{metadata_path.name}: duplicate animation card id")
            continue
        seen_ids.add(card_id)
        metadata, metadata_errors = _load_valid_metadata(root, metadata_path, metadata_rel)
        if metadata_errors or metadata is None:
            response["invalid_count"] += 1
            _add_warning(warnings, f"metadata/{metadata_path.name}: {'; '.join(metadata_errors)}")
            continue
        card = _card_from_metadata(root, metadata_path, metadata_rel, metadata, reports, warnings)
        response["cards"].append(card)
        if card["preview"]["available"] is True:
            response["verified_preview_count"] += 1
        if len(response["cards"]) >= MAX_CARDS:
            _add_warning(warnings, "animation card limit reached; remaining metadata omitted")
            break

    response["cards"].sort(key=lambda card: card["id"])
    response["card_count"] = len(response["cards"])
    return response


def _base_response() -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "gateway-animation-output-cards",
        "runtime_scope": RUNTIME_SCOPE,
        "metadata_dir_available": False,
        "reports_dir_available": False,
        "card_count": 0,
        "invalid_count": 0,
        "preview_report_count": 0,
        "verified_preview_count": 0,
        "cards": [],
        "warnings": [],
        "safety_flags": {
            "read_only": True,
            "generation_triggered": False,
            "animation_execution_attempted": False,
            "preview_render_attempted": False,
            "runtime_assets_written": False,
            "runtime_assets_modified": False,
            "runtime_assets_deleted": False,
            "source_assets_modified": False,
            "external_process_started": False,
            "shell_execution": False,
        },
    }


def _root_error(root: Path) -> str | None:
    if not root.is_absolute():
        return "animation runtime root is not absolute"
    if _unsafe_parts(root):
        return "animation runtime root contains unsafe path segments"
    if _is_under(root, SOURCE_REPO_ROOT) or _is_under(root, DEPLOYED_REPO_ROOT) or _is_under(root, MODEL_BACKUP_ROOT):
        return "animation runtime root is outside the approved runtime scope"
    try:
        if root.exists() and root.is_symlink():
            return "animation runtime root is a symlink and was not scanned"
        if root.exists() and not root.is_dir():
            return "animation runtime root is not a directory"
    except OSError:
        return "animation runtime root could not be inspected"
    return None


def _child_root_error(root: Path, path: Path, label: str, *, require_exists: bool) -> str | None:
    if _unsafe_parts(path) or not _is_under(path, root):
        return f"{label}: path is outside animation runtime scope"
    try:
        if not path.exists():
            return f"{label}: directory is not available" if require_exists else None
        if path.is_symlink():
            return f"{label}: symlink directory was not scanned"
        if not path.is_dir():
            return f"{label}: path is not a directory"
    except OSError:
        return f"{label}: directory could not be inspected"
    return None


def _iter_json_children(directory: Path, warnings: list[str], label: str, limit: int) -> list[Path]:
    results: list[Path] = []
    try:
        entries = sorted(directory.iterdir(), key=lambda item: item.name)
    except OSError:
        _add_warning(warnings, f"{label}: scan failed")
        return results
    json_seen = 0
    for entry in entries:
        display = f"{label}/{entry.name}"
        try:
            if entry.is_symlink():
                _add_warning(warnings, f"{display}: symlink skipped")
                continue
            if entry.name.startswith("."):
                continue
            if entry.is_dir():
                _add_warning(warnings, f"{display}: nested directory skipped")
                continue
            if not entry.is_file() or entry.suffix.lower() != ".json":
                continue
            json_seen += 1
            if json_seen > limit:
                _add_warning(warnings, f"{label}: scan limit reached; remaining files omitted")
                break
            results.append(entry)
        except OSError:
            _add_warning(warnings, f"{display}: entry could not be inspected")
    return results


def _load_valid_metadata(root: Path, metadata_path: Path, metadata_rel: str) -> tuple[dict[str, Any] | None, list[str]]:
    try:
        if metadata_path.lstat().st_size > MAX_METADATA_BYTES:
            return None, ["metadata sidecar exceeds 512 KiB"]
        payload = json.loads(metadata_path.read_text(encoding="utf-8"))
    except UnicodeDecodeError:
        return None, ["metadata sidecar is not valid UTF-8"]
    except json.JSONDecodeError:
        return None, ["metadata sidecar is malformed JSON"]
    except OSError:
        return None, ["metadata sidecar could not be read"]
    if not isinstance(payload, dict):
        return None, ["metadata root must be an object"]
    try:
        schema = load_animation_metadata_schema()
    except ValueError:
        return None, ["animation metadata schema could not be loaded"]
    issues = list(validate_animation_metadata_structure(payload, schema))
    if not [issue for issue in issues if issue.severity == "error"]:
        issues.extend(validate_animation_metadata_semantics(payload))
    expected = payload.get("output_files", {}).get("metadata") if isinstance(payload.get("output_files"), dict) else None
    if expected != metadata_rel:
        return None, ["metadata output reference must match the runtime metadata file"]
    errors = [issue for issue in issues if issue.severity == "error"]
    if errors:
        return None, [_safe_issue(issue.code) for issue in errors[:5]]
    if not _is_under(metadata_path, root):
        return None, ["metadata path outside runtime scope"]
    return payload, []


def _load_preview_reports(root: Path, reports_dir: Path, warnings: list[str]) -> list[dict[str, Any]]:
    reports: list[dict[str, Any]] = []
    for report_path in _iter_json_children(reports_dir, warnings, "reports", MAX_PREVIEW_REPORTS):
        try:
            if report_path.lstat().st_size > MAX_PREVIEW_REPORT_BYTES:
                _add_warning(warnings, f"reports/{report_path.name}: preview report exceeds 1 MiB")
                continue
            payload = json.loads(report_path.read_text(encoding="utf-8"))
        except UnicodeDecodeError:
            _add_warning(warnings, f"reports/{report_path.name}: preview report is not valid UTF-8")
            continue
        except json.JSONDecodeError:
            _add_warning(warnings, f"reports/{report_path.name}: preview report is malformed JSON")
            continue
        except OSError:
            _add_warning(warnings, f"reports/{report_path.name}: preview report could not be read")
            continue
        if not isinstance(payload, dict):
            _add_warning(warnings, f"reports/{report_path.name}: preview report root must be an object")
            continue
        if payload.get("report_type") != "animation_preview_renderer":
            continue
        report_rel = _runtime_relative(root, report_path)
        if report_rel is None:
            _add_warning(warnings, f"reports/{report_path.name}: report path outside runtime scope")
            continue
        reports.append({"path": report_path, "relative_path": report_rel, "payload": payload})
    reports.sort(key=lambda item: str(item["relative_path"]))
    return reports


def _card_from_metadata(root: Path, metadata_path: Path, metadata_rel: str, metadata: dict[str, Any], reports: list[dict[str, Any]], warnings: list[str]) -> dict[str, Any]:
    matching = _matching_rendered_reports(metadata, reports)
    preview = _empty_preview()
    verification = {
        "metadata_valid": True,
        "provenance_checked": False,
        "preview_report_valid": False,
        "runtime_preview_verified": False,
        "valid": True,
        "error_count": 0,
        "warning_count": 0,
    }
    report_rel: str | None = None
    preview_frames: str | None = None
    if len(matching) > 1:
        _add_warning(warnings, f"animation card {metadata.get('animation_id', 'unknown')}: ambiguous_preview_reports")
        verification["warning_count"] += 1
    elif len(matching) == 1:
        report = matching[0]
        report_rel = str(report["relative_path"])
        verify_report, _ = verify_animation_artifact_set(str(metadata_path), preview_report_path=str(report["path"]), runtime_root=root)
        verification["preview_report_valid"] = bool(verify_report.get("preview_report_valid"))
        verification["runtime_preview_verified"] = bool(verify_report.get("runtime_artifacts_checked")) and bool(verify_report.get("valid"))
        verification["valid"] = True
        verification["error_count"] = len(verify_report.get("errors") or [])
        verification["warning_count"] = len(verify_report.get("warnings") or [])
        render_result = report["payload"].get("render_result") if isinstance(report["payload"].get("render_result"), dict) else {}
        if verify_report.get("valid") is True and _render_result_publish_ok(render_result):
            frames = render_result.get("frames")
            rel_dir = render_result.get("relative_output_directory")
            if isinstance(frames, list) and frames and isinstance(rel_dir, str):
                preview_frames = rel_dir
                preview = {
                    "available": True,
                    "preview_id": render_result.get("preview_id"),
                    "format": "PNG",
                    "frame_count": render_result.get("frame_count"),
                    "width": render_result.get("width"),
                    "height": render_result.get("height"),
                    "relative_directory": rel_dir,
                    "first_frame_relative_path": f"{rel_dir}/frame-{frames[0]:06d}.png",
                    "total_output_bytes": render_result.get("total_output_bytes"),
                }
        elif verification["error_count"]:
            _add_warning(warnings, f"animation card {metadata.get('animation_id', 'unknown')}: preview report did not verify")
    paths = {
        "metadata": metadata_rel,
        "declared_video_preview": _safe_declared_video(metadata),
        "preview_frames": preview_frames,
        "report": report_rel if preview["available"] is True else None,
    }
    return {
        "id": f"animation:{metadata_rel}",
        "type": "animation",
        "animation_id": metadata.get("animation_id"),
        "title": metadata.get("title"),
        "created_at": metadata.get("created_at"),
        "source_kind": metadata.get("source_kind"),
        "generation_mode": metadata.get("generation_mode"),
        "timeline": metadata.get("timeline"),
        "summary": _summary(metadata),
        "preview": preview,
        "relative_runtime_paths": paths,
        "verification": verification,
        "visual_reference_only": metadata.get("visual_reference_only"),
        "structural_certification": metadata.get("structural_certification"),
        "operator_review_required": metadata.get("operator_review_required"),
    }


def _matching_rendered_reports(metadata: dict[str, Any], reports: list[dict[str, Any]]) -> list[dict[str, Any]]:
    matches: list[dict[str, Any]] = []
    for report in reports:
        payload = report["payload"]
        operation_plan = payload.get("operation_plan")
        if payload.get("status") != "rendered" or payload.get("rendered") is not True or not isinstance(operation_plan, dict):
            continue
        if (
            operation_plan.get("source_kind") == metadata.get("source_kind")
            and operation_plan.get("source_request_sha256") == metadata.get("source_request_sha256")
            and operation_plan.get("canonical_plan_sha256") == metadata.get("canonical_plan_sha256")
        ):
            matches.append(report)
    return matches


def _render_result_publish_ok(render_result: Any) -> bool:
    return (
        isinstance(render_result, dict)
        and render_result.get("final_output_published") is True
        and render_result.get("partial_output_available") is False
        and isinstance(render_result.get("safety_flags"), dict)
        and render_result["safety_flags"].get("render_settings_restored") is True
    )


def _summary(metadata: dict[str, Any]) -> dict[str, Any]:
    animation_summary = metadata.get("animation_summary") if isinstance(metadata.get("animation_summary"), dict) else {}
    adapter_summary = metadata.get("adapter_summary") if isinstance(metadata.get("adapter_summary"), dict) else {}
    return {
        "track_count": animation_summary.get("track_count"),
        "keyframe_count": animation_summary.get("keyframe_count"),
        "segment_count": animation_summary.get("segment_count"),
        "operation_count": adapter_summary.get("operation_count"),
        "target_types": animation_summary.get("target_types"),
        "target_ids": animation_summary.get("target_ids"),
        "properties": animation_summary.get("properties"),
        "interpolations": animation_summary.get("interpolations"),
    }


def _empty_preview() -> dict[str, Any]:
    return {
        "available": False,
        "preview_id": None,
        "format": None,
        "frame_count": 0,
        "width": None,
        "height": None,
        "relative_directory": None,
        "first_frame_relative_path": None,
        "total_output_bytes": 0,
    }


def _safe_declared_video(metadata: dict[str, Any]) -> str | None:
    output_files = metadata.get("output_files")
    value = output_files.get("preview") if isinstance(output_files, dict) else None
    if not isinstance(value, str):
        return None
    if value.startswith("media/animation/previews/") and value.endswith((".mp4", ".webm", ".gif")) and _safe_relative_text(value):
        return value
    return None


def _safe_relative_text(value: str) -> bool:
    path = Path(value)
    return not path.is_absolute() and path.as_posix() == value and not any(part in {"", ".", ".."} for part in path.parts)


def _runtime_relative(root: Path, path: Path) -> str | None:
    try:
        return path.resolve(strict=False).relative_to(root.resolve(strict=False)).as_posix()
    except ValueError:
        return None


def _is_under(path: Path, root: Path) -> bool:
    try:
        path.resolve(strict=False).relative_to(root.resolve(strict=False))
        return True
    except ValueError:
        return False
    except OSError:
        return False


def _unsafe_parts(path: Path) -> bool:
    return any(part in {"", ".", ".."} for part in path.parts)


def _safe_issue(code: str) -> str:
    return code.replace("/", "_").replace("\\", "_")[:80]


def _label(kind: str, path: Path) -> str:
    return f"{kind}/{path.name}"


def _add_warning(warnings: list[str], message: str) -> None:
    if len(warnings) < MAX_WARNINGS:
        warnings.append(message)
    elif len(warnings) == MAX_WARNINGS:
        warnings.append("warning limit reached; remaining warnings omitted")
