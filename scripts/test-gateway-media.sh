#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"

pass() {
  echo "PASS: $1"
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

post_gateway_json() {
  local path="$1"
  local body="$2"

  curl -fsS \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$body" \
    "$GATEWAY_API_URL$path"
}

wait_for_gateway() {
  local attempts=30

  for attempt in $(seq 1 "$attempts"); do
    if curl -fsS "$GATEWAY_API_URL/gateway/media/health" >/dev/null 2>&1; then
      return 0
    fi
    if [ "$attempt" -lt "$attempts" ]; then
      sleep 1
    fi
  done

  fail "Gateway media health did not become reachable within ${attempts}s"
}

require_command curl
require_command jq

wait_for_gateway

if ! health_response="$(curl -fsS "$GATEWAY_API_URL/gateway/media/health")"; then
  fail "Gateway media health request failed"
fi

health_status="$(jq -r '.status // empty' <<<"$health_response")"
health_service="$(jq -r '.service // empty' <<<"$health_response")"
health_default_mode="$(jq -r '.default_mode // empty' <<<"$health_response")"
health_real_allowed="$(jq -r '.real_allowed' <<<"$health_response")"

if [ "$health_status" = "ok" ] \
  && [ "$health_service" = "gateway-media" ] \
  && [ "$health_default_mode" = "dry_run" ] \
  && { [ "$health_real_allowed" = "false" ] || [ "$health_real_allowed" = "true" ]; }; then
  pass "Gateway media health"
else
  fail "Gateway media health returned unexpected response: $health_response"
fi

plan_payload="$(jq -n \
  --arg prompt "realistic sun shaded wooden pergola render" \
  '{prompt:$prompt,target_mode:"image",style:"realistic"}')"

if ! plan_response="$(post_gateway_json "/gateway/media/plan" "$plan_payload")"; then
  fail "Gateway media plan request failed"
fi

plan_status="$(jq -r '.status // empty' <<<"$plan_response")"
plan_mode="$(jq -r '.mode // empty' <<<"$plan_response")"
plan_job_type="$(jq -r '.job_spec.job_type // empty' <<<"$plan_response")"

if [ "$plan_status" = "ok" ] && [ "$plan_mode" = "dry_run" ] && [ "$plan_job_type" = "image" ]; then
  pass "Gateway media plan"
else
  fail "Gateway media plan returned unexpected response: $plan_response"
fi

real_payload="$(jq -n \
  --arg prompt "realistic sun shaded wooden pergola render" \
  '{
    prompt:$prompt,
    target_mode:"image",
    style:"realistic",
    confirm_real_generation:true
  }')"

if ! real_response="$(post_gateway_json "/gateway/media/jobs/real" "$real_payload")"; then
  fail "Gateway media real request failed"
fi

real_status="$(jq -r '.status // empty' <<<"$real_response")"
real_reason="$(jq -r '.reason // empty' <<<"$real_response")"

if [ "$real_status" = "rejected" ] \
  && [ "$real_reason" = "GATEWAY_MEDIA_REAL_ALLOWED must be true for real generation" ]; then
  pass "Gateway media real rejected by default"
else
  fail "Gateway media real default rejection returned unexpected response: $real_response"
fi

invalid_http_status="$(
  curl -sS -o /tmp/moe-gateway-media-invalid-response.json -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"prompt":"","target_mode":"image","style":"realistic"}' \
    "$GATEWAY_API_URL/gateway/media/plan" || true
)"
invalid_response="$(cat /tmp/moe-gateway-media-invalid-response.json 2>/dev/null || true)"

if [ "$invalid_http_status" = "422" ]; then
  pass "Gateway media invalid prompt rejected"
else
  fail "Gateway media invalid prompt expected HTTP 422, got $invalid_http_status: $invalid_response"
fi

media_api_reachable="$(jq -r '.media_api_reachable' <<<"$health_response")"
if [ "$media_api_reachable" != "true" ]; then
  echo "WARN: skipping Gateway media dry-run job creation because Media API is unreachable"
  exit 0
fi

if ! dry_run_response="$(post_gateway_json "/gateway/media/jobs/dry-run" "$plan_payload")"; then
  fail "Gateway media dry-run job request failed"
fi

dry_run_status="$(jq -r '.status // empty' <<<"$dry_run_response")"
dry_run_mode="$(jq -r '.mode // empty' <<<"$dry_run_response")"
dry_run_media_status="$(jq -r '.media_api.status // empty' <<<"$dry_run_response")"

if [ "$dry_run_status" = "ok" ] \
  && [ "$dry_run_mode" = "dry_run" ] \
  && [ "$dry_run_media_status" = "ok" ]; then
  pass "Gateway media dry-run job"
else
  fail "Gateway media dry-run job returned unexpected response: $dry_run_response"
fi
