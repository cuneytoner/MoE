#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
TMP_DIR="$(mktemp -d /tmp/moe-3d-output-card-api.XXXXXX)"
RUNTIME_ROOT="$TMP_DIR/outputs/3d"
METADATA_DIR="$RUNTIME_ROOT/metadata"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$METADATA_DIR"

cat >"$METADATA_DIR/simple_frame_example-test.json" <<'JSON'
{
  "schema_version": "1.0",
  "asset_type": "3d_model",
  "source": "blender_parametric",
  "asset_name": "simple_frame_example",
  "asset_category": "architecture",
  "created_at": "2026-07-17T00:00:00Z",
  "output_files": {
    "blend": "blender/simple_frame_example-test.blend",
    "glb": "glb/simple_frame_example-test.glb",
    "obj": null,
    "preview": null,
    "metadata": "metadata/simple_frame_example-test.json",
    "report": "reports/simple_frame_example-test.json"
  },
  "safety_label": "visual_reference_only",
  "structural_certification": false,
  "operator_review_required": true,
  "generation_mode": "guarded_blender"
}
JSON

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api" "$PYTHON_BIN" - "$RUNTIME_ROOT" >"$TMP_DIR/cards.json" <<'PY'
import json
import sys

from app.media_3d_output_cards import build_3d_output_cards

print(json.dumps(build_3d_output_cards(sys.argv[1]), indent=2, sort_keys=True))
PY

jq -e '.status == "ok"' "$TMP_DIR/cards.json" >/dev/null
jq -e '.service == "gateway-3d-output-cards"' "$TMP_DIR/cards.json" >/dev/null
jq -e '.card_count == 1' "$TMP_DIR/cards.json" >/dev/null
jq -e '.invalid_count == 0' "$TMP_DIR/cards.json" >/dev/null
jq -e '.cards[0].type == "3d_model"' "$TMP_DIR/cards.json" >/dev/null
jq -e '.cards[0].id | startswith("3d_model:metadata/")' "$TMP_DIR/cards.json" >/dev/null
jq -e '.cards[0].formats | index("blend") and index("glb")' "$TMP_DIR/cards.json" >/dev/null
jq -e '.safety_flags.read_only == true' "$TMP_DIR/cards.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_DIR/cards.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/cards.json" >/dev/null
jq -e '.cards[0].relative_runtime_paths | to_entries | all(.value == null or (.value | startswith("/") | not))' "$TMP_DIR/cards.json" >/dev/null

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api" "$PYTHON_BIN" - "$TMP_DIR/missing/outputs/3d" >"$TMP_DIR/missing.json" <<'PY'
import json
import sys

from app.media_3d_output_cards import build_3d_output_cards

print(json.dumps(build_3d_output_cards(sys.argv[1]), indent=2, sort_keys=True))
PY
jq -e '.card_count == 0' "$TMP_DIR/missing.json" >/dev/null
jq -e '.metadata_dir_available == false' "$TMP_DIR/missing.json" >/dev/null
jq -e '.warnings | length > 0' "$TMP_DIR/missing.json" >/dev/null

printf '{bad json' >"$METADATA_DIR/malformed.json"
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api" "$PYTHON_BIN" - "$RUNTIME_ROOT" >"$TMP_DIR/malformed-response.json" <<'PY'
import json
import sys

from app.media_3d_output_cards import build_3d_output_cards

print(json.dumps(build_3d_output_cards(sys.argv[1]), indent=2, sort_keys=True))
PY
jq -e '.invalid_count > 0' "$TMP_DIR/malformed-response.json" >/dev/null

jq '.output_files.glb = "/etc/passwd"' "$METADATA_DIR/simple_frame_example-test.json" >"$METADATA_DIR/unsafe.json"
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api" "$PYTHON_BIN" - "$RUNTIME_ROOT" >"$TMP_DIR/unsafe-response.json" <<'PY'
import json
import sys

from app.media_3d_output_cards import build_3d_output_cards

print(json.dumps(build_3d_output_cards(sys.argv[1]), indent=2, sort_keys=True))
PY
jq -e '.invalid_count > 0' "$TMP_DIR/unsafe-response.json" >/dev/null
jq -e '[.cards[] | select(.metadata_path == "metadata/unsafe.json")] | length == 0' "$TMP_DIR/unsafe-response.json" >/dev/null

ln -s "$METADATA_DIR/simple_frame_example-test.json" "$METADATA_DIR/symlink-sidecar.json"
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api" "$PYTHON_BIN" - "$RUNTIME_ROOT" >"$TMP_DIR/symlink-response.json" <<'PY'
import json
import sys

from app.media_3d_output_cards import build_3d_output_cards

print(json.dumps(build_3d_output_cards(sys.argv[1]), indent=2, sort_keys=True))
PY
jq -e '.warnings | join(" ") | test("symlink skipped")' "$TMP_DIR/symlink-response.json" >/dev/null

SYMLINK_RUNTIME_ROOT="$TMP_DIR/symlink-root/outputs/3d"
mkdir -p "$SYMLINK_RUNTIME_ROOT"
ln -s "$METADATA_DIR" "$SYMLINK_RUNTIME_ROOT/metadata"
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api" "$PYTHON_BIN" - "$SYMLINK_RUNTIME_ROOT" >"$TMP_DIR/symlink-dir-response.json" <<'PY'
import json
import sys

from app.media_3d_output_cards import build_3d_output_cards

print(json.dumps(build_3d_output_cards(sys.argv[1]), indent=2, sort_keys=True))
PY
jq -e '.metadata_dir_available == false' "$TMP_DIR/symlink-dir-response.json" >/dev/null
jq -e '.warnings | length > 0' "$TMP_DIR/symlink-dir-response.json" >/dev/null

generated_files="$(
  find . -type f \( -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print
)"
if [ -n "$generated_files" ]; then
  echo "Unexpected generated 3D files under repo:" >&2
  echo "$generated_files" >&2
  exit 1
fi

echo "3D output card API OK"
