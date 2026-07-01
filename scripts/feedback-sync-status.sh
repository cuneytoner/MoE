#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-cuneyt@192.168.50.2}"
PC2_FEEDBACK_DIR="${PC2_FEEDBACK_DIR:-/home/cuneyt/MoE/runtime/feedback}"
FEEDBACK_JSONL_PATH="${FEEDBACK_JSONL_PATH:-/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl}"
PC2_SSH_CONNECT_TIMEOUT="${PC2_SSH_CONNECT_TIMEOUT:-2}"
SSH_ERR_FILE="$(mktemp /tmp/moe-feedback-sync-status-ssh.XXXXXX)"

cleanup() {
  rm -f "$SSH_ERR_FILE"
}
trap cleanup EXIT

print_file_status() {
  local label="$1"
  local path="$2"

  echo "${label}:"
  echo "  path: ${path}"
  if [ ! -f "$path" ]; then
    echo "  exists: false"
    echo "  size_bytes: 0"
    echo "  line_count: 0"
    echo "  modified_at: null"
    return 0
  fi

  echo "  exists: true"
  echo "  size_bytes: $(stat -c '%s' "$path")"
  echo "  line_count: $(wc -l < "$path" | tr -d ' ')"
  echo "  modified_at: $(stat -c '%y' "$path")"
}

print_file_status "PC1 Gateway feedback" "$FEEDBACK_JSONL_PATH"

echo "PC2 Gateway feedback:"
echo "  host: ${PC2_HOST}"
echo "  path: ${PC2_FEEDBACK_DIR}/gateway-feedback.jsonl"

if ! command -v ssh >/dev/null 2>&1; then
  echo "  status: unavailable"
  echo "  reason: ssh not found"
  exit 0
fi

pc2_status="$(
  ssh -o BatchMode=yes -o ConnectTimeout="$PC2_SSH_CONNECT_TIMEOUT" "$PC2_HOST" \
    "if [ -f '${PC2_FEEDBACK_DIR}/gateway-feedback.jsonl' ]; then printf 'exists=true\nsize_bytes='; stat -c '%s' '${PC2_FEEDBACK_DIR}/gateway-feedback.jsonl'; printf 'line_count='; wc -l < '${PC2_FEEDBACK_DIR}/gateway-feedback.jsonl' | tr -d ' '; printf '\nmodified_at='; stat -c '%y' '${PC2_FEEDBACK_DIR}/gateway-feedback.jsonl'; else printf 'exists=false\nsize_bytes=0\nline_count=0\nmodified_at=null\n'; fi" \
    2>"$SSH_ERR_FILE" || true
)"

if [ -z "$pc2_status" ]; then
  echo "  status: unavailable"
  echo "  reason: $(cat "$SSH_ERR_FILE" 2>/dev/null || echo 'ssh check failed')"
  exit 0
fi

echo "  status: ok"
while IFS='=' read -r key value; do
  [ -n "$key" ] || continue
  echo "  ${key}: ${value}"
done <<<"$pc2_status"
