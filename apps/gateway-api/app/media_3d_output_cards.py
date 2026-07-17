from __future__ import annotations

import json
from pathlib import Path
from typing import Any


DEFAULT_RUNTIME_3D_ROOT = Path("/home/cuneyt/MoE/runtime/media/outputs/3d")
METADATA_SUBDIR = "metadata"
ALLOWED_OUTPUT_KEYS = ("blend", "glb", "obj", "preview", "metadata", "report")
FORMAT_OUTPUT_KEYS = ("blend", "glb", "obj")
MAX_METADATA_BYTES = 128 * 1024


def build_3d_output_cards(runtime_root: str | Path = DEFAULT_RUNTIME_3D_ROOT) -> dict[str, Any]:
    root = Path(runtime_root).expanduser()
    response = _base_response(root)

    if not root.is_absolute():
        response["metadata_dir_available"] = False
        response["warnings"].append("3D runtime root is not absolute.")
        return response

    metadata_dir = root / METADATA_SUBDIR
    if not metadata_dir.exists():
        response["metadata_dir_available"] = False
        response["warnings"].append("3D metadata directory is not available.")
        return response
    if metadata_dir.is_symlink():
        response["metadata_dir_available"] = False
        response["warnings"].append("3D metadata directory is a symlink and was not scanned.")
        return response
    if not metadata_dir.is_dir():
        response["metadata_dir_available"] = False
        response["warnings"].append("3D metadata path is not a directory.")
        return response

    response["metadata_dir_available"] = True
    for metadata_path in _iter_metadata_files(root, metadata_dir, response["warnings"]):
        card, errors = _card_from_metadata_file(root, metadata_path)
        if errors:
            response["invalid_count"] += 1
            response["warnings"].append(f"{_safe_relative(root, metadata_path)}: {'; '.join(errors)}")
            continue
        if card is not None:
            response["cards"].append(card)

    response["card_count"] = len(response["cards"])
    return response


def _base_response(root: Path) -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "gateway-3d-output-cards",
        "runtime_root": str(root),
        "metadata_dir_available": False,
        "card_count": 0,
        "invalid_count": 0,
        "cards": [],
        "warnings": [],
        "safety_flags": {
            "read_only": True,
            "generation_triggered": False,
            "runtime_assets_written": False,
            "source_assets_modified": False,
            "shell_execution": False,
        },
    }


def _iter_metadata_files(root: Path, metadata_dir: Path, warnings: list[str]) -> list[Path]:
    results: list[Path] = []
    try:
        for path in sorted(metadata_dir.rglob("*")):
            if path.is_symlink():
                warnings.append(f"{_safe_relative(root, path)}: symlink skipped")
                continue
            if not path.is_file():
                continue
            if path.suffix.lower() != ".json":
                continue
            if _has_hidden_part(path):
                warnings.append(f"{_safe_relative(root, path)}: hidden path skipped")
                continue
            if not _is_under_root(path, root):
                warnings.append(f"{_safe_relative(root, path)}: path outside runtime root skipped")
                continue
            results.append(path)
    except OSError as exc:
        warnings.append(f"3D metadata scan failed: {exc}")
    return results


def _card_from_metadata_file(root: Path, metadata_path: Path) -> tuple[dict[str, Any] | None, list[str]]:
    metadata_relative = _safe_relative(root, metadata_path)
    errors: list[str] = []

    try:
        if metadata_path.stat().st_size > MAX_METADATA_BYTES:
            return None, ["metadata sidecar is too large"]
        payload = json.loads(metadata_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None, ["metadata sidecar is malformed JSON"]
    except OSError as exc:
        return None, [f"metadata sidecar could not be read: {exc}"]

    if not isinstance(payload, dict):
        return None, ["metadata sidecar root must be an object"]

    verification_errors = _verify_metadata(payload)
    errors.extend(verification_errors)

    output_files = payload.get("output_files")
    relative_runtime_paths = _empty_relative_runtime_paths()
    if isinstance(output_files, dict):
        for key in ALLOWED_OUTPUT_KEYS:
            value = output_files.get(key)
            relative_runtime_paths[key] = value if isinstance(value, str) else None
    relative_runtime_paths["metadata"] = metadata_relative

    if errors:
        return None, errors

    formats = [
        key
        for key in FORMAT_OUTPUT_KEYS
        if isinstance(relative_runtime_paths.get(key), str) and relative_runtime_paths[key]
    ]
    card = {
        "id": f"3d_model:{metadata_relative}",
        "type": "3d_model",
        "asset_name": payload.get("asset_name"),
        "asset_category": payload.get("asset_category"),
        "created_at": payload.get("created_at"),
        "formats": formats,
        "preview_available": False,
        "metadata_path": metadata_relative,
        "relative_runtime_paths": relative_runtime_paths,
        "safety_label": payload.get("safety_label"),
        "structural_certification": payload.get("structural_certification"),
        "operator_review_required": payload.get("operator_review_required"),
        "generation_mode": payload.get("generation_mode"),
        "verification": {
            "valid": True,
            "error_count": 0,
        },
    }
    return card, []


def _verify_metadata(metadata: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if metadata.get("asset_type") != "3d_model":
        errors.append("asset_type must be 3d_model")
    if metadata.get("source") != "blender_parametric":
        errors.append("source must be blender_parametric")
    if metadata.get("safety_label") != "visual_reference_only":
        errors.append("safety_label must be visual_reference_only")
    if metadata.get("structural_certification") is not False:
        errors.append("structural_certification must be false")
    if metadata.get("operator_review_required") is not True:
        errors.append("operator_review_required must be true")

    for key in ("asset_name", "asset_category", "created_at"):
        if not isinstance(metadata.get(key), str) or not metadata.get(key, "").strip():
            errors.append(f"{key} must be a non-empty string")

    output_files = metadata.get("output_files")
    if not isinstance(output_files, dict):
        errors.append("output_files must be an object")
        return errors

    for key, value in output_files.items():
        if key not in ALLOWED_OUTPUT_KEYS:
            errors.append(f"output_files.{key} is not an allowed output key")
        if value is None:
            continue
        if not isinstance(value, str):
            errors.append(f"output_files.{key} must be null or a string")
            continue
        if not is_safe_runtime_relative_path(value):
            errors.append(f"output_files.{key} must be a safe runtime-relative path")
    return errors


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


def _empty_relative_runtime_paths() -> dict[str, str | None]:
    return {key: None for key in ALLOWED_OUTPUT_KEYS}


def _safe_relative(root: Path, path: Path) -> str:
    try:
        return path.resolve(strict=False).relative_to(root.resolve(strict=False)).as_posix()
    except (OSError, ValueError):
        return path.name


def _is_under_root(path: Path, root: Path) -> bool:
    try:
        path.resolve(strict=False).relative_to(root.resolve(strict=False))
        return True
    except (OSError, ValueError):
        return False


def _has_hidden_part(path: Path) -> bool:
    return any(part.startswith(".") for part in path.parts)
