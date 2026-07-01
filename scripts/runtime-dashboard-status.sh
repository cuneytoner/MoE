#!/usr/bin/env bash
set -euo pipefail

GATEWAY_API_URL="${GATEWAY_API_URL:-http://127.0.0.1:8100}"

response="$(curl -fsS "$GATEWAY_API_URL/gateway/runtime/dashboard")"

echo "Runtime dashboard status"
printf '%s\n' "$response" | jq '{
  status,
  service,
  safety,
  pc1: {
    hostname: .pc1.hostname,
    role: .pc1.role,
    llama_server: .pc1.llama_server,
    gpu: .pc1.gpu,
    comfyui: .pc1.comfyui
  },
  pc2: {
    host: .pc2.host,
    role: .pc2.role,
    prompt_interpreter: .pc2.prompt_interpreter.status,
    nightly_learning: .pc2.nightly_learning.status,
    research_ingestion: .pc2.research_ingestion.status,
    feedback_worker: .pc2.feedback_worker.status
  },
  media_jobs,
  image_lifecycle,
  warnings
}'
