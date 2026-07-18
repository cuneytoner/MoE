"""Shared path constants for read-only animation validation."""

from __future__ import annotations

from pathlib import Path


SOURCE_REPO_ROOT = Path("/home/cuneyt/DiskD/Projects/MoE/codebase")
DEPLOYED_REPO_ROOT = Path("/home/cuneyt/MoE/codebase")
CONTAINER_WORKSPACE_ROOT = Path("/workspace")
MODEL_BACKUP_ROOT = Path("/home/cuneyt/MoE_Models_Backup")

DEFAULT_RUNTIME_ROOT = Path("/home/cuneyt/MoE/runtime")
ANIMATION_ROOT_REL = Path("media/animation")
METADATA_ROOT_REL = ANIMATION_ROOT_REL / "metadata"
PREVIEW_ROOT_REL = ANIMATION_ROOT_REL / "previews"
REPORT_ROOT_REL = ANIMATION_ROOT_REL / "reports"
