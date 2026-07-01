#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
IMPROVEMENT_PLAN_PATH="${IMPROVEMENT_PLAN_PATH:-${RUNTIME_DIR}/reports/improvement-plans/human-approved-improvement-plan.json}"
IMPROVEMENT_PATCH_PLAN_PATH="${IMPROVEMENT_PATCH_PLAN_PATH:-${RUNTIME_DIR}/reports/patch-plans/reviewed-improvement-patch-plan.json}"
SCRIPT="$ROOT/scripts/improvement-patch-plan-local.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$SCRIPT" ] || fail "missing script: $SCRIPT"
[ -x "$SCRIPT" ] || fail "script is not executable: $SCRIPT"
pass "improvement patch plan script exists and is executable"

if [ ! -f "$IMPROVEMENT_PLAN_PATH" ]; then
  mkdir -p "$(dirname "$IMPROVEMENT_PLAN_PATH")"
  cat > "$IMPROVEMENT_PLAN_PATH" <<'JSON'
{
  "apply_supported": false,
  "generated_at": "2026-01-01T00:00:00Z",
  "human_review_required": true,
  "next_steps": [
    "Review proposed changes manually."
  ],
  "plan_status": "review_required",
  "proposed_changes": [
    {
      "apply_supported": false,
      "category": "router",
      "human_approval_required": true,
      "id": "change-001",
      "rationale": "One router intent dominates aggregate feedback.",
      "risk": "medium",
      "target_files": [
        "configs/model-routing.yaml"
      ],
      "title": "Review router examples"
    },
    {
      "apply_supported": false,
      "category": "tests",
      "human_approval_required": true,
      "id": "change-002",
      "rationale": "Repeated feedback themes need regression coverage.",
      "risk": "low",
      "target_files": [
        "scripts/test-gateway-feedback.sh"
      ],
      "title": "Add focused feedback tests"
    }
  ],
  "safety_boundaries": [
    "no automatic file edits"
  ],
  "service": "human-approved-improvement-plan",
  "source_record_count": 3,
  "source_report_path": "/home/cuneyt/MoE/runtime/reports/learning-loop/learning-loop-report.json",
  "validation_plan": [
    "make check-layout",
    "make check-python-syntax",
    "make test"
  ]
}
JSON
  pass "created minimal runtime human-approved improvement plan"
else
  pass "using existing runtime human-approved improvement plan"
fi

make -C "$ROOT" improvement-patch-plan-local

[ -f "$IMPROVEMENT_PATCH_PLAN_PATH" ] || fail "missing improvement patch plan: $IMPROVEMENT_PATCH_PLAN_PATH"
pass "improvement patch plan exists under runtime"

python3 - "$ROOT" "$IMPROVEMENT_PATCH_PLAN_PATH" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
patch_plan_path = pathlib.Path(sys.argv[2]).resolve()
patch_plan = json.loads(patch_plan_path.read_text(encoding="utf-8"))

def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")

if root in patch_plan_path.parents:
    fail(f"patch plan was written inside the repository: {patch_plan_path}")
if patch_plan.get("apply_supported") is not False:
    fail(f"apply_supported must be false: {patch_plan}")
if patch_plan.get("human_review_required") is not True:
    fail(f"human_review_required must be true: {patch_plan}")
if patch_plan.get("patch_plan_status") != "review_required":
    fail(f"patch_plan_status must be review_required: {patch_plan}")
if not isinstance(patch_plan.get("patch_groups"), list) or not patch_plan["patch_groups"]:
    fail(f"patch_groups must be a non-empty list: {patch_plan}")
for group in patch_plan["patch_groups"]:
    if group.get("apply_supported") is not False:
        fail(f"patch group apply_supported must be false: {group}")
    if group.get("human_approval_required") is not True:
        fail(f"patch group human_approval_required must be true: {group}")
for forbidden in ("prompt", "response", "records", "feedback_records"):
    if forbidden in patch_plan:
        fail(f"forbidden raw field present: {forbidden}")
serialized = json.dumps(patch_plan, sort_keys=True).lower()
for forbidden_text in ("raw_prompt", "raw_response", "model_response", "prompt_text", "response_text"):
    if forbidden_text in serialized:
        fail(f"forbidden raw text marker present: {forbidden_text}")
print("PASS: improvement patch plan contract is safe")
PY

if find "$ROOT" -name "reviewed-improvement-patch-plan.json" -print -quit | grep -q .; then
  fail "reviewed-improvement-patch-plan.json was written inside the repository"
fi
pass "no improvement patch plan output was written into the repo"

echo "Improvement patch plan tests passed"
