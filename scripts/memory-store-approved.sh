#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
MEMORY_STORE_PLAN_PATH="${RUNTIME_DIR}/reports/memory-store/memory-store-plan.json"
MEMORY_STORE_APPLY_LOG_PATH="${RUNTIME_DIR}/reports/memory-store/memory-store-apply-log.jsonl"
MEMORY_STORE_APPLY_SUMMARY_PATH="${RUNTIME_DIR}/reports/memory-store/memory-store-apply-summary.json"
MEMORY_API_URL="${MEMORY_API_URL:-http://127.0.0.1:8101}"
APPLY="${APPLY:-0}"
LOG_DRY_RUN="${LOG_DRY_RUN:-0}"

export PYTHONDONTWRITEBYTECODE=1

if [ ! -f "$MEMORY_STORE_PLAN_PATH" ]; then
  echo "SKIP: Memory store plan is missing: $MEMORY_STORE_PLAN_PATH"
  echo "Run make memory-store-plan-local before storing approved memory candidates."
  exit 0
fi

payload_dir="$(mktemp -d /tmp/moe-memory-store-payloads.XXXXXX)"
trap 'rm -rf "$payload_dir"' EXIT

python3 - "$ROOT" "$MEMORY_STORE_PLAN_PATH" "$payload_dir" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
plan_path = pathlib.Path(sys.argv[2])
payload_dir = pathlib.Path(sys.argv[3])
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.memory_store_workflow import memory_add_payload

plan = json.loads(plan_path.read_text(encoding="utf-8"))
approved = plan.get("approved_candidates")
if not isinstance(approved, list):
    approved = []

print(f"APPROVED_COUNT={len(approved)}")
for index, candidate in enumerate(approved, start=1):
    if not isinstance(candidate, dict):
        continue
    payload = candidate.get("store_payload")
    if not isinstance(payload, dict):
        payload = memory_add_payload(candidate)
    payload_path = payload_dir / f"memory-payload-{index:03d}.json"
    metadata_path = payload_dir / f"memory-candidate-{index:03d}.json"
    payload_path.write_text(json.dumps(payload, sort_keys=True) + "\n", encoding="utf-8")
    metadata_path.write_text(
        json.dumps(
            {
                "id": candidate.get("id", f"candidate-{index:03d}"),
                "title": candidate.get("title", ""),
                "category": candidate.get("category", ""),
            },
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"PAYLOAD\t{candidate.get('id', f'candidate-{index:03d}')}\t{payload_path}")
PY

approved_count="$(
  python3 - "$MEMORY_STORE_PLAN_PATH" <<'PY'
import json
import pathlib
import sys

plan = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
approved = plan.get("approved_candidates")
print(len(approved) if isinstance(approved, list) else 0)
PY
)"

if [ "$approved_count" -eq 0 ]; then
  echo "SKIP: No approved memory candidates are present in $MEMORY_STORE_PLAN_PATH"
  echo "Create approved-memory-candidates.json, rerun make memory-store-plan-local, then inspect dry-run output."
  exit 0
fi

append_log() {
  local mode="$1"
  local candidate_file="$2"
  local result="$3"
  local request_supported="$4"
  local apply_requested="$5"
  local http_status="${6:-}"
  local memory_id="${7:-}"
  local error_summary="${8:-}"

  python3 - "$ROOT" \
    "$MEMORY_STORE_APPLY_LOG_PATH" \
    "$mode" \
    "$candidate_file" \
    "$MEMORY_API_URL" \
    "$result" \
    "$request_supported" \
    "$apply_requested" \
    "$http_status" \
    "$memory_id" \
    "$error_summary" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
log_path = sys.argv[2]
mode = sys.argv[3]
candidate_file = pathlib.Path(sys.argv[4])
memory_api_url = sys.argv[5]
result = sys.argv[6]
request_supported = sys.argv[7] == "true"
apply_requested = sys.argv[8] == "true"
http_status = int(sys.argv[9]) if sys.argv[9] else None
memory_id = sys.argv[10] or None
error_summary = sys.argv[11] or None
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.memory_store_apply_log import append_apply_log, build_log_entry

candidate = json.loads(candidate_file.read_text(encoding="utf-8"))
entry = build_log_entry(
    mode=mode,
    candidate=candidate,
    memory_api_url=memory_api_url,
    result=result,
    request_supported=request_supported,
    apply_requested=apply_requested,
    http_status=http_status,
    memory_id=memory_id,
    error_summary=error_summary,
)
append_apply_log(log_path, entry)
PY
}

