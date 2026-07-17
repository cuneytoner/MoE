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

run_cards() {
  local runtime_root="$1"
  local output_path="$2"
  PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api" "$PYTHON_BIN" - "$runtime_root" >"$output_path" <<'PY'
import json
import sys

from app.media_3d_output_cards import _build_3d_output_cards_from_root

print(json.dumps(_build_3d_output_cards_from_root(sys.argv[1]), indent=2, sort_keys=True))
PY
}

write_sidecar() {
  local output_path="$1"
  local blend_path="${2:-blender/test.blend}"
  local glb_path="${3:-glb/test.glb}"
  local preview_path="${4:-null}"

  cat >"$output_path" <<JSON
{
  "schema_version": "1.0",
  "asset_type": "3d_model",
  "source": "blender_parametric",
  "asset_name": "simple_frame_example",
  "asset_category": "architecture",
  "created_at": "2026-07-17T00:00:00Z",
  "output_files": {
    "blend": "$blend_path",
    "glb": "$glb_path",
    "obj": null,
    "preview": $preview_path,
    "metadata": "metadata/$(basename "$output_path")",
    "report": "reports/test.json"
  },
  "safety_label": "visual_reference_only",
  "structural_certification": false,
  "operator_review_required": true,
  "generation_mode": "guarded_blender"
}
JSON
}

mkdir -p "$METADATA_DIR"
write_sidecar "$METADATA_DIR/missing-artifacts.json"
run_cards "$RUNTIME_ROOT" "$TMP_DIR/missing-artifacts-response.json"
jq -e '.status == "ok"' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.service == "gateway-3d-output-cards"' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.runtime_scope == "runtime/media/outputs/3d"' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.card_count == 1' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.invalid_count == 0' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.cards[0].id | startswith("3d_model:metadata/")' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.cards[0].formats | length == 0' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.cards[0].preview_available == false' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.cards[0].verification.metadata_valid == true' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.cards[0].verification.artifacts_valid == false' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.cards[0].verification.missing_count > 0' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.safety_flags.read_only == true' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$TMP_DIR/missing-artifacts-response.json" >/dev/null
jq -e '.cards[0].relative_runtime_paths | to_entries | all(.value == null or (.value | startswith("/") | not))' "$TMP_DIR/missing-artifacts-response.json" >/dev/null

mkdir -p "$RUNTIME_ROOT/blender" "$RUNTIME_ROOT/glb" "$RUNTIME_ROOT/reports" "$RUNTIME_ROOT/previews"
touch "$RUNTIME_ROOT/blender/test.blend"
touch "$RUNTIME_ROOT/glb/test.glb"
touch "$RUNTIME_ROOT/reports/test.json"
write_sidecar "$METADATA_DIR/existing-artifacts.json"
run_cards "$RUNTIME_ROOT" "$TMP_DIR/existing-artifacts-response.json"
jq -e '[.cards[] | select(.metadata_path == "metadata/existing-artifacts.json")][0].formats | index("blend") and index("glb")' "$TMP_DIR/existing-artifacts-response.json" >/dev/null
jq -e '[.cards[] | select(.metadata_path == "metadata/existing-artifacts.json")][0].verification.valid == true' "$TMP_DIR/existing-artifacts-response.json" >/dev/null

touch "$RUNTIME_ROOT/previews/test.png"
write_sidecar "$METADATA_DIR/preview-artifact.json" "blender/test.blend" "glb/test.glb" '"previews/test.png"'
run_cards "$RUNTIME_ROOT" "$TMP_DIR/preview-response.json"
jq -e '[.cards[] | select(.metadata_path == "metadata/preview-artifact.json")][0].preview_available == true' "$TMP_DIR/preview-response.json" >/dev/null

run_cards "$TMP_DIR/missing/outputs/3d" "$TMP_DIR/missing-dir-response.json"
jq -e '.card_count == 0' "$TMP_DIR/missing-dir-response.json" >/dev/null
jq -e '.metadata_dir_available == false' "$TMP_DIR/missing-dir-response.json" >/dev/null
jq -e '.warnings | length > 0' "$TMP_DIR/missing-dir-response.json" >/dev/null

printf '{bad json' >"$METADATA_DIR/malformed.json"
run_cards "$RUNTIME_ROOT" "$TMP_DIR/malformed-response.json"
jq -e '.invalid_count > 0' "$TMP_DIR/malformed-response.json" >/dev/null

printf '\377\376' >"$METADATA_DIR/invalid-utf8.json"
run_cards "$RUNTIME_ROOT" "$TMP_DIR/invalid-utf8-response.json"
jq -e '.invalid_count > 0' "$TMP_DIR/invalid-utf8-response.json" >/dev/null

"$PYTHON_BIN" - "$METADATA_DIR/oversized.json" <<'PY'
import sys
from pathlib import Path

Path(sys.argv[1]).write_text('{"padding":"' + ("x" * (129 * 1024)) + '"}', encoding="utf-8")
PY
run_cards "$RUNTIME_ROOT" "$TMP_DIR/oversized-response.json"
jq -e '.invalid_count > 0' "$TMP_DIR/oversized-response.json" >/dev/null

invalid_cases=(
  "absolute:/etc/passwd"
  "traversal:../glb/file.glb"
  "leading-dot:./docs/file.json"
  "repo-dir:docs/file.json"
  "model-path:models/model.gguf"
  "checkpoint-path:checkpoints/model.ckpt"
  "backslash:..\\\\..\\\\etc\\\\passwd"
  "wrong-extension:glb/file.json"
  "wrong-directory:reports/file.glb"
  "url:file:///etc/passwd"
  "drive:C:\\\\file.glb"
  "network://server/share/file.glb"
)

