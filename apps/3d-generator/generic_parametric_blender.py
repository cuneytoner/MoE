#!/usr/bin/env python3
"""Dry-run skeleton for future generic parametric Blender generation.

This module intentionally does not import bpy at module import time. It can run
with normal Python and only emits plans for future guarded Blender execution.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any


RUNTIME_OUTPUT_ROOT = Path("/home/cuneyt/MoE/runtime/media/outputs/3d")
REPO_ROOT = Path(__file__).resolve().parents[2]
CONFIG_ROOT = REPO_ROOT / "configs" / "3d"
PLANNED_PRIMITIVES = [
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
METADATA_PLAN = {
    "schema_version": "1.0",
    "asset_type": "3d_model",
    "source": "blender_parametric",
    "safety_label": "visual_reference_only",
    "structural_certification": False,
}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Dry-run generic parametric Blender generation skeleton.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print a human-readable dry-run plan. This is the default.",
    )
    parser.add_argument(
        "--plan-json",
        action="store_true",
        help="Print the dry-run generation plan as JSON only.",
    )
    parser.add_argument(
        "--output-root",
        default=str(RUNTIME_OUTPUT_ROOT),
        help="Planned runtime output root. Must stay under the approved 3D runtime root.",
    )
    parser.add_argument(
        "--config",
        help="Optional source-only JSON parameter config to validate and include in the plan.",
    )
    return parser


def resolve_config_path(raw_config_path: str) -> Path:
    config_path = Path(raw_config_path).expanduser()
    if ".." in config_path.parts:
        raise ValueError("config path must not contain path traversal")
    if config_path.suffix.lower() != ".json":
        raise ValueError("config path must use .json extension")
    candidate = config_path if config_path.is_absolute() else REPO_ROOT / config_path
    if not candidate.exists():
        raise ValueError(f"config file does not exist: {config_path}")
    if not candidate.is_file():
        raise ValueError(f"config path is not a file: {config_path}")

    resolved = candidate.resolve(strict=True)
    allowed = CONFIG_ROOT.resolve(strict=True)
    if resolved != allowed and allowed not in resolved.parents:
        raise ValueError(f"config path must stay under {allowed}")
    return resolved


def resolve_output_root(raw_output_root: str) -> Path:
    output_root = Path(raw_output_root).expanduser()
    if not output_root.is_absolute():
        raise ValueError("output root must be absolute")
    if ".." in output_root.parts:
        raise ValueError("output root must not contain path traversal")

    resolved = output_root.resolve(strict=False)
    allowed = RUNTIME_OUTPUT_ROOT.resolve(strict=False)
    if resolved != allowed and allowed not in resolved.parents:
        raise ValueError(f"output root must stay under {allowed}")
    return resolved


def generation_enabled() -> bool:
    return os.environ.get("REAL_3D_GENERATION", "0") == "1"


def require_mapping(value: object, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    return value


def require_non_empty_string(value: object, label: str) -> str:
    if not isinstance(value, str) or value.strip() == "":
        raise ValueError(f"{label} must be a non-empty string")
    return value


def validate_positive_dimensions(dimensions: object, label: str) -> None:
    data = require_mapping(dimensions, label)
    for key, value in data.items():
        if key.endswith("_mm") or key in {"slope_degrees", "slope_mm"}:
            if not isinstance(value, (int, float)) or isinstance(value, bool) or value <= 0:
                raise ValueError(f"{label}.{key} must be positive")


def load_config(raw_config_path: str) -> dict[str, Any]:
    config_path = resolve_config_path(raw_config_path)
    try:
        payload = json.loads(config_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"config JSON is malformed: {exc.msg}") from exc

    config = require_mapping(payload, "config")
    require_non_empty_string(config.get("schema_version"), "schema_version")
    if config.get("safety_label") != "visual_reference_only":
        raise ValueError("safety_label must be visual_reference_only")
    if config.get("structural_certification") is not False:
        raise ValueError("structural_certification must be false")

    output_plan = require_mapping(config.get("output_plan"), "output_plan")
    if output_plan.get("runtime_output_root") != str(RUNTIME_OUTPUT_ROOT):
        raise ValueError(f"output_plan.runtime_output_root must be {RUNTIME_OUTPUT_ROOT}")

    validate_positive_dimensions(config.get("dimensions"), "dimensions")

    components = config.get("components")
    if not isinstance(components, list) or len(components) == 0:
        raise ValueError("components must be a non-empty list")

    seen_component_ids: set[str] = set()
    for index, component in enumerate(components):
        item = require_mapping(component, f"components[{index}]")
        component_id = require_non_empty_string(item.get("component_id"), f"components[{index}].component_id")
        if component_id in seen_component_ids:
            raise ValueError(f"duplicate component_id: {component_id}")
        seen_component_ids.add(component_id)

        component_type = require_non_empty_string(item.get("component_type"), f"components[{index}].component_type")
        if component_type not in PLANNED_PRIMITIVES:
            raise ValueError(f"unsupported component_type: {component_type}")
        validate_positive_dimensions(item.get("dimensions"), f"components[{index}].dimensions")

    return {
        "path": str(config_path),
        "payload": config,
        "summary": {
            "asset_name": require_non_empty_string(config.get("asset_name"), "asset_name"),
            "asset_category": require_non_empty_string(config.get("asset_category"), "asset_category"),
            "component_count": len(components),
            "units": require_non_empty_string(config.get("units"), "units"),
        },
    }


def build_plan(output_root: Path, config_info: dict[str, Any] | None = None) -> dict[str, Any]:
    real_generation_enabled = generation_enabled()
    return {
        "status": "planned",
        "message": (
            "dry-run only; real generation not implemented yet"
            if not real_generation_enabled
            else "REAL_3D_GENERATION=1 requested, but real generation is not implemented yet"
        ),
        "runtime_output_root": str(output_root),
        "config_loaded": config_info is not None,
        "config_path": config_info["path"] if config_info else None,
        "config_summary": config_info["summary"] if config_info else None,
        "planned_output_subfolders": [
            "blender",
            "glb",
            "obj",
            "previews",
            "metadata",
            "reports",
        ],
        "planned_primitive_builders": PLANNED_PRIMITIVES,
        "metadata_plan": METADATA_PLAN,
        "safety_flags": {
            "dry_run": True,
            "real_generation_requested": real_generation_enabled,
            "real_generation_enabled": real_generation_enabled,
            "blender_execution_attempted": False,
            "runtime_assets_written": False,
            "source_assets_modified": False,
            "generation_triggered": False,
        },
    }


def print_dry_run_summary(plan: dict[str, Any]) -> None:
    safety_flags = plan["safety_flags"]
    print("Generic parametric Blender skeleton dry-run")
    print(f"Runtime output root: {plan['runtime_output_root']}")
    print("Blender execution attempted: false")
    print("Runtime assets written: false")
    print("Generation triggered: false")
    if plan["config_loaded"]:
        print(f"Config path: {plan['config_path']}")
        print(f"Asset name: {plan['config_summary']['asset_name']}")
    print(f"REAL_3D_GENERATION requested: {str(safety_flags['real_generation_requested']).lower()}")
    print(plan["message"])
    print("Planned primitive builders:")
    for primitive in plan["planned_primitive_builders"]:
        print(f"- {primitive}")


def run(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        output_root = resolve_output_root(args.output_root)
        config_info = load_config(args.config) if args.config else None
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    plan = build_plan(output_root, config_info)
    if args.plan_json:
        print(json.dumps(plan, indent=2, sort_keys=True))
        return 0

    print_dry_run_summary(plan)
    return 0


def main() -> int:
    return run()


if __name__ == "__main__":
    raise SystemExit(main())
