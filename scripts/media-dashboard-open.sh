#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Media dashboard locations"
echo ""
echo "Gateway JSON endpoint:"
echo "  $GATEWAY_API_URL/gateway/media/dashboard"
echo ""
echo "Static source-only UI:"
echo "  $ROOT/apps/media-dashboard/index.html"
echo ""
echo "No services were started. To inspect the JSON from a terminal:"
echo "  curl -fsS $GATEWAY_API_URL/gateway/media/dashboard | jq ."
