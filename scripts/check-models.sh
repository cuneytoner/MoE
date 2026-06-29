#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL_BACKUP_DIR="${MODEL_BACKUP_DIR:-/home/cuneyt/MoE_Models_Backup}"
MODEL_DIR="$MODEL_BACKUP_DIR/bge-m3"
COMPOSE_FILE="$ROOT/infra/docker/docker-compose.yml"
ENV_FILE="$ROOT/.env.example"
MIN_MODEL_BYTES=$((10 * 1024 * 1024))

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

require_command docker
require_command du
require_command grep
require_command stat

if [ -d "$MODEL_BACKUP_DIR" ]; then
  pass "Model backup directory exists: $MODEL_BACKUP_DIR"
else
  fail "Model backup directory missing: $MODEL_BACKUP_DIR"
fi

if [ -d "$MODEL_DIR" ]; then
  pass "BGE-M3 directory exists: $MODEL_DIR"
else
  fail "BGE-M3 directory missing: $MODEL_DIR"
fi

echo "INFO: BGE-M3 directory size: $(du -sh "$MODEL_DIR" | awk '{print $1}')"

required_files=(
  "config.json"
  "modules.json"
  "pytorch_model.bin"
  "tokenizer.json"
  "sentencepiece.bpe.model"
)

for file in "${required_files[@]}"; do
  if [ -f "$MODEL_DIR/$file" ]; then
    pass "Required file exists: $file"
  else
    fail "Required file missing: $MODEL_DIR/$file"
  fi
done

while IFS= read -r file; do
  if grep -q "git-lfs.github.com/spec" "$file"; then
    fail "Git LFS pointer detected: $file"
  fi
done < <(find "$MODEL_DIR" -type f)

pass "No Git LFS pointer files detected"

model_bytes="$(stat -c %s "$MODEL_DIR/pytorch_model.bin")"
if [ "$model_bytes" -le "$MIN_MODEL_BYTES" ]; then
  fail "pytorch_model.bin is suspiciously small: ${model_bytes} bytes"
fi

pass "pytorch_model.bin size looks plausible: ${model_bytes} bytes"

compose_config="$(docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config)"

if grep -Fq "source: ${MODEL_BACKUP_DIR}/bge-m3" <<<"$compose_config" && \
  grep -Fq "target: /models/bge-m3" <<<"$compose_config"; then
  pass "Docker mount visibility matches expected BGE-M3 path"
else
  fail "Docker compose mount for BGE-M3 is not visible as expected"
fi

echo "Model integrity checks passed"
