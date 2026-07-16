"""Read-only verification helpers for future generated 3D artifact sets."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

DEFAULT_RUNTIME_3D_ROOT = "/home/cuneyt/MoE/runtime/media/outputs/3d"
ALLOWED_OUTPUT_KEYS = ["blend", "glb", "obj", "preview", "metadata", "report"]
TMP_ROOT = Path("/tmp")
REPO_ROOT = Path(__file__).resolve().parents[2]


def is_safe_runtime_relative_path(value: str) -> bool:
    if not isinstance(value, str) or value.strip() == "":
        return False

    path = Path(value)
    if path.is_absolute():
        return False
    if ".." in path.parts:
        return False

    lowered = value.lower()
    blocked_prefixes = (
        "apps/",
        "configs/",
        "docs/",
        "infra/",
        "packages/",
        "scripts/",
        "tools/",
        ".git/",
        "home/",
        "workspace/",
    )
    if lowered.startswith(blocked_prefixes):
        return False

    blocked_markers = (
        "moe_models_backup",
        "models_backup",
        "/models/",
        "\\models\\",
    )
    return not any(marker in lowered for marker in blocked_markers)


def _base_report(runtime_root: str) -> dict[str, Any]:
    return {
        "schema_version": "1.0",
        "report_type": "3d_artifact_verification",
        "valid": True,
        "error_count": 0,
        "errors": [],
        "runtime_root": runtime_root,
        "artifact_count": 0,
        "artifacts": [],
        "safety_flags": {
            "read_only": True,
            "runtime_assets_written": False,
            "source_assets_modified": False,
            "generation_triggered": False,
            "blender_execution_attempted": False,
        },
    }


def _add_error(report: dict[str, Any], message: str) -> None:
    report["errors"].append(message)
    report["error_count"] = len(report["errors"])
    report["valid"] = False


def verify_3d_artifact_set(
    metadata: dict[str, Any],
    runtime_root: str = DEFAULT_RUNTIME_3D_ROOT,
    require_existing_files: bool = False,
) -> dict[str, Any]:
    report = _base_report(runtime_root)

    if not isinstance(metadata, dict):
        _add_error(report, "metadata root must be an object")
        return report

    if metadata.get("asset_type") != "3d_model":
        _add_error(report, "asset_type must be 3d_model")
    if metadata.get("source") != "blender_parametric":
        _add_error(report, "source must be blender_parametric")
    if metadata.get("safety_label") != "visual_reference_only":
        _add_error(report, "safety_label must be visual_reference_only")
    if metadata.get("structural_certification") is not False:
        _add_error(report, "structural_certification must be false")

    output_files = metadata.get("output_files")
    if not isinstance(output_files, dict):
        _add_error(report, "output_files must be an object")
        return report

    runtime_base = Path(runtime_root).expanduser()
    if not runtime_base.is_absolute():
        _add_error(report, "runtime_root must be absolute")
        return report

    for key, value in output_files.items():
        if key not in ALLOWED_OUTPUT_KEYS:
            _add_error(report, f"output_files.{key} is not an allowed output key")
        if value is None:
            continue
        if not isinstance(value, str):
            _add_error(report, f"output_files.{key} must be null or a string")
            continue

        safe_path = is_safe_runtime_relative_path(value)
        artifact: dict[str, Any] = {
            "key": key,
            "relative_path": value,
            "safe_path": safe_path,
            "exists": None,
            "size_bytes": None,
        }
        if not safe_path:
            _add_error(report, f"output_files.{key} must be a safe runtime-relative path")
        elif require_existing_files:
            candidate = (runtime_base / value).resolve(strict=False)
            runtime_resolved = runtime_base.resolve(strict=False)
            if candidate != runtime_resolved and runtime_resolved not in candidate.parents:
                _add_error(report, f"output_files.{key} resolved outside runtime_root")
                artifact["exists"] = False
            elif not candidate.is_file():
                _add_error(report, f"output_files.{key} does not exist under runtime_root")
                artifact["exists"] = False
            else:
                artifact["exists"] = True
                artifact["size_bytes"] = candidate.stat().st_size

        report["artifacts"].append(artifact)

    report["artifact_count"] = len(report["artifacts"])
    report["error_count"] = len(report["errors"])
    report["valid"] = report["error_count"] == 0
    return report


def load_metadata_file(path: str, allow_tmp_only: bool = True) -> dict[str, Any]:
    candidate = Path(path).expanduser()
    if not candidate.is_absolute():
        raise ValueError("metadata path must be absolute")
    if ".." in candidate.parts:
        raise ValueError("metadata path must not contain path traversal")
    if candidate.suffix.lower() != ".json":
        raise ValueError("metadata path must use .json extension")

    resolved = candidate.resolve(strict=False)
    repo_root = REPO_ROOT.resolve(strict=True)
    runtime_root = Path(DEFAULT_RUNTIME_3D_ROOT).resolve(strict=False)
    tmp_root = TMP_ROOT.resolve(strict=True)

    if resolved == repo_root or repo_root in resolved.parents:
        raise ValueError("metadata path must not be inside the repo")
    if resolved == runtime_root or runtime_root in resolved.parents:
        raise ValueError("metadata path must not be inside runtime in this milestone")
    if allow_tmp_only and resolved != tmp_root and tmp_root not in resolved.parents:
        raise ValueError("metadata path must stay under /tmp in this milestone")
    if resolved.is_symlink():
        raise ValueError("metadata path must not be a symlink")
    if not resolved.is_file():
        raise ValueError(f"metadata file does not exist: {path}")

    try:
        payload = json.loads(resolved.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"metadata JSON is malformed: {exc.msg}") from exc
    if not isinstance(payload, dict):
        raise ValueError("metadata root must be an object")
    return payload
