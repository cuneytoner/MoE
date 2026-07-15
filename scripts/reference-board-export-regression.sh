#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"
BOARD_ID="${BOARD_ID:-api-test-board}"

TMP_DIR="$(mktemp -d /tmp/moe-reference-board-export-regression.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

json_export="$TMP_DIR/export.json"
markdown_export="$TMP_DIR/export.md"
json_download="$TMP_DIR/download.json"
markdown_download="$TMP_DIR/download.md"
json_headers="$TMP_DIR/download-json.headers"
markdown_headers="$TMP_DIR/download-markdown.headers"
invalid_create_payload="$TMP_DIR/invalid-create.json"
long_reason_payload="$TMP_DIR/long-reason.json"
many_tags_payload="$TMP_DIR/many-tags.json"

fail() {
  echo "Reference board export regression FAIL: $*" >&2
  exit 1
}

endpoint() {
  printf "%s/gateway/media/reference-boards/%s/%s" "$GATEWAY_API_URL" "$BOARD_ID" "$1"
}

board_endpoint() {
  printf "%s/gateway/media/reference-boards/%s/%s" "$GATEWAY_API_URL" "$1" "$2"
}

assert_json_review_pack() {
  local file="$1"
  jq -e '.export_type == "reference_board_review_pack"' "$file" >/dev/null
  jq -e '.safety.review_only == true' "$file" >/dev/null
  jq -e '.safety.source_assets_copied == false' "$file" >/dev/null
  jq -e '.safety.source_assets_deleted == false' "$file" >/dev/null
  jq -e '.safety.generation_triggered == false' "$file" >/dev/null
  jq -e 'all(.items[]?; (.review_status | type) == "object")' "$file" >/dev/null
  jq -e 'all(.items[]?; (.review_status.needs_review | type) == "boolean")' "$file" >/dev/null
  jq -e 'all(.items[]?; (.review_status.duplicate_hint | type) == "boolean")' "$file" >/dev/null
  jq -e 'all(.items[]?; (.review_status.duplicate_keys | type) == "array")' "$file" >/dev/null
}

assert_no_host_paths() {
  local file="$1"
  if grep -E '/home/cuneyt|/mnt|/media' "$file" >/dev/null; then
    fail "host path leaked in $file"
  fi
}

assert_header_contains() {
  local headers="$1"
  local pattern="$2"
  if ! grep -Ei "$pattern" "$headers" >/dev/null; then
    fail "missing header pattern '$pattern' in $headers"
  fi
}

assert_http_status() {
  local expected="$1"
  local url="$2"
  local body="$TMP_DIR/http-${expected}.json"
  local status
  status="$(curl -sS -o "$body" -w '%{http_code}' "$url")"
  if [ "$status" != "$expected" ]; then
    fail "expected HTTP $expected for $url, got $status"
  fi
  jq -e '.status == "error"' "$body" >/dev/null
}

assert_json_post_status() {
  local expected="$1"
  local url="$2"
  local payload="$3"
  local body="$TMP_DIR/post-${expected}.json"
  local status
  status="$(curl -sS -o "$body" -w '%{http_code}' -H 'Content-Type: application/json' -d "@$payload" "$url")"
  if [ "$status" != "$expected" ]; then
    fail "expected HTTP $expected for POST $url, got $status"
  fi
  jq -e '.status == "error"' "$body" >/dev/null
}

assert_json_patch_status() {
  local expected="$1"
  local url="$2"
  local payload="$3"
  local body="$TMP_DIR/patch-${expected}.json"
  local status
  status="$(curl -sS -o "$body" -w '%{http_code}' -X PATCH -H 'Content-Type: application/json' -d "@$payload" "$url")"
  if [ "$status" != "$expected" ]; then
    fail "expected HTTP $expected for PATCH $url, got $status"
  fi
  jq -e '.status == "error"' "$body" >/dev/null
}

