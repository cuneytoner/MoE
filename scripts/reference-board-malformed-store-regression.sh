#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"
BOARD_ID="${BOARD_ID:-malformed-regression-board}"
REFERENCE_BOARD_RUNTIME_DIR="${REFERENCE_BOARD_RUNTIME_DIR:-/home/cuneyt/MoE/runtime/reference-boards}"

malformed_file="${REFERENCE_BOARD_RUNTIME_DIR}/${BOARD_ID}.json"
TMP_DIR="$(mktemp -d /tmp/moe-reference-board-malformed-store-regression.XXXXXX)"
cleanup_malformed_file="false"

trap 'if [ "$cleanup_malformed_file" = "true" ]; then rm -f "$malformed_file"; fi; rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "Reference board malformed store regression FAIL: $*" >&2
  exit 1
}

board_url() {
  printf "%s/gateway/media/reference-boards/%s%s" "$GATEWAY_API_URL" "$BOARD_ID" "$1"
}

assert_no_traceback() {
  local file="$1"
  if grep -F 'Traceback' "$file" >/dev/null; then
    fail "traceback leaked in $file"
  fi
}

assert_no_unsafe_error_text() {
  local file="$1"
  if grep -E 'Traceback|/home/cuneyt|/mnt|/media' "$file" >/dev/null; then
    fail "unsafe error text leaked in $file"
  fi
}

assert_controlled_error_body() {
  local file="$1"
  jq -e '.status == "error" and (.error | type == "string") and (.detail | type == "string")' "$file" >/dev/null
  assert_no_unsafe_error_text "$file"
}

assert_controlled_non_success() {
  local label="$1"
  local url="$2"
  local body="$TMP_DIR/${label}.json"
  local status

  status="$(curl -sS -o "$body" -w '%{http_code}' "$url")"
  case "$status" in
    2*)
      fail "$label unexpectedly returned HTTP $status"
      ;;
    500)
      fail "$label returned HTTP 500"
      ;;
  esac

  assert_controlled_error_body "$body"
}

if [ ! -d "$REFERENCE_BOARD_RUNTIME_DIR" ]; then
  fail "reference board runtime dir does not exist: $REFERENCE_BOARD_RUNTIME_DIR"
fi

if [ -e "$malformed_file" ]; then
  fail "refusing to overwrite existing runtime board file: $malformed_file"
fi

printf '{ bad json\n' >"$malformed_file"
cleanup_malformed_file="true"

list_body="$TMP_DIR/list.json"
list_status="$(curl -sS -o "$list_body" -w '%{http_code}' "$GATEWAY_API_URL/gateway/media/reference-boards")"
if [ "$list_status" = "500" ]; then
  fail "list endpoint returned HTTP 500"
fi
assert_no_traceback "$list_body"
jq -e --arg board_id "$BOARD_ID" 'all(.boards[]?; .board_id != $board_id)' "$list_body" >/dev/null

assert_controlled_non_success "read" "$(board_url "")"
assert_controlled_non_success "export-json" "$(board_url "/export/json")"
assert_controlled_non_success "download-markdown" "$(board_url "/download/markdown")"

rm -f "$malformed_file"
cleanup_malformed_file="false"

if [ -e "$malformed_file" ]; then
  fail "cleanup failed for $malformed_file"
fi

echo "Reference board malformed store regression OK"
echo "BOARD_ID=$BOARD_ID"
echo "GATEWAY_API_URL=$GATEWAY_API_URL"
echo "REFERENCE_BOARD_RUNTIME_DIR=$REFERENCE_BOARD_RUNTIME_DIR"
