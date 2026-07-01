#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${RUNTIME_DIR:-/home/cuneyt/MoE/runtime}"
FEEDBACK_JSONL_PATH="${FEEDBACK_JSONL_PATH:-${RUNTIME_DIR}/feedback/gateway-feedback.jsonl}"
FEEDBACK_SUMMARY_PATH="${FEEDBACK_SUMMARY_PATH:-${RUNTIME_DIR}/feedback/reports/feedback-summary.json}"
FEEDBACK_WORKER_URL="${FEEDBACK_WORKER_URL:-http://127.0.0.1:8220}"

pass() {
  echo "PASS: $1"
}

skip() {
  echo "SKIP: $1"
  exit 0
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "$1 is required"
  fi
}

ensure_sample_feedback() {
  mkdir -p "$(dirname "$FEEDBACK_JSONL_PATH")"
  if [ ! -s "$FEEDBACK_JSONL_PATH" ]; then
    printf '%s\n' '{"created_at":"2026-01-01T00:00:00Z","service":"gateway-feedback","source":"manual","rating":"useful","tags":["m28","bridge"],"router_intent":"architecture","model":"gateway-auto"}' > "$FEEDBACK_JSONL_PATH"
    pass "Created minimal Gateway feedback sample at $FEEDBACK_JSONL_PATH"
  else
    pass "Gateway feedback file exists at $FEEDBACK_JSONL_PATH"
  fi
}

require_command curl
require_command jq
ensure_sample_feedback

status_http="$(
  curl -sS -o /tmp/moe-feedback-worker-bridge-status.json -w "%{http_code}" \
    "$FEEDBACK_WORKER_URL/feedback/status" 2>/dev/null || true
)"
status_response="$(cat /tmp/moe-feedback-worker-bridge-status.json 2>/dev/null || true)"

case "$status_http" in
  000)
    skip "Feedback Worker is unavailable at $FEEDBACK_WORKER_URL"
    ;;
  200)
    service="$(jq -r '.service // empty' <<<"$status_response")"
    status="$(jq -r '.status // empty' <<<"$status_response")"
    record_count="$(jq -r '.record_count // -1' <<<"$status_response")"
    useful_count="$(jq -r '.ratings.useful // -1' <<<"$status_response")"
    if [ "$service" != "feedback-worker" ] || [ "$status" != "ok" ] || [ "$record_count" -lt 1 ] || [ "$useful_count" -lt 0 ]; then
      fail "Feedback Worker status returned bad contract: $status_response"
    fi
    pass "Feedback Worker bridge status record_count=$record_count"
    ;;
  404)
    fail "Feedback Worker bridge endpoint missing; rebuild feedback-worker with M28.6 source"
    ;;
  *)
    fail "Feedback Worker bridge status returned HTTP $status_http: $status_response"
    ;;
esac

summary_http="$(
  curl -sS -o /tmp/moe-feedback-worker-bridge-summary.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    "$FEEDBACK_WORKER_URL/feedback/summarize" || true
)"
summary_response="$(cat /tmp/moe-feedback-worker-bridge-summary.json 2>/dev/null || true)"

if [ "$summary_http" != "200" ]; then
  fail "Feedback Worker summarize returned HTTP $summary_http: $summary_response"
fi

summary_status="$(jq -r '.status // empty' <<<"$summary_response")"
summary_record_count="$(jq -r '.summary.record_count // -1' <<<"$summary_response")"
if [ "$summary_status" != "ok" ] || [ "$summary_record_count" -lt 1 ]; then
  fail "Feedback Worker summarize returned bad contract: $summary_response"
fi

if [ ! -f "$FEEDBACK_SUMMARY_PATH" ]; then
  fail "Expected summary file was not created under runtime: $FEEDBACK_SUMMARY_PATH"
fi

jq -e '.record_count >= 1 and (.rating_counts.useful >= 0)' "$FEEDBACK_SUMMARY_PATH" >/dev/null
pass "Feedback Worker bridge summary written to $FEEDBACK_SUMMARY_PATH"
echo "Feedback Worker bridge test passed"
