#!/usr/bin/env bash
set -euo pipefail

DOC="docs/ops/277-animation-pipeline-foundation.md"
REVIEW="docs/ops/278-animation-pipeline-foundation-review-template.md"
CONFIG="configs/animation/animation-plan.example.yaml"
MILESTONES="docs/milestones.md"

for path in "$DOC" "$REVIEW" "$CONFIG" "$MILESTONES"; do
  if [ ! -f "$path" ]; then
    echo "missing animation foundation file: $path" >&2
    exit 1
  fi
done

grep -q 'schema_version: "1.0"' "$CONFIG"
grep -q 'plan_id: "camera-orbit-demo"' "$CONFIG"
grep -q 'mode: "dry_run"' "$CONFIG"
grep -q 'visual_reference_only: true' "$CONFIG"
grep -q 'structural_certification: false' "$CONFIG"
grep -q 'operator_review_required: true' "$CONFIG"
grep -q 'fps: 24' "$CONFIG"
grep -q 'start_frame: 1' "$CONFIG"
grep -q 'end_frame: 120' "$CONFIG"
grep -q 'duration_seconds: 5' "$CONFIG"
grep -q 'target_type: "camera"' "$CONFIG"
grep -q 'property: "transform"' "$CONFIG"
grep -q 'interpolation: "bezier"' "$CONFIG"
grep -q 'keyframes:' "$CONFIG"
grep -q 'real_animation_enabled: false' "$CONFIG"
grep -q 'blender_execution_enabled: false' "$CONFIG"
grep -q 'preview_render_enabled: false' "$CONFIG"
grep -q 'runtime_write_planned: false' "$CONFIG"

if grep -E 'relative_runtime_path: "/|relative_runtime_path: "\.\.|/home/cuneyt|MoE_Models_Backup|DiskD/Projects/MoE/codebase' "$CONFIG" >/dev/null; then
  echo "unsafe path found in animation example config" >&2
  exit 1
fi

grep -q "fps.*1..120" "$DOC"
grep -q "max tracks: 64" "$DOC"
grep -q "max keyframes per track: 1000" "$DOC"
grep -q "max plan id length: 80" "$DOC"
grep -q "max title length: 120" "$DOC"
grep -q "max description length: 1000" "$DOC"
grep -q '`camera`' "$DOC"
grep -q '`object`' "$DOC"
grep -q '`transform`' "$DOC"
grep -q '`location`' "$DOC"
grep -q '`rotation_euler`' "$DOC"
grep -q '`scale`' "$DOC"
grep -q '`visibility`' "$DOC"
grep -q '`constant`' "$DOC"
grep -q '`linear`' "$DOC"
grep -q '`bezier`' "$DOC"
grep -q "REAL_ANIMATION_GENERATION=1" "$DOC"
grep -q -- "--execute-animation" "$DOC"
grep -q -- "--render-preview" "$DOC"
grep -q "M36.0 | Animation Pipeline Foundation and Roadmap | DONE" "$DOC"
grep -q "M36.1 | Animation Plan Schema | DONE" "$DOC"
grep -q "M36.2 | Animation Plan Validator | DONE" "$DOC"
grep -q "M36.3 | Timeline and Keyframe Planner Core | DONE" "$DOC"
grep -q "M36.4 | Camera Animation Planner | DONE" "$DOC"
grep -q "M36.5 | Object Transform Animation Planner | DONE" "$DOC"
grep -q "M36.6 | Blender Animation Adapter Plan | DONE" "$DOC"
grep -q "M36.7 | Guarded Blender Animation Implementation | DONE" "$DOC"
grep -q "M36.8 | Animation Metadata Sidecar Writer | DONE" "$DOC"
grep -q "M36.9 | Animation Metadata Validator | DONE" "$DOC"
grep -q "M36.10 | Preview Render Safety Plan | DONE" "$DOC"
grep -q "M36.11 | Guarded Preview Render Implementation | DONE" "$DOC"
grep -q "M36.12 | Animation Artifact Verifier | DONE" "$DOC"
grep -q "M36.13 | Animation Output Card API Plan | DONE" "$DOC"

python3 - "$MILESTONES" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
expected = {
    "36.0": "DONE",
    "36.1": "DONE",
    "36.2": "DONE",
    "36.3": "DONE",
    "36.4": "DONE",
    "36.5": "DONE",
    "36.6": "DONE",
    "36.7": "DONE",
    "36.8": "DONE",
    "36.9": "DONE",
    "36.10": "DONE",
    "36.11": "DONE",
    "36.12": "DONE",
    "36.13": "DONE",
    "36.14": "DONE",
    "36.15": "PLANNED",
    "36.16": "PLANNED",
    "36.17": "PLANNED",
}
for milestone, status in expected.items():
    pattern = rf"## Milestone {re.escape(milestone)}:.*?\n\nStatus: ([^\n]+)"
    match = re.search(pattern, text, flags=re.S)
    if not match:
        raise SystemExit(f"missing Milestone {milestone}")
    actual = match.group(1).strip()
    if actual != status:
        raise SystemExit(f"Milestone {milestone} expected {status}, got {actual}")
PY

unexpected_animation_files="$(
  find apps scripts -type f \( -name '*animation*.py' -o -name '*animation*.ts' -o -name '*animation*.tsx' \) \
    ! -path 'apps/media-worker/app/animation_plan_validator.py' \
    ! -path 'apps/media-worker/app/animation_timeline_planner.py' \
    ! -path 'apps/media-worker/app/camera_animation_planner.py' \
    ! -path 'apps/media-worker/app/object_transform_animation_planner.py' \
    ! -path 'apps/media-worker/app/blender_animation_adapter.py' \
    ! -path 'apps/media-worker/app/animation_metadata_sidecar.py' \
    ! -path 'apps/media-worker/app/animation_metadata_validator.py' \
    ! -path 'apps/media-worker/app/animation_preview_renderer.py' \
    ! -path 'apps/media-worker/app/animation_artifact_verifier.py' \
    ! -path 'apps/gateway-api/app/media_animation_output_cards.py' \
    ! -path 'scripts/test-animation-output-card-api.sh' -print
)"
if [ -n "$unexpected_animation_files" ]; then
  echo "unexpected animation implementation source file found:" >&2
  echo "$unexpected_animation_files" >&2
  exit 1
fi

if grep -R "animation_reference_board\|animation_dashboard" apps configs >/dev/null; then
  echo "future animation dashboard/reference-board behavior found outside allowed docs/config tests" >&2
  exit 1
fi

if find . -type d \( -name node_modules -o -name dist -o -name build -o -name .cache -o -name __pycache__ \) -print -quit | grep -q .; then
  echo "generated dependency/build/cache directory found in source checkout" >&2
  exit 1
fi

if git ls-files | grep -Ei '\.(mp4|webm|mov|gif|blend|glb|obj|fbx|mtl|safetensors|gguf|ckpt|pt|pth|zip|tar)$' >/dev/null; then
  echo "tracked animation/video/model/3D binary found" >&2
  exit 1
fi

if find . -type f \( -name "*.mp4" -o -name "*.webm" -o -name "*.mov" -o -name "*.gif" -o -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print -quit | grep -q .; then
  echo "generated animation/video/3D artifact found in source checkout" >&2
  exit 1
fi

echo "Animation pipeline foundation OK"
