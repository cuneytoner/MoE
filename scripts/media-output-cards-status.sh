#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"

response="$(curl -fsS "$GATEWAY_API_URL/gateway/media/output-cards")"

echo "Media output cards status"
printf '%s\n' "$response" | jq '{
  status,
  service,
  safety,
  allowlisted_roots,
  max_cards,
  cards_count: (.cards | length),
  cards: [.cards[0:10][]? | {
    id,
    type,
    name,
    path,
    relative_runtime_path,
    modified,
    size_bytes,
    preview_available,
    source,
    safety_label,
    metadata_available,
    metadata_path
  }]
}'
