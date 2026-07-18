#!/usr/bin/env python3
"""Compatibility wrapper for shared animation metadata validation."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True


def _add_shared_package_path() -> None:
    candidates = (
        Path.cwd() / "packages" / "animation-validation",
        Path("/home/cuneyt/DiskD/Projects/MoE/codebase/packages/animation-validation"),
        Path("/home/cuneyt/MoE/codebase/packages/animation-validation"),
        Path("/workspace/packages/animation-validation"),
        Path("/app/packages/animation-validation"),
    )
    for candidate in candidates:
        if candidate.is_dir():
            sys.path.insert(0, str(candidate))
            return


_add_shared_package_path()

from animation_validation.metadata import (  # noqa: E402
    MetadataValidationIssue,
    build_animation_metadata_validation_report,
    load_animation_metadata,
    load_animation_metadata_schema,
    validate_animation_metadata,
    validate_animation_metadata_provenance,
    validate_animation_metadata_semantics,
    validate_animation_metadata_structure,
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Validate an animation metadata sidecar without writing files.")
    parser.add_argument("--metadata", required=True, help="Metadata JSON under configs/animation or /tmp.")
    parser.add_argument("--adapter-request", help="Optional adapter request JSON for full provenance validation.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON validation report.")
    return parser


def run(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    report, exit_code = validate_animation_metadata(args.metadata, adapter_request_path=args.adapter_request)
    print(json.dumps(report, indent=2 if args.pretty else None, sort_keys=True))
    return exit_code


__all__ = [
    "Any",
    "MetadataValidationIssue",
    "build_animation_metadata_validation_report",
    "load_animation_metadata",
    "load_animation_metadata_schema",
    "validate_animation_metadata",
    "validate_animation_metadata_provenance",
    "validate_animation_metadata_semantics",
    "validate_animation_metadata_structure",
]


if __name__ == "__main__":
    raise SystemExit(run())
