from __future__ import annotations

import json
import string
from pathlib import Path
from typing import Any


DEFAULT_RUNTIME_3D_ROOT = Path("/home/cuneyt/MoE/runtime/media/outputs/3d")
RUNTIME_SCOPE = "runtime/media/outputs/3d"
METADATA_SUBDIR = "metadata"
MODEL_BACKUP_ROOT = Path("/home/cuneyt/MoE_Models_Backup")
REPO_ROOT = Path(__file__).resolve().parents[3]
ALLOWED_OUTPUT_KEYS = ("blend", "glb", "obj", "preview", "metadata", "report")
FORMAT_OUTPUT_KEYS = ("blend", "glb", "obj")
PREVIEW_EXTENSIONS = (".png", ".jpg", ".jpeg", ".webp")
MAX_METADATA_BYTES = 128 * 1024
MAX_SIDECARS = 200
PATH_POLICY: dict[str, tuple[str, tuple[str, ...]]] = {
    "blend": ("blender", (".blend",)),
    "glb": ("glb", (".glb",)),
    "obj": ("obj", (".obj",)),
    "preview": ("previews", PREVIEW_EXTENSIONS),
    "metadata": ("metadata", (".json",)),
    "report": ("reports", (".json",)),
}


def build_3d_output_cards() -> dict[str, Any]:
    return _build_3d_output_cards_from_root(DEFAULT_RUNTIME_3D_ROOT)


def _build_3d_output_cards_from_root(runtime_root: str | Path) -> dict[str, Any]:
    root = Path(runtime_root).expanduser()
    response = _base_response()

    root_error = _runtime_root_error(root)
    if root_error is not None:
        response["metadata_dir_available"] = False
        response["warnings"].append(root_error)
        return response

    metadata_dir = root / METADATA_SUBDIR
    metadata_dir_error = _metadata_dir_error(root, metadata_dir)
    if metadata_dir_error is not None:
        response["metadata_dir_available"] = False
        response["warnings"].append(metadata_dir_error)
        return response

    response["metadata_dir_available"] = True
    for metadata_path in _iter_metadata_files(metadata_dir, response["warnings"]):
        card, errors = _card_from_metadata_file(root, metadata_path)
        if errors:
            response["invalid_count"] += 1
            response["warnings"].append(f"{_metadata_warning_label(metadata_path)}: {'; '.join(errors)}")
            continue
        if card is not None:
            response["cards"].append(card)

    response["card_count"] = len(response["cards"])
    return response


def _base_response() -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "gateway-3d-output-cards",
        "runtime_scope": RUNTIME_SCOPE,
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


def _runtime_root_error(root: Path) -> str | None:
    if not root.is_absolute():
        return "3D runtime root is not absolute."
    if _path_has_unsafe_parts(root):
        return "3D runtime root contains unsafe path segments."
    if _is_repo_or_model_backup_path(root):
        return "3D runtime root is outside the approved runtime scope."
    try:
        if root.exists() and root.is_symlink():
            return "3D runtime root is a symlink and was not scanned."
        if root.exists() and not root.is_dir():
            return "3D runtime root is not a directory."
        if root.exists() and not _is_under_root(root, root):
            return "3D runtime root could not be resolved safely."
    except OSError:
        return "3D runtime root could not be inspected."
    return None


def _metadata_dir_error(root: Path, metadata_dir: Path) -> str | None:
    try:
        if not metadata_dir.exists():
            return "3D metadata directory is not available."
        if metadata_dir.is_symlink():
            return "3D metadata directory is a symlink and was not scanned."
        if not metadata_dir.is_dir():
            return "3D metadata path is not a directory."
        if not _is_under_root(metadata_dir, root):
            return "3D metadata directory resolved outside runtime scope."
    except OSError:
        return "3D metadata directory could not be inspected."
    return None


def _iter_metadata_files(metadata_dir: Path, warnings: list[str]) -> list[Path]:
    results: list[Path] = []
    try:
        entries = sorted(metadata_dir.iterdir(), key=lambda item: item.name)
    except OSError:
        warnings.append("3D metadata scan failed.")
        return results

    json_seen = 0
    for path in entries:
        label = _metadata_warning_label(path)
        try:
            if path.is_symlink():
                warnings.append(f"{label}: symlink skipped")
                continue
            if path.is_dir():
                warnings.append(f"{label}: nested directory skipped")
                continue
            if not path.is_file():
                continue
            if _has_hidden_part(path):
                warnings.append(f"{label}: hidden path skipped")
                continue
            if path.suffix.lower() != ".json":
                continue
            json_seen += 1
            if json_seen > MAX_SIDECARS:
                warnings.append("3D metadata sidecar limit reached; remaining sidecars skipped.")
                break
            results.append(path)
        except OSError:
            warnings.append(f"{label}: metadata entry could not be inspected")
    return results