curl -fsS --retry 5 --retry-delay 1 --retry-connrefused --retry-all-errors "$(endpoint export/json)" -o "$json_export"
curl -fsS --retry 5 --retry-delay 1 --retry-connrefused --retry-all-errors "$(endpoint export/markdown)" -o "$markdown_export"
curl -fsS --retry 5 --retry-delay 1 --retry-connrefused --retry-all-errors -D "$json_headers" "$(endpoint download/json)" -o "$json_download"
curl -fsS --retry 5 --retry-delay 1 --retry-connrefused --retry-all-errors -D "$markdown_headers" "$(endpoint download/markdown)" -o "$markdown_download"

assert_json_review_pack "$json_export"
assert_json_review_pack "$json_download"

assert_header_contains "$json_headers" '^content-type:.*application/json'
assert_header_contains "$markdown_headers" '^content-type:.*text/markdown'
assert_header_contains "$json_headers" '^content-disposition:.*attachment'
assert_header_contains "$markdown_headers" '^content-disposition:.*attachment'
assert_header_contains "$json_headers" "filename=\"reference-board-${BOARD_ID}-[0-9]{8}-[0-9]{6}\\.json\""
assert_header_contains "$markdown_headers" "filename=\"reference-board-${BOARD_ID}-[0-9]{8}-[0-9]{6}\\.md\""

grep -F "Reference Board Review Pack" "$markdown_export" >/dev/null || fail "Markdown export missing title"
grep -F "Review status" "$markdown_export" >/dev/null || fail "Markdown export missing Review status"
grep -F "Reference Board Review Pack" "$markdown_download" >/dev/null || fail "Markdown download missing title"
grep -F "Safety" "$markdown_download" >/dev/null || fail "Markdown download missing Safety section"
grep -F "Items" "$markdown_download" >/dev/null || fail "Markdown download missing Items section"
grep -F "Review status" "$markdown_download" >/dev/null || fail "Markdown download missing Review status"
grep -F "Selected reason" "$markdown_download" >/dev/null || fail "Markdown download missing Selected reason"

assert_no_host_paths "$json_export"
assert_no_host_paths "$json_download"
assert_no_host_paths "$markdown_export"
assert_no_host_paths "$markdown_download"

assert_http_status 400 "$(board_endpoint InvalidBoard export/json)"
assert_http_status 404 "$(board_endpoint missing-reference-board export/json)"
assert_http_status 400 "$(board_endpoint InvalidBoard download/markdown)"

printf '{"board_id":"InvalidBoard","title":"Invalid board"}\n' >"$invalid_create_payload"
assert_json_post_status 400 "$GATEWAY_API_URL/gateway/media/reference-boards" "$invalid_create_payload"

first_item_id="$(jq -r '.items[0].item_id // empty' "$json_export")"
if [ -n "$first_item_id" ]; then
  long_reason="$(printf 'x%.0s' {1..1001})"
  jq -n --arg selected_reason "$long_reason" '{selected_reason: $selected_reason}' >"$long_reason_payload"
  jq -n '{tags: ["one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen"]}' >"$many_tags_payload"
  assert_json_patch_status 400 "$GATEWAY_API_URL/gateway/media/reference-boards/$BOARD_ID/items/$first_item_id" "$long_reason_payload"
  assert_json_patch_status 400 "$GATEWAY_API_URL/gateway/media/reference-boards/$BOARD_ID/items/$first_item_id" "$many_tags_payload"
fi

exports_dir="/home/cuneyt/MoE/runtime/reference-boards/exports"
if [ -d "$exports_dir" ]; then
  created_export_file="$(find "$exports_dir" -type f -print -quit)"
  if [ -n "$created_export_file" ]; then
    fail "runtime export file exists: $created_export_file"
  fi
fi

echo "Reference board export regression OK"
echo "BOARD_ID=$BOARD_ID"
echo "GATEWAY_API_URL=$GATEWAY_API_URL"