write_summary() {
  local memory_write_supported="$1"

  python3 - "$ROOT" \
    "$MEMORY_STORE_APPLY_LOG_PATH" \
    "$MEMORY_STORE_APPLY_SUMMARY_PATH" \
    "$memory_write_supported" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
log_path = sys.argv[2]
summary_path = sys.argv[3]
memory_write_supported = sys.argv[4] == "true"
sys.path.insert(0, str(root / "apps/feedback-worker"))

from app.memory_store_apply_log import write_apply_summary

summary = write_apply_summary(
    log_path=log_path,
    summary_path=summary_path,
    memory_write_supported=memory_write_supported,
)
print(f"PASS: Memory store apply summary written to {summary_path}")
print(f"  total_attempts: {summary['total_attempts']}")
print(f"  stored_count: {summary['stored_count']}")
print(f"  failed_count: {summary['failed_count']}")
print(f"  skipped_count: {summary['skipped_count']}")
print(f"  dry_run_count: {summary['dry_run_count']}")
PY
}

if [ "$APPLY" != "1" ]; then
  echo "DRY-RUN: Memory API writes are disabled. Set APPLY=1 to store approved candidates."
  for payload in "$payload_dir"/memory-payload-*.json; do
    [ -f "$payload" ] || continue
    echo "DRY-RUN: curl -sS '${MEMORY_API_URL%/}/memory/add' -H 'Content-Type: application/json' -d @${payload}"
    if [ "$LOG_DRY_RUN" = "1" ]; then
      candidate_file="${payload/memory-payload-/memory-candidate-}"
      append_log "dry_run" "$candidate_file" "skipped" "true" "false"
    fi
  done
  if [ "$LOG_DRY_RUN" = "1" ]; then
    write_summary "false"
  fi
  exit 0
fi

echo "APPLY=1: storing approved memory candidates through ${MEMORY_API_URL%/}/memory/add"
for payload in "$payload_dir"/memory-payload-*.json; do
  [ -f "$payload" ] || continue
  candidate_file="${payload/memory-payload-/memory-candidate-}"
  response_file="$payload_dir/memory-response.json"
  http_status="$(
    curl -sS \
      -o "$response_file" \
      -w "%{http_code}" \
      -H "Content-Type: application/json" \
      -X POST \
      -d @"$payload" \
      "${MEMORY_API_URL%/}/memory/add" || true
  )"
  response="$(cat "$response_file" 2>/dev/null || true)"
  if [ "$http_status" -ge 200 ] && [ "$http_status" -lt 300 ]; then
    memory_id="$(jq -r '.id // empty' <<<"$response" 2>/dev/null || true)"
    append_log "apply" "$candidate_file" "stored" "true" "true" "$http_status" "$memory_id"
    echo "PASS: Memory API stored approved candidate from $payload"
  else
    error_summary="$(jq -r '.detail // .message // empty' <<<"$response" 2>/dev/null || true)"
    if [ -z "$error_summary" ]; then
      error_summary="Memory API request failed with HTTP $http_status"
    fi
    append_log "apply" "$candidate_file" "failed" "true" "true" "$http_status" "" "$error_summary"
    echo "FAIL: Memory API failed for approved candidate from $payload: $error_summary" >&2
    write_summary "true"
    exit 1
  fi
done
write_summary "true"
