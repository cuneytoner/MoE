#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY_CONFIG="${MODEL_REGISTRY_CONFIG:-$ROOT/configs/model-registry.example.yaml}"

pass() {
  echo "PASS: $1"
}

warn() {
  echo "WARN: $1"
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

require_command awk
require_command find
require_command sort
require_command uniq
require_command head
require_command stat

if [ ! -f "$REGISTRY_CONFIG" ]; then
  fail "Model registry config missing: $REGISTRY_CONFIG"
fi

active_root="$(awk '
  $1 == "active_root:" {
    sub(/^[^:]+:[[:space:]]*/, "")
    print
    exit
  }
' "$REGISTRY_CONFIG")"

archive_root="$(awk '
  $1 == "archive_root:" {
    sub(/^[^:]+:[[:space:]]*/, "")
    print
    exit
  }
' "$REGISTRY_CONFIG")"

if [ -d "$active_root" ]; then
  pass "Active model root exists: $active_root"
else
  fail "Active model root missing: $active_root"
fi

if [ -d "$archive_root" ]; then
  pass "Archive model root exists: $archive_root"
else
  warn "Archive model root missing: $archive_root"
fi

while IFS=$'\t' read -r model_id model_type model_path; do
  if [ -z "$model_id" ] || [ -z "$model_type" ] || [ -z "$model_path" ]; then
    continue
  fi

  case "$model_type" in
    directory)
      if [ -d "$model_path" ]; then
        pass "Required active directory exists: id=$model_id path=$model_path"
      else
        fail "Required active directory missing: id=$model_id path=$model_path"
      fi
      ;;
    gguf)
      if [ ! -f "$model_path" ]; then
        fail "Required active GGUF missing: id=$model_id path=$model_path"
      fi
      magic="$(head -c 4 "$model_path")"
      if [ "$magic" != "GGUF" ]; then
        fail "Required active GGUF has invalid magic: id=$model_id path=$model_path magic=${magic:-empty}"
      fi
      size="$(stat -c %s "$model_path")"
      pass "Required active GGUF exists: id=$model_id path=$model_path size=$size"
      ;;
    safetensors)
      if [ -f "$model_path" ]; then
        size="$(stat -c %s "$model_path")"
        pass "Required active safetensors exists: id=$model_id path=$model_path size=$size"
      else
        fail "Required active safetensors missing: id=$model_id path=$model_path"
      fi
      ;;
    *)
      if [ -e "$model_path" ]; then
        pass "Required active path exists: id=$model_id type=$model_type path=$model_path"
      else
        fail "Required active path missing: id=$model_id type=$model_type path=$model_path"
      fi
      ;;
  esac
done < <(awk '
  function emit() {
    if (section == "required_active" && id != "" && type != "" && path != "") {
      print id "\t" type "\t" path
    }
  }
  /^[^[:space:]-][^:]*:/ {
    emit()
    section = $1
    sub(/:$/, "", section)
    id = ""
    type = ""
    path = ""
    next
  }
  $1 == "-" && $2 == "id:" {
    emit()
    id = $3
    type = ""
    path = ""
    next
  }
  $1 == "type:" {
    type = $2
    next
  }
  $1 == "path:" {
    path = $0
    sub(/^[^:]+:[[:space:]]*/, "", path)
    next
  }
  END {
    emit()
  }
' "$REGISTRY_CONFIG")

while IFS=$'\t' read -r model_id archive_path; do
  if [ -z "$model_id" ] || [ -z "$archive_path" ]; then
    continue
  fi

  if [ -e "$archive_path" ]; then
    pass "Archived optional path exists: id=$model_id path=$archive_path"
  else
    warn "Archived optional path missing: id=$model_id path=$archive_path"
  fi
done < <(awk '
  function emit() {
    if (section == "archived_optional" && id != "" && archive_path != "") {
      print id "\t" archive_path
    }
  }
  /^[^[:space:]-][^:]*:/ {
    emit()
    section = $1
    sub(/:$/, "", section)
    id = ""
    archive_path = ""
    next
  }
  $1 == "-" && $2 == "id:" {
    emit()
    id = $3
    archive_path = ""
    next
  }
  $1 == "archive_path:" {
    archive_path = $0
    sub(/^[^:]+:[[:space:]]*/, "", archive_path)
    next
  }
  END {
    emit()
  }
' "$REGISTRY_CONFIG")

while IFS=$'\t' read -r candidate_id candidate_path canonical_path; do
  if [ -z "$candidate_id" ] || [ -z "$candidate_path" ]; then
    continue
  fi

  if [ -e "$candidate_path" ]; then
    warn "Optional duplicate candidate exists: id=$candidate_id path=$candidate_path canonical=$canonical_path"
  else
    warn "Optional duplicate candidate not present: id=$candidate_id path=$candidate_path canonical=$canonical_path"
  fi
done < <(awk '
  function emit() {
    if (section == "optional_duplicate_candidates" && id != "" && path != "") {
      print id "\t" path "\t" canonical_path
    }
  }
  /^[^[:space:]-][^:]*:/ {
    emit()
    section = $1
    sub(/:$/, "", section)
    id = ""
    path = ""
    canonical_path = ""
    next
  }
  $1 == "-" && $2 == "id:" {
    emit()
    id = $3
    path = ""
    canonical_path = ""
    next
  }
  $1 == "path:" {
    path = $0
    sub(/^[^:]+:[[:space:]]*/, "", path)
    next
  }
  $1 == "canonical_path:" {
    canonical_path = $0
    sub(/^[^:]+:[[:space:]]*/, "", canonical_path)
    next
  }
  END {
    emit()
  }
' "$REGISTRY_CONFIG")

duplicates="$(find "$active_root" "$archive_root" \
  \( -path "*/.git/*" -o -path "*/.cache/*" \) -prune -o \
  -type f \( \
    -iname "*.gguf" -o \
    -iname "*.safetensors" -o \
    -iname "*.bin" -o \
    -iname "*.pt" -o \
    -iname "*.pth" -o \
    -iname "*.onnx" \
  \) -printf '%f\n' 2>/dev/null | sort | uniq -d || true)"
if [ -n "$duplicates" ]; then
  warn "Duplicate model filename candidates detected:"
  while IFS= read -r duplicate; do
    [ -n "$duplicate" ] || continue
    echo "  $duplicate"
  done <<<"$duplicates"
else
  pass "No duplicate model filename candidates detected"
fi

echo "Model registry check complete"
