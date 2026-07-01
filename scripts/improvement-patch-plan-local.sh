#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
IMPROVEMENT_PLAN_PATH="${IMPROVEMENT_PLAN_PATH:-${RUNTIME_DIR}/reports/improvement-plans/human-approved-improvement-plan.json}"
IMPROVEMENT_PATCH_PLAN_PATH="${IMPROVEMENT_PATCH_PLAN_PATH:-${RUNTIME_DIR}/reports/patch-plans/reviewed-improvement-patch-plan.json}"

export PYTHONDONTWRITEBYTECODE=1

if [ ! -f "$IMPROVEMENT_PLAN_PATH" ]; then
  echo "SKIP: Human-approved improvement plan is missing: $IMPROVEMENT_PLAN_PATH"
  echo "Run make improvement-plan-local before generating a reviewed improvement patch plan."
  exit 0
fi

python3 - "$ROOT" "$IMPROVEMENT_PLAN_PATH" "$IMPROVEMENT_PATCH_PLAN_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
plan_path = pathlib.Path(sys.argv[2])
patch_plan_path = pathlib.Path(sys.argv[3])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.improvement_patch_plan import (
    build_improvement_patch_plan,
    read_improvement_plan,
    write_improvement_patch_plan,
)

plan = read_improvement_plan(plan_path)
patch_plan = build_improvement_patch_plan(plan, source_plan_path=str(plan_path))
written = write_improvement_patch_plan(patch_plan_path, patch_plan)

print(f"PASS: Reviewed improvement patch plan written to {written}")
print(f"  source_plan_path: {patch_plan['source_plan_path']}")
print(f"  source_plan_status: {patch_plan['source_plan_status']}")
print(f"  patch_plan_status: {patch_plan['patch_plan_status']}")
print("  apply_supported: false")
print("  human_review_required: true")
PY
