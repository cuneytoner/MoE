#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL_BACKUP_DIR="${MODEL_BACKUP_DIR:-/home/cuneyt/MoE_Models_Backup}"
MODEL_DIR="$MODEL_BACKUP_DIR/bge-m3"
COMPOSE_FILE="$ROOT/infra/docker/docker-compose.yml"
ENV_FILE="$ROOT/.env.example"
MODELS_CONFIG="$ROOT/configs/models.yaml"
RUNTIME_CONFIG="$ROOT/configs/runtime.yaml"
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
require_command awk
require_command head

runtime_value() {
  local key="$1"

  awk -v key="$key" '
    $1 == key ":" {
      sub(/^[^:]+:[[:space:]]*/, "")
      print
      exit
    }
  ' "$RUNTIME_CONFIG"
}

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

LLAMA_SERVER="${LLAMA_SERVER:-$(runtime_value llama_server)}"
if [ -x "$LLAMA_SERVER" ]; then
  pass "llama-server binary exists: $LLAMA_SERVER"
else
  fail "llama-server binary missing or not executable: $LLAMA_SERVER"
fi

optional_gguf_ids=(
  "qwen-coder-14b-fast"
)

is_optional_gguf() {
  local model_id="$1"

  for optional_id in "${optional_gguf_ids[@]}"; do
    if [ "$model_id" = "$optional_id" ]; then
      return 0
    fi
  done
  return 1
}

warn_gguf() {
  echo "WARN: $1"
}

while IFS=$'\t' read -r model_id gguf_path; do
  if [ -z "$model_id" ] || [ -z "$gguf_path" ]; then
    continue
  fi

  if [ ! -f "$gguf_path" ]; then
    if is_optional_gguf "$model_id"; then
      warn_gguf "GGUF model missing: id=$model_id path=$gguf_path"
      continue
    fi
    fail "GGUF model missing: id=$model_id path=$gguf_path"
  fi

  gguf_size="$(stat -c %s "$gguf_path")"
  gguf_magic="$(head -c 4 "$gguf_path")"
  if [ "$gguf_magic" = "GGUF" ]; then
    pass "GGUF magic OK: id=$model_id path=$gguf_path size=${gguf_size} magic=$gguf_magic"
    continue
  fi

  message="invalid GGUF magic: id=$model_id path=$gguf_path size=${gguf_size} magic=${gguf_magic:-empty}"
  if is_optional_gguf "$model_id"; then
    warn_gguf "$message"
  else
    fail "$message"
  fi
done < <(awk '
  $1 == "-" && $2 == "id:" {
    model_id = $3
    next
  }
  $1 == "path:" && $2 ~ /\.gguf$/ {
    path = $0
    sub(/^[^:]+:[[:space:]]*/, "", path)
    print model_id "\t" path
  }
' "$MODELS_CONFIG")

compose_config="$(docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config)"

if grep -Fq "source: ${MODEL_BACKUP_DIR}/bge-m3" <<<"$compose_config" && \
  grep -Fq "target: /models/bge-m3" <<<"$compose_config"; then
  pass "Docker mount visibility matches expected BGE-M3 path"
else
  fail "Docker compose mount for BGE-M3 is not visible as expected"
fi

echo "Model integrity checks passed"
