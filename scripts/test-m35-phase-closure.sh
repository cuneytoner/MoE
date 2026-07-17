#!/usr/bin/env bash
set -euo pipefail

MILESTONES="docs/milestones.md"
CLOSURE_DOC="docs/ops/275-m35-3d-pipeline-phase-closure.md"
REVIEW_DOC="docs/ops/276-m35-3d-pipeline-phase-closure-review-template.md"

required_files=(
  "$MILESTONES"
  "$CLOSURE_DOC"
  "$REVIEW_DOC"
  "apps/3d-generator/generic_parametric_blender.py"
  "apps/3d-generator/primitive_builder.py"
  "apps/3d-generator/blender_adapter.py"
  "apps/3d-generator/artifact_verifier.py"
  "apps/gateway-api/app/media_3d_output_cards.py"
  "apps/gateway-api/app/reference_boards.py"
  "apps/gateway-api/app/main.py"
  "apps/gateway-api/app/models/gateway.py"
  "apps/dashboard-ui/src/components/ThreeDOutputCards.tsx"
  "apps/dashboard-ui/src/components/ReferenceBoards.tsx"
  "scripts/test-3d-metadata-sidecar-validator.sh"
  "scripts/test-3d-primitive-builder.sh"
  "scripts/test-3d-blender-adapter.sh"
  "scripts/test-3d-generation-guards.sh"
  "scripts/test-3d-artifact-verifier.sh"
  "scripts/test-3d-output-card-api.sh"
  "scripts/test-3d-reference-board-selection.sh"
)

for path in "${required_files[@]}"; do
  if [ ! -e "$path" ]; then
    echo "missing required M35 closure file: $path" >&2
    exit 1
  fi
done

for milestone in $(seq 1 20); do
  grep -q "## Milestone 35\\.$milestone:" "$MILESTONES"
done

python3 - "$MILESTONES" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
for number in range(1, 21):
    pattern = rf"## Milestone 35\.{number}:.*?\n\nStatus: ([^\n]+)"
    match = re.search(pattern, text, flags=re.S)
    if not match:
        raise SystemExit(f"missing M35.{number} detailed milestone section")
    if match.group(1).strip() != "DONE":
        raise SystemExit(f"M35.{number} is not DONE: {match.group(1).strip()}")
PY

grep -q "M35.20 is DONE" "$CLOSURE_DOC"
grep -q "M35 phase is CLOSED" "$CLOSURE_DOC"
grep -q "Next planned milestone: M36.0 Animation Pipeline" "$CLOSURE_DOC"
if grep -E "M36.*(DONE|implemented|delivered)" "$CLOSURE_DOC" >/dev/null; then
  echo "closure doc appears to claim M36 implementation is complete" >&2
  exit 1
fi

grep -q 'REAL_3D_GENERATION=1' apps/3d-generator/generic_parametric_blender.py
grep -q -- '--execute-generation' apps/3d-generator/generic_parametric_blender.py
grep -q 'os.environ.get("REAL_3D_GENERATION", "0") == "1"' apps/3d-generator/generic_parametric_blender.py
if grep -R '^import bpy\|^from bpy' apps/3d-generator apps/gateway-api/app >/dev/null; then
  echo "module-level bpy import found" >&2
  exit 1
fi

grep -q '@app.get("/gateway/media/3d/cards"' apps/gateway-api/app/main.py
grep -q '@app.post("/gateway/media/reference-boards/{board_id}/items/3d"' apps/gateway-api/app/main.py
grep -q 'find_3d_output_card_by_id' apps/gateway-api/app/media_3d_output_cards.py
grep -q 'build_3d_reference_board_item' apps/gateway-api/app/reference_boards.py
grep -q 'ThreeDOutputCards' apps/dashboard-ui/src/components/ThreeDOutputCards.tsx
grep -q 'Adds a metadata reference only. No 3D asset is copied or modified.' apps/dashboard-ui/src/components/ThreeDOutputCards.tsx

if grep -E "Generate|Regenerate|Delete asset|Remove asset|Move|Rename|Repair|Cleanup|Execute|Open filesystem|Launch Blender|Download asset" apps/dashboard-ui/src/components/ThreeDOutputCards.tsx >/dev/null; then
  echo "forbidden 3D asset operation text found in Dashboard 3D cards component" >&2
  exit 1
fi

if find . -type d \( -name node_modules -o -name dist -o -name build -o -name .cache -o -name __pycache__ \) -print -quit | grep -q .; then
  echo "generated dependency/build/cache directory found in source checkout" >&2
  exit 1
fi

if git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth|pdf|dxf|blend|glb|obj|fbx|mtl|zip|tar)$' >/dev/null; then
  echo "tracked generated media/model/3D binary file found" >&2
  exit 1
fi

if find . -type f \( -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print -quit | grep -q .; then
  echo "3D binary artifact found in source checkout" >&2
  exit 1
fi

grep -q 'RUNTIME_OUTPUT_ROOT = Path("/home/cuneyt/MoE/runtime/media/outputs/3d")' apps/3d-generator/generic_parametric_blender.py
grep -q 'DEFAULT_RUNTIME_3D_ROOT = Path("/home/cuneyt/MoE/runtime/media/outputs/3d")' apps/gateway-api/app/media_3d_output_cards.py
grep -q 'MODEL_BACKUP_ROOT = Path("/home/cuneyt/MoE_Models_Backup")' apps/gateway-api/app/media_3d_output_cards.py

echo "M35 phase closure OK"
