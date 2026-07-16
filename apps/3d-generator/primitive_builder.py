"""Blender-independent primitive planning for generic 3D configs."""

from __future__ import annotations

import math
from typing import Any


SUPPORTED_PRIMITIVE_TYPES = [
    "rectangular_prism",
    "cylinder",
    "plane",
    "sloped_plane",
    "frame",
    "panel",
    "connector_placeholder",
    "guide_line",
    "label_anchor",
]

VECTOR_FIELDS = {
    "mm": ("x_mm", "y_mm", "z_mm"),
    "deg": ("x_deg", "y_deg", "z_deg"),
}

REQUIRED_DIMENSIONS = {
    "rectangular_prism": ("width_mm", "depth_mm", "height_mm"),
    "cylinder": ("radius_mm", "height_mm"),
    "plane": ("width_mm", "depth_mm"),
    "sloped_plane": ("width_mm", "depth_mm"),
    "frame": ("width_mm", "height_mm"),
    "panel": ("width_mm", "height_mm"),
}

OPTIONAL_POSITIVE_DIMENSIONS = ("depth_mm", "thickness_mm")


def is_finite_number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def normalize_vector3(value: dict[str, Any], suffix: str) -> dict[str, float]:
    fields = VECTOR_FIELDS.get(suffix)
    if fields is None:
        raise ValueError(f"unsupported vector suffix: {suffix}")
    normalized: dict[str, float] = {}
    for field in fields:
        raw_value = value.get(field, 0)
        if not is_finite_number(raw_value):
            raise ValueError(f"{field} must be a finite number")
        normalized[field] = raw_value
    return normalized


def validate_positive_dimension(value: object, field_name: str) -> list[str]:
    if not is_finite_number(value):
        return [f"{field_name} must be a finite number"]
    if value <= 0:
        return [f"{field_name} must be positive"]
    return []


def validate_dimensions(component_type: str, dimensions: object) -> list[str]:
    errors: list[str] = []
    if dimensions is None:
        dimensions = {}
    if not isinstance(dimensions, dict):
        return ["dimensions must be an object"]

    for field in REQUIRED_DIMENSIONS.get(component_type, ()):
        if field not in dimensions:
            errors.append(f"dimensions.{field} is required for {component_type}")
            continue
        errors.extend(validate_positive_dimension(dimensions.get(field), f"dimensions.{field}"))

    if component_type == "sloped_plane" and "slope_degrees" not in dimensions and "slope_mm" not in dimensions:
        errors.append("dimensions.slope_degrees or dimensions.slope_mm is required for sloped_plane")

    for field, value in dimensions.items():
        if field.endswith("_mm") or field in {"slope_degrees", "slope_mm"}:
            errors.extend(validate_positive_dimension(value, f"dimensions.{field}"))
        elif field in OPTIONAL_POSITIVE_DIMENSIONS:
            errors.extend(validate_positive_dimension(value, f"dimensions.{field}"))
        elif not is_finite_number(value):
            errors.append(f"dimensions.{field} must be a finite number")
    return errors


def build_primitive_plan(component: dict[str, Any]) -> tuple[dict[str, Any] | None, list[str]]:
    errors: list[str] = []

    component_id = component.get("component_id")
    if not isinstance(component_id, str) or component_id.strip() == "":
        errors.append("component_id must be a non-empty string")

    component_type = component.get("component_type")
    if not isinstance(component_type, str) or component_type.strip() == "":
        errors.append("component_type must be a non-empty string")
    elif component_type not in SUPPORTED_PRIMITIVE_TYPES:
        errors.append(f"unsupported component_type: {component_type}")

    position_raw = component.get("position", {})
    rotation_raw = component.get("rotation", {})
    if not isinstance(position_raw, dict):
        errors.append("position must be an object")
        position = {"x_mm": 0, "y_mm": 0, "z_mm": 0}
    else:
        try:
            position = normalize_vector3(position_raw, "mm")
        except ValueError as exc:
            errors.append(str(exc))
            position = {"x_mm": 0, "y_mm": 0, "z_mm": 0}

    if not isinstance(rotation_raw, dict):
        errors.append("rotation must be an object")
        rotation = {"x_deg": 0, "y_deg": 0, "z_deg": 0}
    else:
        try:
            rotation = normalize_vector3(rotation_raw, "deg")
        except ValueError as exc:
            errors.append(str(exc))
            rotation = {"x_deg": 0, "y_deg": 0, "z_deg": 0}

    dimensions = component.get("dimensions", {})
    if isinstance(component_type, str):
        errors.extend(validate_dimensions(component_type, dimensions))

    if errors:
        return None, errors

    metadata = component.get("metadata", {})
    if not isinstance(metadata, dict):
        metadata = {}

    return {
        "primitive_id": component_id,
        "primitive_type": component_type,
        "label": component.get("label", component_id),
        "position": position,
        "rotation": rotation,
        "dimensions": dict(dimensions) if isinstance(dimensions, dict) else {},
        "material_label": component.get("material_label"),
        "metadata": metadata,
        "generation_status": "planned_only",
    }, []


def build_scene_plan(config: dict[str, Any]) -> tuple[dict[str, Any] | None, list[str]]:
    errors: list[str] = []
    components = config.get("components")
    if not isinstance(components, list):
        return None, ["components must be a list"]

    seen_ids: set[str] = set()
    primitives: list[dict[str, Any]] = []
    for index, component in enumerate(components):
        if not isinstance(component, dict):
            errors.append(f"components[{index}] must be an object")
            continue
        component_id = component.get("component_id")
        if isinstance(component_id, str):
            if component_id in seen_ids:
                errors.append(f"duplicate component_id: {component_id}")
            seen_ids.add(component_id)
        primitive, primitive_errors = build_primitive_plan(component)
        errors.extend(f"components[{index}].{error}" for error in primitive_errors)
        if primitive is not None:
            primitives.append(primitive)

    if errors:
        return None, errors

    primitive_types = sorted({primitive["primitive_type"] for primitive in primitives})
    return {
        "schema_version": "1.0",
        "plan_type": "generic_3d_scene_plan",
        "asset_name": config.get("asset_name"),
        "asset_category": config.get("asset_category"),
        "units": config.get("units", "mm"),
        "coordinate_system": config.get("coordinate_system", {}),
        "primitive_count": len(primitives),
        "primitive_types": primitive_types,
        "primitives": primitives,
        "safety_flags": {
            "blender_required": False,
            "bpy_imported": False,
            "runtime_assets_written": False,
            "generation_triggered": False,
            "source_assets_modified": False,
        },
    }, []
