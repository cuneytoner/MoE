#!/usr/bin/env python3
"""Compatibility wrapper for shared animation artifact verification."""

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

from animation_validation.artifacts import (  # noqa: E402
    ArtifactVerificationIssue,
    LoadedJson,
    build_animation_artifact_verification_report,
    load_animation_metadata_for_verification,
    load_preview_renderer_report,
    validate_preview_renderer_report,
    verify_animation_artifact_set,
    verify_preview_frame_set,
    verify_runtime_metadata_file,
)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Verify animation metadata and preview artifacts without writing files.")
    parser.add_argument("--metadata", required=True, help="Metadata JSON under configs/animation, /tmp, or runtime metadata root.")
    parser.add_argument("--adapter-request", help="Optional adapter request JSON under configs/animation or /tmp.")
    parser.add_argument("--preview-report", help="Optional preview renderer report JSON under /tmp or runtime reports root.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON verification report.")
    return parser


def run(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    report, exit_code = verify_animation_artifact_set(
        args.metadata,
        adapter_request_path=args.adapter_request,
        preview_report_path=args.preview_report,
    )
    print(json.dumps(report, indent=2 if args.pretty else None, sort_keys=True))
    return exit_code


__all__ = [
    "Any",
    "ArtifactVerificationIssue",
    "LoadedJson",
    "build_animation_artifact_verification_report",
    "load_animation_metadata_for_verification",
    "load_preview_renderer_report",
    "validate_preview_renderer_report",
    "verify_animation_artifact_set",
    "verify_preview_frame_set",
    "verify_runtime_metadata_file",
]


if __name__ == "__main__":
    raise SystemExit(run())
