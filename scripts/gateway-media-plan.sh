#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"
PROMPT="${PROMPT:-realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight}"
TARGET_MODE="${TARGET_MODE:-image}"
STYLE="${STYLE:-realistic}"

payload="$(jq -n \
  --arg prompt "$PROMPT" \
  --arg target_mode "$TARGET_MODE" \
  --arg style "$STYLE" \
  '{prompt:$prompt,target_mode:$target_mode,style:$style}')"

curl -fsS \
  -H "Content-Type: application/json" \
  -X POST \
  -d "$payload" \
  "$GATEWAY_API_URL/gateway/media/plan" | jq .
