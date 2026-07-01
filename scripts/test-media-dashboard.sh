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

wait_for_gateway_dashboard() {
  local attempts=30

  for attempt in $(seq 1 "$attempts"); do
    if curl -fsS "$GATEWAY_API_URL/gateway/media/dashboard" >/dev/null 2>&1; then
      return 0
    fi
    if [ "$attempt" -lt "$attempts" ]; then
      sleep 1
    fi
  done

  fail "Gateway media dashboard did not become reachable within ${attempts}s"
}

require_command curl
require_command jq

wait_for_gateway_dashboard

if ! response="$(curl -fsS "$GATEWAY_API_URL/gateway/media/dashboard")"; then
  fail "Gateway media dashboard request failed"
fi

status="$(jq -r '.status // empty' <<<"$response")"
service="$(jq -r '.service // empty' <<<"$response")"
read_only="$(jq -r '.safety.read_only' <<<"$response")"
starts_services="$(jq -r '.safety.starts_services' <<<"$response")"
stops_services="$(jq -r '.safety.stops_services' <<<"$response")"
real_generation_trigger="$(jq -r '.safety.real_generation_trigger' <<<"$response")"
arbitrary_shell="$(jq -r '.safety.arbitrary_shell' <<<"$response")"
latest_images_type="$(jq -r 'if (.latest_images | type) == "array" then "array" else "other" end' <<<"$response")"
gates_type="$(jq -r 'if (.gates | type) == "object" then "object" else "other" end' <<<"$response")"
services_type="$(jq -r 'if (.services | type) == "object" then "object" else "other" end' <<<"$response")"

if [ "$status" = "ok" ] \
  && [ "$service" = "gateway-media-dashboard" ] \
  && [ "$read_only" = "true" ] \
  && [ "$starts_services" = "false" ] \
  && [ "$stops_services" = "false" ] \
  && [ "$real_generation_trigger" = "false" ] \
  && [ "$arbitrary_shell" = "false" ] \
  && [ "$latest_images_type" = "array" ] \
  && [ "$gates_type" = "object" ] \
  && [ "$services_type" = "object" ]; then
  pass "Gateway media dashboard contract"
else
  fail "Gateway media dashboard returned unexpected response: $response"
fi
