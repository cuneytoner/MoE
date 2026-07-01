#!/usr/bin/env bash
set -euo pipefail

DASHBOARD_UI_URL="${DASHBOARD_UI_URL:-http://127.0.0.1:8500}"
GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"
DASHBOARD_UI_ATTEMPTS="${DASHBOARD_UI_ATTEMPTS:-20}"
GATEWAY_ATTEMPTS="${GATEWAY_ATTEMPTS:-5}"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

print_dashboard_container_status() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "INFO: docker command not available; skipping dashboard container status"
    return
  fi

  echo "Dashboard container status:"
  docker ps \
    --filter "name=moe-dashboard-ui" \
    --format "  {{.Names}} {{.Status}} {{.Ports}}" || true
}

wait_for_http_200() {
  local label="$1"
  local url="$2"
  local attempts="$3"
  local required="$4"
  local attempt
  local response
  local body
  local status

  for attempt in $(seq 1 "$attempts"); do
    echo "Attempt $attempt/$attempts: $label $url"
    if response="$(curl -sS -w $'\n__HTTP_STATUS__:%{http_code}' "$url" 2>&1)"; then
      status="${response##*__HTTP_STATUS__:}"
      body="${response%$'\n__HTTP_STATUS__:'*}"
      if [ "$status" = "200" ]; then
        echo "PASS: $label reachable: $url"
        return 0
      fi
      echo "WARN: $label returned HTTP $status"
      if [ -n "$body" ]; then
        echo "$body"
      fi
    else
      echo "WARN: $label request failed"
      echo "$response"
    fi

    if [ "$attempt" -lt "$attempts" ]; then
      sleep 1
    fi
  done

  if [ "$required" = "required" ]; then
    print_dashboard_container_status
    fail "$label did not return HTTP 200 after $attempts attempts: $url"
  fi

  echo "WARN: $label did not return HTTP 200 after $attempts attempts: $url"
  return 0
}

echo "Checking Dashboard UI"
wait_for_http_200 "Dashboard UI" "$DASHBOARD_UI_URL" "$DASHBOARD_UI_ATTEMPTS" "required"

echo "Checking Gateway dashboard endpoint"
wait_for_http_200 "Gateway media dashboard" "$GATEWAY_API_URL/gateway/media/dashboard" "$GATEWAY_ATTEMPTS" "optional"
