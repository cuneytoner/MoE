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

require_command curl
require_command jq

if ! response="$(curl -fsS --max-time 3 "$GATEWAY_API_URL/gateway/runtime/dashboard" 2>&1)"; then
  echo "SKIP: Gateway runtime dashboard is not reachable at $GATEWAY_API_URL/gateway/runtime/dashboard"
  echo "$response"
  exit 0
fi

status="$(jq -r '.status // empty' <<<"$response")"
service="$(jq -r '.service // empty' <<<"$response")"
read_only="$(jq -r '.safety.read_only' <<<"$response")"
starts_services="$(jq -r '.safety.starts_services' <<<"$response")"
stops_services="$(jq -r '.safety.stops_services' <<<"$response")"
real_generation_trigger="$(jq -r '.safety.real_generation_trigger' <<<"$response")"
arbitrary_shell="$(jq -r '.safety.arbitrary_shell' <<<"$response")"
pc1_type="$(jq -r 'if (.pc1 | type) == "object" then "object" else "other" end' <<<"$response")"
pc2_type="$(jq -r 'if (.pc2 | type) == "object" then "object" else "other" end' <<<"$response")"
media_jobs_type="$(jq -r 'if (.media_jobs | type) == "object" then "object" else "other" end' <<<"$response")"
image_lifecycle_type="$(jq -r 'if (.image_lifecycle | type) == "object" then "object" else "other" end' <<<"$response")"
system_type="$(jq -r 'if (.system | type) == "object" then "object" else "other" end' <<<"$response")"
system_pc1_memory_type="$(jq -r 'if (.system.pc1.memory | type) == "object" then "object" else "other" end' <<<"$response")"
system_pc1_cpu_type="$(jq -r 'if (.system.pc1.cpu | type) == "object" then "object" else "other" end' <<<"$response")"
system_pc1_disk_type="$(jq -r 'if (.system.pc1.disk | type) == "object" then "object" else "other" end' <<<"$response")"
system_pc1_uptime_type="$(jq -r 'if (.system.pc1.uptime | type) == "object" then "object" else "other" end' <<<"$response")"
system_pc2_status="$(jq -r '.system.pc2.status // empty' <<<"$response")"
system_docker_status="$(jq -r '.system.docker.status // empty' <<<"$response")"
warnings_type="$(jq -r 'if (.warnings | type) == "array" then "array" else "other" end' <<<"$response")"
runtime_profile_summary_type="$(jq -r 'if (.runtime_profile_summary | type) == "object" then "object" else "other" end' <<<"$response")"
runtime_profile_summary_source="$(jq -r '.runtime_profile_summary.source_endpoint // empty' <<<"$response")"

if [ "$status" = "ok" ] \
  && [ "$service" = "gateway-runtime-dashboard" ] \
  && [ "$read_only" = "true" ] \
  && [ "$starts_services" = "false" ] \
  && [ "$stops_services" = "false" ] \
  && [ "$real_generation_trigger" = "false" ] \
  && [ "$arbitrary_shell" = "false" ] \
  && [ "$pc1_type" = "object" ] \
  && [ "$pc2_type" = "object" ] \
  && [ "$media_jobs_type" = "object" ] \
  && [ "$image_lifecycle_type" = "object" ] \
  && [ "$system_type" = "object" ] \
  && [ "$system_pc1_memory_type" = "object" ] \
  && [ "$system_pc1_cpu_type" = "object" ] \
  && [ "$system_pc1_disk_type" = "object" ] \
  && [ "$system_pc1_uptime_type" = "object" ] \
  && [ -n "$system_pc2_status" ] \
  && [ -n "$system_docker_status" ] \
  && [ "$runtime_profile_summary_type" = "object" ] \
  && [ "$runtime_profile_summary_source" = "/gateway/runtime/profile-recommendation-summary" ] \
  && [ "$warnings_type" = "array" ]; then
  pass "Gateway runtime dashboard contract"
else
  fail "Gateway runtime dashboard returned unexpected response: $response"
fi