for item in "${invalid_cases[@]}"; do
  name="${item%%:*}"
  value="${item#*:}"
  write_sidecar "$METADATA_DIR/invalid-$name.json" "blender/test.blend" "$value"
done
run_cards "$RUNTIME_ROOT" "$TMP_DIR/invalid-paths-response.json"
for item in "${invalid_cases[@]}"; do
  name="${item%%:*}"
  jq -e --arg path "metadata/invalid-$name.json" '[.cards[] | select(.metadata_path == $path)] | length == 0' "$TMP_DIR/invalid-paths-response.json" >/dev/null
done
jq -e '.invalid_count >= 12' "$TMP_DIR/invalid-paths-response.json" >/dev/null

ln -s "$METADATA_DIR/existing-artifacts.json" "$METADATA_DIR/symlink-sidecar.json"
run_cards "$RUNTIME_ROOT" "$TMP_DIR/symlink-sidecar-response.json"
jq -e '.warnings | join(" ") | test("symlink skipped")' "$TMP_DIR/symlink-sidecar-response.json" >/dev/null

SYMLINK_METADATA_ROOT="$TMP_DIR/symlink-metadata-root/outputs/3d"
mkdir -p "$SYMLINK_METADATA_ROOT"
ln -s "$METADATA_DIR" "$SYMLINK_METADATA_ROOT/metadata"
run_cards "$SYMLINK_METADATA_ROOT" "$TMP_DIR/symlink-metadata-dir-response.json"
jq -e '.metadata_dir_available == false' "$TMP_DIR/symlink-metadata-dir-response.json" >/dev/null

SYMLINK_RUNTIME_ROOT="$TMP_DIR/runtime-root-symlink"
ln -s "$RUNTIME_ROOT" "$SYMLINK_RUNTIME_ROOT"
run_cards "$SYMLINK_RUNTIME_ROOT" "$TMP_DIR/symlink-runtime-root-response.json"
jq -e '.metadata_dir_available == false' "$TMP_DIR/symlink-runtime-root-response.json" >/dev/null

ln -s "$RUNTIME_ROOT/glb/test.glb" "$RUNTIME_ROOT/glb/symlink.glb"
write_sidecar "$METADATA_DIR/artifact-symlink.json" "blender/test.blend" "glb/symlink.glb"
run_cards "$RUNTIME_ROOT" "$TMP_DIR/artifact-symlink-response.json"
jq -e '[.cards[] | select(.metadata_path == "metadata/artifact-symlink.json")][0].formats | index("glb") | not' "$TMP_DIR/artifact-symlink-response.json" >/dev/null
jq -e '[.cards[] | select(.metadata_path == "metadata/artifact-symlink.json")][0].verification.valid == false' "$TMP_DIR/artifact-symlink-response.json" >/dev/null

MAX_ROOT="$TMP_DIR/max/outputs/3d"
MAX_METADATA_DIR="$MAX_ROOT/metadata"
mkdir -p "$MAX_METADATA_DIR" "$MAX_ROOT/blender" "$MAX_ROOT/glb" "$MAX_ROOT/reports"
touch "$MAX_ROOT/blender/test.blend" "$MAX_ROOT/glb/test.glb" "$MAX_ROOT/reports/test.json"
for index in $(seq -w 1 205); do
  write_sidecar "$MAX_METADATA_DIR/sidecar-$index.json"
done
run_cards "$MAX_ROOT" "$TMP_DIR/max-response.json"
jq -e '.card_count == 200' "$TMP_DIR/max-response.json" >/dev/null
jq -e '.warnings | join(" ") | test("sidecar limit")' "$TMP_DIR/max-response.json" >/dev/null

if grep -R "/home/cuneyt\\|MoE_Models_Backup\\|DiskD/Projects/MoE/codebase" "$TMP_DIR"/*response.json >/dev/null; then
  echo "3D output card response leaked an absolute host path" >&2
  exit 1
fi

PYTHONDONTWRITEBYTECODE=1 "$PYTHON_BIN" - >"$TMP_DIR/routes.json" <<'PY'
import ast
import json
from pathlib import Path

tree = ast.parse(Path("apps/gateway-api/app/main.py").read_text(encoding="utf-8"))
matches = []
for node in ast.walk(tree):
    if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        continue
    for decorator in node.decorator_list:
        if not isinstance(decorator, ast.Call):
            continue
        func = decorator.func
        if not (
            isinstance(func, ast.Attribute)
            and func.attr == "get"
            and isinstance(func.value, ast.Name)
            and func.value.id == "app"
        ):
            continue
        if not decorator.args:
            continue
        path_arg = decorator.args[0]
        if isinstance(path_arg, ast.Constant) and path_arg.value == "/gateway/media/3d/cards":
            matches.append({"path": path_arg.value, "methods": ["GET"]})
print(json.dumps(matches, sort_keys=True))
PY
jq -e 'length == 1' "$TMP_DIR/routes.json" >/dev/null
jq -e '.[0].methods == ["GET"]' "$TMP_DIR/routes.json" >/dev/null

generated_files="$(
  find . -type f \( -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print
)"
if [ -n "$generated_files" ]; then
  echo "Unexpected generated 3D files under repo:" >&2
  echo "$generated_files" >&2
  exit 1
fi

echo "3D output card API OK"
