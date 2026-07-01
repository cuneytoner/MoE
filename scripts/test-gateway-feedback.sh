#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"

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

wait_for_gateway() {
  local attempts=20
  local http_status

  for attempt in $(seq 1 "$attempts"); do
    http_status="$(
      curl -sS -o /tmp/moe-gateway-feedback-ready.json -w "%{http_code}" \
        "$GATEWAY_API_URL/gateway/feedback/status" 2>/dev/null || true
    )"
    if [ "$http_status" != "000" ]; then
      return 0
    fi
    if [ "$attempt" -lt "$attempts" ]; then
      sleep 1
    fi
  done

  return 1
}

require_command curl
require_command jq

if ! wait_for_gateway; then
  skip "Gateway API is unavailable at $GATEWAY_API_URL"
fi

valid_status="$(
  curl -sS -o /tmp/moe-gateway-feedback-valid.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"source":"manual","rating":"useful","reason":"Gateway feedback smoke test.","tags":["m28","gateway","feedback"],"router_intent":"architecture","model":"gateway-auto"}' \
    "$GATEWAY_API_URL/gateway/feedback" || true
)"
valid_response="$(cat /tmp/moe-gateway-feedback-valid.json 2>/dev/null || true)"

case "$valid_status" in
  200)
    status="$(jq -r '.status // empty' <<<"$valid_response")"
    service="$(jq -r '.service // empty' <<<"$valid_response")"
    id="$(jq -r '.id // empty' <<<"$valid_response")"
    if [ "$status" = "ok" ] && [ "$service" = "gateway-feedback" ] && [ -n "$id" ]; then
      pass "Gateway feedback accepted"
    else
      fail "Gateway feedback returned bad contract: $valid_response"
    fi
    ;;
  404)
    fail "Gateway feedback endpoint missing; rebuild Gateway with M28.5 source"
    ;;
  *)
    fail "Gateway feedback returned HTTP $valid_status: $valid_response"
    ;;
esac

status_http="$(
  curl -sS -o /tmp/moe-gateway-feedback-status.json -w "%{http_code}" \
    "$GATEWAY_API_URL/gateway/feedback/status" || true
)"
status_response="$(cat /tmp/moe-gateway-feedback-status.json 2>/dev/null || true)"

if [ "$status_http" != "200" ]; then
  fail "Gateway feedback status returned HTTP $status_http: $status_response"
fi

record_count="$(jq -r '.record_count // 0' <<<"$status_response")"
service="$(jq -r '.service // empty' <<<"$status_response")"
if [ "$service" = "gateway-feedback" ] && [ "$record_count" -ge 1 ]; then
  pass "Gateway feedback status record_count=$record_count"
else
  fail "Gateway feedback status returned bad contract: $status_response"
fi

invalid_status="$(
  curl -sS -o /tmp/moe-gateway-feedback-invalid.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"source":"manual","rating":"bad-rating"}' \
    "$GATEWAY_API_URL/gateway/feedback" || true
)"

if [ "$invalid_status" = "422" ] || [ "$invalid_status" = "400" ]; then
  pass "Gateway feedback rejects invalid rating"
else
  invalid_response="$(cat /tmp/moe-gateway-feedback-invalid.json 2>/dev/null || true)"
  fail "Gateway feedback expected rejection for invalid rating, got HTTP $invalid_status: $invalid_response"
fi

echo "Gateway feedback test passed"
