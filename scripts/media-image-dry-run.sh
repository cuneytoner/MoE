#!/usr/bin/env bash
set -euo pipefail

MEDIA_API_URL="${MEDIA_API_URL:-http://127.0.0.1:8300}"
PROMPT="${PROMPT:-realistic sun shaded wooden pergola in a small garden}"

payload="$(jq -n --arg prompt "$PROMPT" '{
  job_type:"image",
  mode:"dry_run",
  prompt:$prompt,
  workflow:"image_default",
  metadata:{width:512,height:512,steps:4,engine:"disabled",source:"manual"}
}')"

echo "Creating Media API dry-run image job"
created="$(curl -fsS -H "Content-Type: application/json" -X POST -d "$payload" "$MEDIA_API_URL/media/jobs")"
printf '%s\n' "$created"
job_id="$(printf '%s\n' "$created" | jq -r '.job.job_id // empty')"
if [ -z "$job_id" ]; then
  echo "FAIL: job_id not found in Media API response"
  exit 1
fi

echo "Processing dry-run image job: $job_id"
curl -fsS -X POST "$MEDIA_API_URL/media/jobs/$job_id/process"
echo ""
