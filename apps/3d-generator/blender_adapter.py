"""Blender operation planning for generic 3D scene plans.

This module is intentionally importable without Blender. Do not import bpy at
module import time.
"""

from __future__ import annotations

import re
from typing import Any


SUPPORTED_BLENDER_OPERATIONS = [
    "create_cube",
    "create_cylinder",
    "create_plane",
    "create_empty",
    "assign_material_label",
    "set_transform",
    "set_custom_property",
]

PRIMITIVE_OPERATION_MAP = {
    "rectangular_prism": "create_cube",
    "cylinder": "create_cylinder",
    "plane": "create_plane",
    "sloped_plane": "create_plane",
    "frame": "create_cube",
    "panel": "create_cube",
    "connector_placeholder": "create_empty",
    "guide_line": "create_empty",
    "label_anchor": "create_empty",
}


def sanitize_object_name(value: object) -> str:
    raw_value = value if isinstance(value, str) else ""
    sanitized = re.sub(r"[^A-Za-z0-9_-]+", "_", raw_value.strip())
    sanitized = sanitized.strip("_")
    if not sanitized:
        return "object_unnamed"
    if not re.match(r"^[A-Za-z0-9_-]+$", sanitized):
        return f"object_{sanitized}"
    return sanitized


def build_operation_for_primitive(primitive: dict[str, Any]) -> tuple[dict[str, Any] | None, list[str]]:
    primitive_id = primitive.get("primitive_id")
    primitive_type = primitive.get("primitive_type")
    errors: list[str] = []

    if not isinstance(primitive_id, str) or primitive_id.strip() == "":
        errors.append("primitive_id must be a non-empty string")
    if not isinstance(primitive_type, str) or primitive_type.strip() == "":
        errors.append("primitive_type must be a non-empty string")
    elif primitive_type not in PRIMITIVE_OPERATION_MAP:
        errors.append(f"unsupported primitive_type: {primitive_type}")

    if errors:
        return None, errors

    operation_type = PRIMITIVE_OPERATION_MAP[primitive_type]
    operation_id = sanitize_object_name(f"{operation_type}_{primitive_id}")
    custom_properties = {
        "source_primitive_id": primitive_id,
        "generation_status": "planned_only",
    }
    if primitive_type == "sloped_plane":
        custom_properties["adapter_note"] = "sloped_plane uses create_plane with slope metadata"
    if primitive_type in {"frame", "panel"}:
        custom_properties["adapter_note"] = f"{primitive_type} uses create_cube placeholder"

    return {
        "operation_id": operation_id,
        "operation_type": operation_type,
        "primitive_id": primitive_id,
        "primitive_type": primitive_type,
        "object_name": sanitize_object_name(primitive_id),
        "position": primitive.get("position", {}),
        "rotation": primitive.get("rotation", {}),
        "dimensions": primitive.get("dimensions", {}),
        "material_label": primitive.get("material_label"),
        "custom_properties": custom_properties,
    }, []


def build_blender_operation_plan(scene_plan: dict[str, Any]) -> tuple[dict[str, Any] | None, list[str]]:
    errors: list[str] = []
    if scene_plan.get("plan_type") != "generic_3d_scene_plan":
        errors.append("scene_plan.plan_type must be generic_3d_scene_plan")

    primitives = scene_plan.get("primitives")
    if not isinstance(primitives, list):
        errors.append("scene_plan.primitives must be a list")
        primitives = []

    operations: list[dict[str, Any]] = []
    seen_operation_ids: set[str] = set()
    for index, primitive in enumerate(primitives):
        if not isinstance(primitive, dict):
            errors.append(f"primitives[{index}] must be an object")
            continue
        operation, operation_errors = build_operation_for_primitive(primitive)
        errors.extend(f"primitives[{index}].{error}" for error in operation_errors)
        if operation is None:
            continue
        operation_id = operation["operation_id"]
        if operation_id in seen_operation_ids:
            errors.append(f"duplicate operation_id: {operation_id}")
            continue
        seen_operation_ids.add(operation_id)
        operations.append(operation)

    if errors:
        return None, errors

    operation_types = sorted({operation["operation_type"] for operation in operations})
    return {
        "schema_version": "1.0",
        "plan_type": "blender_operation_plan",
        "asset_name": scene_plan.get("asset_name"),
        "asset_category": scene_plan.get("asset_category"),
        "operation_count": len(operations),
        "operation_types": operation_types,
        "operations": operations,
        "safety_flags": {
            "bpy_imported": False,
            "blender_execution_attempted": False,
            "runtime_assets_written": False,
            "generation_triggered": False,
            "source_assets_modified": False,
        },
    }, []


def execute_blender_operation_plan(operation_plan: dict[str, Any]) -> dict[str, Any]:
    try:
        import bpy  # type: ignore[import-not-found]  # noqa: PLC0415,F401
    except ImportError as exc:
        raise RuntimeError("Blender execution requires running inside Blender") from exc

    raise RuntimeError("Blender execution is not enabled in this milestone")
