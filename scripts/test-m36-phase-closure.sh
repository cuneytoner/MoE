#!/usr/bin/env bash
set -euo pipefail

MILESTONES="docs/milestones.md"
CODEX_PROMPTS="docs/codex-prompts.md"
README="README.md"
DOC="docs/ops/311-m36-phase-closure.md"
RUNNER="scripts/run-m36-real-blender-acceptance.sh"
SCENE="scripts/animation/create-m36-acceptance-scene.py"

for path in "$MILESTONES" "$CODEX_PROMPTS" "$README" "$DOC" "$RUNNER" "$SCENE"; do
  [ -f "$path" ] || {
    echo "missing M36 closure file: $path" >&2
    exit 1
  }
done

python3 - "$MILESTONES" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
for minor in range(18):
    milestone = f"36.{minor}"
    match = re.search(rf"## Milestone {re.escape(milestone)}:.*?\n\nStatus: ([^\n]+)", text, flags=re.S)
    if not match:
        raise SystemExit(f"missing Milestone {milestone}")
    if match.group(1).strip() != "DONE":
        raise SystemExit(f"Milestone {milestone} is not DONE")
match = re.search(r"## Milestone 37\.0:.*?\n\nStatus: ([^\n]+)", text, flags=re.S)
if not match or match.group(1).strip() != "PLANNED":
    raise SystemExit("M37.0 must remain PLANNED")
PY

grep -q "M36 Animation Pipeline CLOSED" "$MILESTONES"
grep -q "Latest completed: M36.17 M36 Phase Closure." "$MILESTONES"
grep -q "Next planned: M37.0 Media Workflow Orchestrator." "$MILESTONES"
grep -q -- "- M36.17 M36 Phase Closure DONE" "$CODEX_PROMPTS"
grep -q -- "- M37.0 Media Workflow Orchestrator PLANNED" "$CODEX_PROMPTS"
grep -q "Completed through Milestone 36.17: M36 Phase Closure" "$README"
grep -q "Milestone 37.0: Media Workflow Orchestrator" "$README"

grep -q 'BLENDER_BIN="${BLENDER_BIN:-$HOME/Apps/blender-4.5.11/blender}"' "$RUNNER"
grep -q "BLENDER_EEVEE_NEXT" "$RUNNER"
grep -q "REAL_ANIMATION_GENERATION=1" "$RUNNER"
grep -q "REAL_ANIMATION_PREVIEW_RENDER=1" "$RUNNER"
grep -q -- "--execute-animation" "$RUNNER"
grep -q -- "--render-preview" "$RUNNER"
grep -q "frame-000001.png" "$DOC"
grep -q "/home/cuneyt/MoE/runtime/media/animation/previews/m36-acceptance/frames" "$DOC"
grep -q "no workflow orchestrator" "$DOC"

if rg -n "workflow_orchestrator|media_workflow_orchestrator" apps configs >/dev/null; then
  echo "M37 implementation appears to have started" >&2
  exit 1
fi

if find . -type f \( -name '*.blend' -o -name 'frame-*.png' -o -name '*.mp4' -o -name '*.webm' -o -name '*.gif' -o -name '*.mov' \) -print -quit | grep -q .; then
  echo "generated animation binary artifact found in source checkout" >&2
  exit 1
fi

echo "M36 phase closure OK"
