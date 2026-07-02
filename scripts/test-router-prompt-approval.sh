#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
IMPROVEMENT_PATCH_PLAN_PATH="${IMPROVEMENT_PATCH_PLAN_PATH:-${RUNTIME_DIR}/reports/patch-plans/reviewed-improvement-patch-plan.json}"
ROUTER_PROMPT_APPROVAL_PATH="${ROUTER_PROMPT_APPROVAL_PATH:-${RUNTIME_DIR}/reports/approvals/router-prompt-update-approval-packet.json}"
SCRIPT="$ROOT/scripts/router-prompt-approval-local.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$SCRIPT" ] || fail "missing script: $SCRIPT"
[ -x "$SCRIPT" ] || fail "script is not executable: $SCRIPT"
pass "router/prompt approval script exists and is executable"

if [ ! -f "$IMPROVEMENT_PATCH_PLAN_PATH" ]; then
  mkdir -p "$(dirname "$IMPROVEMENT_PATCH_PLAN_PATH")"
  cat > "$IMPROVEMENT_PATCH_PLAN_PATH" <<'JSON'
{
  "apply_supported": false,
  "generated_at": "2026-01-01T00:00:00Z",
  "human_review_required": true,
  "patch_groups": [
    {
      "apply_supported": false,
      "category": "router",
      "expected_validation": [
        "make test-gateway-chat-router"
      ],
      "human_approval_required": true,
      "id": "patch-group-001",
      "proposed_patch_strategy": "Review router examples before any manual edit.",
      "rationale": "Router examples need review.",
      "risk": "medium",
      "target_files": [
        "configs/model-routing.yaml"
      ],
      "title": "Review router examples"
    },
    {
      "apply_supported": false,
      "category": "memory",
      "expected_validation": [
        "make test-gateway-memory-injection"
      ],
      "human_approval_required": true,
      "id": "patch-group-002",
      "proposed_patch_strategy": "Review candidate memory entries separately.",
      "rationale": "Memory candidates require a separate workflow.",
      "risk": "medium",
      "target_files": [
        "docs/memory-api.md"
      ],
      "title": "Review memory candidates"
    }
  ],
  "patch_plan_status": "review_required",
  "review_checklist": [
    "confirm target files are correct"
  ],
  "safety_boundaries": [
    "no automatic file edits"
  ],
  "service": "reviewed-improvement-patch-planner",
  "source_plan_path": "/home/cuneyt/MoE/runtime/reports/improvement-plans/human-approved-improvement-plan.json"
}
JSON
  pass "created minimal runtime reviewed improvement patch plan"
else
  pass "using existing runtime reviewed improvement patch plan"
fi

make -C "$ROOT" router-prompt-approval-local

[ -f "$ROUTER_PROMPT_APPROVAL_PATH" ] || fail "missing approval packet: $ROUTER_PROMPT_APPROVAL_PATH"
pass "approval packet exists under runtime"

python3 - "$ROOT" "$ROUTER_PROMPT_APPROVAL_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
packet_path = pathlib.Path(sys.argv[2]).resolve()
packet = json.loads(packet_path.read_text(encoding="utf-8"))

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in packet_path.parents:
    fail(f"approval packet was written inside the repository: {packet_path}")
if packet.get("apply_supported") is not False:
    fail(f"apply_supported must be false: {packet}")
if packet.get("human_review_required") is not True:
    fail(f"human_review_required must be true: {packet}")
if packet.get("approval_status") != "pending_human_review":
    fail(f"approval_status must be pending_human_review: {packet}")
if not isinstance(packet.get("approval_items"), list):
    fail(f"approval_items must be a list: {packet}")
if not isinstance(packet.get("blocked_items"), list):
    fail(f"blocked_items must be a list: {packet}")
for item in packet["approval_items"]:
    if item.get("apply_supported") is not False:
        fail(f"approval item apply_supported must be false: {item}")
    if item.get("approval_required") is not True:
        fail(f"approval item approval_required must be true: {item}")
for forbidden in ("prompt", "response", "records", "feedback_records"):
    if forbidden in packet:
        fail(f"forbidden raw field present: {forbidden}")
serialized = json.dumps(packet, sort_keys=True).lower()
for forbidden_text in ("raw_prompt", "raw_response", "model_response", "prompt_text", "response_text"):
    if forbidden_text in serialized:
        fail(f"forbidden raw text marker present: {forbidden_text}")
print("PASS: router/prompt approval packet contract is safe")
PY

if find "$ROOT" -name "router-prompt-update-approval-packet.json" -print -quit | grep -q .; then
  fail "router-prompt-update-approval-packet.json was written inside the repository"
fi
pass "no approval packet output was written into the repo"

echo "Router/prompt approval tests passed"
