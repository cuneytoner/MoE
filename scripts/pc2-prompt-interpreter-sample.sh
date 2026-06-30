#!/usr/bin/env bash
set -euo pipefail

PC2_HOST="${PC2_HOST:-192.168.50.2}"
PROMPT_INTERPRETER_PORT="${PROMPT_INTERPRETER_PORT:-8230}"
BASE_URL="http://${PC2_HOST}:${PROMPT_INTERPRETER_PORT}"

post_prompt() {
  local prompt="$1"

  echo "Prompt: $prompt"
  curl -fsS -H "Content-Type: application/json" \
    -X POST \
    -d "{\"prompt\":\"${prompt}\",\"target_mode\":\"auto\",\"style\":\"auto\",\"mode\":\"dry_run\"}" \
    "${BASE_URL}/interpret"
  echo ""
}

echo "Posting PC-2 Prompt Interpreter sample prompts"
echo "  url: ${BASE_URL}/interpret"
echo "  note: samples do not call Media API or generation engines"

post_prompt "gerçekçi ahşap pergola görseli üret"
post_prompt "short cinematic video shot of a wooden pergola"
post_prompt "3d model rig and animation plan for a simple robot"
