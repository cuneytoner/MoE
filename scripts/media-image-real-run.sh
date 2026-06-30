#!/usr/bin/env bash
set -euo pipefail

APPLY="${APPLY:-0}"
MEDIA_API_URL="${MEDIA_API_URL:-http://127.0.0.1:8300}"
MEDIA_WORKER_URL="${MEDIA_WORKER_URL:-http://127.0.0.1:8310}"
PROMPT="${PROMPT:-realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight}"

if [ "$APPLY" != "1" ]; then
  echo "DRY RUN: set APPLY=1 and MEDIA_REAL_GENERATION_ENABLED=true to submit a real media image job."
  exit 0
fi

if [ "${MEDIA_REAL_GENERATION_ENABLED:-false}" != "true" ]; then
  echo "FAIL: MEDIA_REAL_GENERATION_ENABLED=true is required for real generation."
  exit 1
fi

"$(dirname "${BASH_SOURCE[0]}")/comfyui-health.sh"
REQUIRE_READY=1 "$(dirname "${BASH_SOURCE[0]}")/check-flux-schnell-models.sh"
"$(dirname "${BASH_SOURCE[0]}")/comfyui-vram-status.sh" || true

echo "Media API health:"
curl -fsS "$MEDIA_API_URL/health"
echo ""

echo "Media Worker health:"
curl -fsS "$MEDIA_WORKER_URL/health"
echo ""

payload="$(jq -n --arg prompt "$PROMPT" '{
  job_type:"image",
  mode:"real",
  prompt:$prompt,
  workflow:"flux_schnell",
  metadata:{width:512,height:512,steps:4,seed:-1,engine:"comfyui",source:"manual"}
}')"

echo "Creating real Media API image job"
if ! created="$(curl -fsS -H "Content-Type: application/json" -X POST -d "$payload" "$MEDIA_API_URL/media/jobs" 2>&1)"; then
  echo "FAIL: Media API job creation request failed"
  printf '%s\n' "$created"
  exit 1
fi
printf '%s\n' "$created"
job_id="$(printf '%s\n' "$created" | jq -r '.job.job_id // empty')"
if [ -z "$job_id" ]; then
  echo "FAIL: job_id not found in Media API response"
  exit 1
fi

echo "Processing real image job: $job_id"
if ! processed="$(curl -fsS -X POST "$MEDIA_API_URL/media/jobs/$job_id/process" 2>&1)"; then
  echo "FAIL: Media API process request failed"
  printf '%s\n' "$processed"
  exit 1
fi
printf '%s\n' "$processed"
echo ""
