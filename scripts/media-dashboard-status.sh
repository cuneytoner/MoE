#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"

response="$(curl -fsS "$GATEWAY_API_URL/gateway/media/dashboard")"

echo "Media dashboard status"
printf '%s\n' "$response" | jq '{
  status,
  service,
  safety,
  gates,
  services: (.services | with_entries(.value = {
    status: .value.status,
    reachable: .value.reachable,
    url: .value.url,
    http_status: .value.http_status,
    detail: .value.detail
  })),
  latest_images: [.latest_images[]? | {name, path, modified, size_bytes}],
  warnings
}'
