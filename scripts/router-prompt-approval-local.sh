#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
IMPROVEMENT_PATCH_PLAN_PATH="${IMPROVEMENT_PATCH_PLAN_PATH:-${RUNTIME_DIR}/reports/patch-plans/reviewed-improvement-patch-plan.json}"
ROUTER_PROMPT_APPROVAL_PATH="${ROUTER_PROMPT_APPROVAL_PATH:-${RUNTIME_DIR}/reports/approvals/router-prompt-update-approval-packet.json}"

export PYTHONDONTWRITEBYTECODE=1

if [ ! -f "$IMPROVEMENT_PATCH_PLAN_PATH" ]; then
  echo "SKIP: Reviewed improvement patch plan is missing: $IMPROVEMENT_PATCH_PLAN_PATH"
  echo "Run make improvement-patch-plan-local before generating a router/prompt approval packet."
  exit 0
fi

python3 - "$ROOT" "$IMPROVEMENT_PATCH_PLAN_PATH" "$ROUTER_PROMPT_APPROVAL_PATH" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
patch_plan_path = pathlib.Path(sys.argv[2])
approval_path = pathlib.Path(sys.argv[3])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.router_prompt_approval import (
    build_router_prompt_approval_packet,
    read_patch_plan,
    write_router_prompt_approval_packet,
)

patch_plan = read_patch_plan(patch_plan_path)
packet = build_router_prompt_approval_packet(
    patch_plan,
    source_patch_plan_path=str(patch_plan_path),
)
written = write_router_prompt_approval_packet(approval_path, packet)

print(f"PASS: Router/prompt approval packet written to {written}")
print(f"  source_patch_plan_path: {packet['source_patch_plan_path']}")
print(f"  approval_status: {packet['approval_status']}")
print(f"  approval_items: {len(packet['approval_items'])}")
print(f"  blocked_items: {len(packet['blocked_items'])}")
print("  apply_supported: false")
print("  human_review_required: true")
PY
