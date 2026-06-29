#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://localhost:8100}"

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

patch_body='{"task":"Suggest a docs-only wording improvement for docs/coding-workspace.md","query":"safe patch","paths":["docs/coding-workspace.md"],"max_files":4,"max_context_chars":12000,"temperature":0.1,"max_tokens":768}'

if ! patch_response="$(
  curl -fsS \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$patch_body" \
    "$GATEWAY_API_URL/gateway/code/patch-plan"
)"; then
  fail "Gateway patch plan runtime request failed"
fi

patch_status="$(jq -r '.status // empty' <<<"$patch_response")"
patch_summary="$(jq -r '.summary // empty' <<<"$patch_response")"

if [ "$patch_status" = "ok" ] && [ -n "$patch_summary" ]; then
  pass "Gateway code patch plan runtime"
else
  fail "Gateway patch plan runtime returned unexpected response: $patch_response"
fi

diff_body='{"task":"Suggest a tiny docs-only diff for docs/coding-workspace.md","query":"safe patch","paths":["docs/coding-workspace.md"],"max_files":4,"max_context_chars":12000,"temperature":0.1,"max_tokens":1200}'

if ! diff_response="$(
  curl -fsS \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$diff_body" \
    "$GATEWAY_API_URL/gateway/code/diff-suggest"
)"; then
  fail "Gateway diff suggest runtime request failed"
fi

diff_status="$(jq -r '.status // empty' <<<"$diff_response")"
diff_apply_supported="$(jq -r '.apply_supported' <<<"$diff_response")"
diff_content="$(jq -r '(.diff // "") + (.explanation // "")' <<<"$diff_response")"

if [ "$diff_status" = "ok" ] \
  && [ "$diff_apply_supported" = "false" ] \
  && [ -n "$diff_content" ]; then
  pass "Gateway code diff suggestion runtime"
else
  fail "Gateway diff suggest runtime returned unexpected response: $diff_response"
fi
