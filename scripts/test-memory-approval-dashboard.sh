#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_PATH="$ROOT/apps/gateway-api/app/services/memory_approval_dashboard.py"
MAIN_PATH="$ROOT/apps/gateway-api/app/main.py"
UI_PANEL_PATH="$ROOT/apps/dashboard-ui/src/components/MemoryApprovalPanel.tsx"
UI_API_PATH="$ROOT/apps/dashboard-ui/src/api.ts"
UI_APP_PATH="$ROOT/apps/dashboard-ui/src/App.tsx"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

[ -f "$SERVICE_PATH" ] || fail "missing service: $SERVICE_PATH"
[ -f "$MAIN_PATH" ] || fail "missing Gateway main: $MAIN_PATH"
[ -f "$UI_PANEL_PATH" ] || fail "missing UI panel: $UI_PANEL_PATH"
pass "memory approval dashboard source files exist"

grep -q '"/gateway/memory-approval/dashboard"' "$MAIN_PATH" \
  || fail "Gateway route /gateway/memory-approval/dashboard is missing"
grep -q "build_memory_approval_dashboard" "$MAIN_PATH" \
  || fail "Gateway route does not call build_memory_approval_dashboard"
pass "Gateway endpoint code is present"

if grep -E "import subprocess|from subprocess|os\.system|subprocess\.|Popen|httpx|MemoryApi|memory/add|docker\.|exec\(" "$SERVICE_PATH"; then
  fail "memory approval dashboard service must not execute scripts or call external services"
fi
pass "Gateway endpoint service is read-only and file-based"

if grep -E "<Button|button|APPLY=1|approved-memory-candidates.json'|memory/add|fetch\\(.*memory" "$UI_PANEL_PATH"; then
  fail "Memory Approval UI must not expose control buttons or write-oriented calls"
fi
grep -q "Memory Approval" "$UI_PANEL_PATH" || fail "UI panel does not include Memory Approval section"
grep -q "/gateway/memory-approval/dashboard" "$UI_API_PATH" || fail "UI API does not use memory approval endpoint"
grep -q "MemoryApprovalPanel" "$UI_APP_PATH" || fail "App does not render MemoryApprovalPanel"
pass "Dashboard UI exposes read-only Memory Approval view"

PYTHONDONTWRITEBYTECODE=1 python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys
import tempfile

root = pathlib.Path(sys.argv[1])
sys.path.insert(0, str(root / "apps/gateway-api"))

from app.services import memory_approval_dashboard as dashboard


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


response = dashboard.build_memory_approval_dashboard()
if response.get("read_only") is not True:
    fail("read_only must be true")
if response.get("apply_supported") is not False:
    fail("apply_supported must be false")
if response.get("approval_supported") is not False:
    fail("approval_supported must be false")
if response.get("memory_write_supported") is not False:
    fail("memory_write_supported must be false")
if response.get("human_review_required") is not True:
    fail("human_review_required must be true")
for field in ("reports", "summary", "candidates", "duplicates", "approval", "apply_log", "e2e", "warnings"):
    if field not in response:
        fail(f"missing response field: {field}")

serialized = json.dumps(response).lower()
for forbidden in ("raw_prompt", "raw_response", "prompt_text", "response_text"):
    if forbidden in serialized:
        fail(f"response contains forbidden raw field: {forbidden}")

with tempfile.TemporaryDirectory(prefix="moe-memory-approval-dashboard-") as tmp:
    missing_root = pathlib.Path(tmp) / "missing"
    original_paths = dashboard.REPORT_PATHS
    dashboard.REPORT_PATHS = {
        name: missing_root / f"{name}.json"
        for name in original_paths
    }
    try:
        missing_response = dashboard.build_memory_approval_dashboard()
    finally:
        dashboard.REPORT_PATHS = original_paths
    if missing_response.get("read_only") is not True:
        fail("missing-file response must remain read-only")
    if not missing_response.get("warnings"):
        fail("missing files should produce warnings")
    if missing_response.get("summary", {}).get("total_candidates") != 0:
        fail("missing files should produce zero candidate summary")

print("PASS: memory approval dashboard response contract is safe")
PY

if find "$ROOT" -name "memory-approval-dashboard.json" -print -quit | grep -q .; then
  fail "memory approval dashboard test wrote output inside the repository"
fi
pass "no memory approval dashboard output was written into the repo"

echo "Memory approval dashboard tests passed"
