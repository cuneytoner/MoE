#!/usr/bin/env bash
set -euo pipefail

COMPONENT="apps/dashboard-ui/src/components/ThreeDOutputCards.tsx"
TYPES="apps/dashboard-ui/src/types.ts"
API="apps/dashboard-ui/src/api.ts"
APP="apps/dashboard-ui/src/App.tsx"
OUTPUT_CARDS="apps/dashboard-ui/src/components/OutputCards.tsx"
TMP_DIR="$(mktemp -d /tmp/moe-3d-output-cards-ui.XXXXXX)"
DOCKER_IMAGE="${DASHBOARD_UI_TEST_NODE_IMAGE:-node:22-alpine}"
SOURCE_LOCKFILE="apps/dashboard-ui/package-lock.json"

cleanup() {
  if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
    chmod -R u+rwX "$TMP_DIR" 2>/dev/null || true
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT INT TERM

for path in "$COMPONENT" "$TYPES" "$API" "$APP" "$OUTPUT_CARDS"; do
  if [ ! -f "$path" ]; then
    echo "missing required Dashboard UI file: $path" >&2
    exit 1
  fi
done

grep -q "export type ThreeDArtifactVerification" "$TYPES"
grep -q "export type ThreeDOutputCardsResponse" "$TYPES"
grep -q "fetchThreeDOutputCards" "$API"
grep -q "/gateway/media/3d/cards" "$API"
grep -q "ThreeDOutputCards" "$APP"
grep -q "3D Output Cards" "$COMPONENT"
grep -q "Read-only view of guarded Blender outputs and metadata verification." "$COMPONENT"
grep -q "asset_name" "$COMPONENT"
grep -q "asset_category" "$COMPONENT"
grep -q "created_at" "$COMPONENT"
grep -q "formats" "$COMPONENT"
grep -q "safety_label" "$COMPONENT"
grep -q "structural_certification" "$COMPONENT"
grep -q "operator_review_required" "$COMPONENT"
grep -q "generation_mode" "$COMPONENT"
grep -q "verification" "$COMPONENT"
grep -q "metadata_path" "$COMPONENT"
grep -q "Loading 3D output cards." "$COMPONENT"
grep -q "3D output cards unavailable:" "$COMPONENT"
grep -q "3D metadata directory is not available yet." "$COMPONENT"
grep -q "No verified 3D output metadata reported yet." "$COMPONENT"
grep -q "invalid metadata sidecar(s) were skipped." "$COMPONENT"

if grep -E "Generate|Regenerate|Delete|Remove|Move|Rename|Repair|Cleanup|Apply|Execute|Shell|Start Blender|Stop Blender|Model switch|Docker control|Download|Reference board" "$COMPONENT" >/dev/null; then
  echo "forbidden action text found in ThreeDOutputCards component" >&2
  exit 1
fi

if grep -E "/home/cuneyt|MoE_Models_Backup|DiskD/Projects/MoE/codebase" "$COMPONENT" "$TYPES" >/dev/null; then
  echo "absolute production path found in 3D Dashboard component/type files" >&2
  exit 1
fi

if ! grep -q "Media Output Cards" "$OUTPUT_CARDS"; then
  echo "generic OutputCards component appears changed unexpectedly" >&2
  exit 1
fi

if find apps/dashboard-ui -maxdepth 2 -type d \( -name node_modules -o -name dist -o -name build -o -name .cache \) -print | grep -q .; then
  echo "generated dependency/build directory exists under apps/dashboard-ui" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for the isolated Dashboard UI build test." >&2
  exit 1
fi

if [ "${ALLOW_UI_TEST_NETWORK:-0}" = "1" ]; then
  DOCKER_NETWORK_ARGS=()
else
  echo "Dashboard UI dependency installation requires operator-approved network access."
  echo "Run: ALLOW_UI_TEST_NETWORK=1 make test-3d-output-cards-ui"
  exit 2
fi

if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
  echo "$DOCKER_IMAGE is not available locally; refusing automatic pull." >&2
  exit 1
fi

if find apps/dashboard-ui -type d \( -name node_modules -o -name dist -o -name build -o -name .cache \) -print -quit | grep -q .; then
  echo "Generated Dashboard dependency/build directory found in source repo." >&2
  exit 1
fi

mkdir -p "$TMP_DIR/dashboard-ui" "$TMP_DIR/build"
cp -a apps/dashboard-ui/. "$TMP_DIR/dashboard-ui/"

if [ -f "$SOURCE_LOCKFILE" ]; then
  INSTALL_COMMAND="npm ci --ignore-scripts --no-audit --no-fund"
else
  INSTALL_COMMAND="npm install --ignore-scripts --no-audit --no-fund"
fi

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e npm_config_cache=/tmp/.npm \
  "${DOCKER_NETWORK_ARGS[@]}" \
  -v "$TMP_DIR/dashboard-ui:/work" \
  -v "$TMP_DIR/build:/build" \
  -w /work \
  "$DOCKER_IMAGE" \
  sh -lc "$INSTALL_COMMAND && npm run build -- --outDir /build --emptyOutDir"

if [ ! -f "$SOURCE_LOCKFILE" ]; then
  if [ ! -f "$TMP_DIR/dashboard-ui/package-lock.json" ]; then
    echo "Dashboard UI package-lock.json was not created in the temp workspace." >&2
    exit 1
  fi
  cp "$TMP_DIR/dashboard-ui/package-lock.json" "$SOURCE_LOCKFILE"
  rm -rf "$TMP_DIR/dashboard-ui/node_modules" "$TMP_DIR/build"
  mkdir -p "$TMP_DIR/build"
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -e npm_config_cache=/tmp/.npm \
    "${DOCKER_NETWORK_ARGS[@]}" \
    -v "$TMP_DIR/dashboard-ui:/work" \
    -v "$TMP_DIR/build:/build" \
    -w /work \
    "$DOCKER_IMAGE" \
    sh -lc 'npm ci --ignore-scripts --no-audit --no-fund && npm run build -- --outDir /build --emptyOutDir'
fi

if [ ! -f "$TMP_DIR/build/index.html" ]; then
  echo "Dashboard UI build did not create index.html." >&2
  exit 1
fi

if ! find "$TMP_DIR/build" -type f -name "*.js" -print -quit | grep -q .; then
  echo "Dashboard UI build did not create a JavaScript asset." >&2
  exit 1
fi

if find apps/dashboard-ui -type d \( -name node_modules -o -name dist -o -name build -o -name .cache \) -print -quit | grep -q .; then
  echo "Generated Dashboard dependency/build directory found in source repo." >&2
  exit 1
fi

echo "3D output cards UI OK"
