#!/usr/bin/env bash
set -euo pipefail

APPLY="${APPLY:-0}"
PC2_HOST="${PC2_HOST:-cuneyt@192.168.50.2}"
PC2_FEEDBACK_DIR="${PC2_FEEDBACK_DIR:-/home/cuneyt/MoE/runtime/feedback}"
FEEDBACK_JSONL_PATH="${FEEDBACK_JSONL_PATH:-/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl}"
FEEDBACK_REPORTS_DIR="${FEEDBACK_REPORTS_DIR:-/home/cuneyt/MoE/runtime/feedback/reports}"
SUMMARY_PATH="${FEEDBACK_REPORTS_DIR}/feedback-summary.json"

echo "Feedback sync PC1 to PC2"
echo "  mode: $([ "$APPLY" = "1" ] && echo "apply" || echo "dry-run")"
echo "  destination: ${PC2_HOST}:${PC2_FEEDBACK_DIR}"
echo "  source_feedback: ${FEEDBACK_JSONL_PATH}"
echo "  source_summary: ${SUMMARY_PATH}"

if [ ! -f "$FEEDBACK_JSONL_PATH" ]; then
  echo "SKIP: Gateway feedback file is missing: ${FEEDBACK_JSONL_PATH}"
  echo "Nothing to sync. Gateway feedback remains append-only when present."
  exit 0
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "  rsync_available: false"
  if [ "$APPLY" = "1" ]; then
    echo "FAIL: rsync is required for APPLY=1 sync." >&2
    exit 1
  fi
else
  echo "  rsync_available: true"
fi

echo "Planned operations:"
echo "  ssh ${PC2_HOST} mkdir -p '${PC2_FEEDBACK_DIR}/reports'"
echo "  rsync -av '${FEEDBACK_JSONL_PATH}' '${PC2_HOST}:${PC2_FEEDBACK_DIR}/gateway-feedback.jsonl'"
if [ -f "$SUMMARY_PATH" ]; then
  echo "  rsync -av '${SUMMARY_PATH}' '${PC2_HOST}:${PC2_FEEDBACK_DIR}/reports/feedback-summary.json'"
else
  echo "  optional summary missing; would not sync summary: ${SUMMARY_PATH}"
fi

if [ "$APPLY" != "1" ]; then
  echo "DRY RUN: set APPLY=1 to perform this explicit feedback sync."
  exit 0
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "FAIL: ssh is required for APPLY=1 sync." >&2
  exit 1
fi

ssh -o BatchMode=yes "$PC2_HOST" "mkdir -p '${PC2_FEEDBACK_DIR}/reports'"
rsync -av "$FEEDBACK_JSONL_PATH" "${PC2_HOST}:${PC2_FEEDBACK_DIR}/gateway-feedback.jsonl"

if [ -f "$SUMMARY_PATH" ]; then
  rsync -av "$SUMMARY_PATH" "${PC2_HOST}:${PC2_FEEDBACK_DIR}/reports/feedback-summary.json"
fi

echo "PASS: Feedback sync completed."
