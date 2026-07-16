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
    return parser


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


def build_plan(output_root: Path) -> dict[str, Any]:
    real_generation_enabled = generation_enabled()
    return {
        "status": "planned",
        "message": (
            "dry-run only; real generation not implemented yet"
            if not real_generation_enabled
            else "REAL_3D_GENERATION=1 requested, but real generation is not implemented yet"
        ),
        "runtime_output_root": str(output_root),
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
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    plan = build_plan(output_root)
    if args.plan_json:
        print(json.dumps(plan, indent=2, sort_keys=True))
        return 0

    print_dry_run_summary(plan)
    return 0


def main() -> int:
    return run()


if __name__ == "__main__":
    raise SystemExit(main())