def _card_from_metadata_file(root: Path, metadata_path: Path) -> tuple[dict[str, Any] | None, list[str]]:
    metadata_relative = _metadata_relative_path(root, metadata_path)
    errors: list[str] = []

    if metadata_path.is_symlink():
        return None, ["metadata sidecar is a symlink"]
    if metadata_relative is None:
        return None, ["metadata sidecar resolved outside runtime scope"]

    try:
        if metadata_path.stat().st_size > MAX_METADATA_BYTES:
            return None, ["metadata sidecar is too large"]
        payload = json.loads(metadata_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None, ["metadata sidecar is malformed JSON"]
    except (UnicodeDecodeError, UnicodeError):
        return None, ["metadata sidecar is not valid UTF-8"]
    except (OSError, ValueError, RecursionError):
        return None, ["metadata sidecar could not be read"]

    if not isinstance(payload, dict):
        return None, ["metadata sidecar root must be an object"]

    metadata_errors = _verify_metadata(payload)
    if metadata_errors:
        return None, metadata_errors

    output_files = payload["output_files"]
    relative_runtime_paths = _empty_relative_runtime_paths()
    artifact_errors: list[str] = []
    declared_count = 0
    existing_count = 0
    formats: list[str] = []
    preview_available = False

    for key in ALLOWED_OUTPUT_KEYS:
        value = output_files.get(key)
        if value is None:
            continue
        relative_runtime_paths[key] = value
        declared_count += 1
        artifact_path = root / value
        artifact_error = _artifact_error(root, artifact_path)
        if artifact_error is not None:
            artifact_errors.append(f"declared {key} artifact {artifact_error}")
            continue
        existing_count += 1
        if key in FORMAT_OUTPUT_KEYS:
            formats.append(key)
        if key == "preview":
            preview_available = True

    relative_runtime_paths["metadata"] = metadata_relative
    if output_files.get("metadata") is None:
        declared_count += 1
        existing_count += 1

    missing_count = len(artifact_errors)
    verification = {
        "metadata_valid": True,
        "artifacts_valid": len(artifact_errors) == 0,
        "valid": len(artifact_errors) == 0,
        "declared_count": declared_count,
        "existing_count": existing_count,
        "missing_count": missing_count,
        "error_count": len(artifact_errors),
        "errors": artifact_errors,
    }

    card = {
        "id": f"3d_model:{metadata_relative}",
        "type": "3d_model",
        "asset_name": payload["asset_name"],
        "asset_category": payload["asset_category"],
        "created_at": payload["created_at"],
        "formats": formats,
        "preview_available": preview_available,
        "metadata_path": metadata_relative,
        "relative_runtime_paths": relative_runtime_paths,
        "safety_label": payload["safety_label"],
        "structural_certification": payload["structural_certification"],
        "operator_review_required": payload["operator_review_required"],
        "generation_mode": payload.get("generation_mode"),
        "verification": verification,
    }
    return card, errors


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
            continue
        if value is None:
            continue
        if not isinstance(value, str):
            errors.append(f"output_files.{key} must be null or a string")
            continue
        path_error = runtime_relative_path_error(key, value)
        if path_error is not None:
            errors.append(f"output_files.{key} {path_error}")
    return errors


def runtime_relative_path_error(key: str, value: str) -> str | None:
    if key not in PATH_POLICY:
        return "uses an unsupported output key"
    if not isinstance(value, str) or value == "":
        return "must be a non-empty runtime-relative path"
    if any(char == "\x00" or char in string.whitespace and char not in {" "} for char in value):
        return "contains a control character"
    if "\\" in value:
        return "must use POSIX separators"
    if value.startswith(("/", "./")):
        return "must not be absolute or dot-relative"
    lowered = value.lower()
    if "://" in lowered or lowered.startswith("file:"):
        return "must not be a URL"
    if len(value) >= 2 and value[1] == ":":
        return "must not contain a drive prefix"
    if value.startswith("//"):
        return "must not be a network path"

    parts = value.split("/")
    if any(part in {"", ".", ".."} for part in parts):
        return "contains an unsafe path segment"
    if any(part.startswith(".") for part in parts):
        return "contains a hidden path segment"
    if len(parts) != 2:
        return "must use exactly one allowlisted subdirectory and filename"

    directory, filename = parts
    expected_directory, extensions = PATH_POLICY[key]
    if directory != expected_directory:
        return f"must be under {expected_directory}/"
    if not filename.lower().endswith(extensions):
        return f"must use one of {', '.join(extensions)}"
    return None


def _artifact_error(root: Path, artifact_path: Path) -> str | None:
    try:
        resolved = artifact_path.resolve(strict=False)
        if not _is_under_root(resolved, root):
            return "resolved outside runtime scope"
        if artifact_path.is_symlink():
            return "is a symlink"
        if not artifact_path.is_file():
            return "is missing"
    except OSError:
        return "could not be inspected"
    return None


def _empty_relative_runtime_paths() -> dict[str, str | None]:
    return {key: None for key in ALLOWED_OUTPUT_KEYS}


def _metadata_relative_path(root: Path, path: Path) -> str | None:
    try:
        relative = path.resolve(strict=False).relative_to(root.resolve(strict=False)).as_posix()
    except (OSError, ValueError):
        return None
    if runtime_relative_path_error("metadata", relative) is not None:
        return None
    return relative


def _metadata_warning_label(path: Path) -> str:
    return f"metadata entry {path.name}"


def _is_under_root(path: Path, root: Path) -> bool:
    try:
        path.resolve(strict=False).relative_to(root.resolve(strict=False))
        return True
    except (OSError, ValueError):
        return False


def _is_repo_or_model_backup_path(path: Path) -> bool:
    try:
        resolved = path.resolve(strict=False)
        repo = REPO_ROOT.resolve(strict=False)
        model_backup = MODEL_BACKUP_ROOT.resolve(strict=False)
        return (
            resolved == repo
            or repo in resolved.parents
            or resolved == model_backup
            or model_backup in resolved.parents
        )
    except OSError:
        return True


def _path_has_unsafe_parts(path: Path) -> bool:
    return any(part in {"", ".", ".."} for part in path.parts)


def _has_hidden_part(path: Path) -> bool:
    return any(part.startswith(".") for part in path.parts)
