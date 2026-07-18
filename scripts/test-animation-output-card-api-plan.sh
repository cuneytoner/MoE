#!/usr/bin/env bash
set -euo pipefail

DOC="docs/ops/303-animation-output-card-api-plan.md"
REVIEW="docs/ops/304-animation-output-card-api-plan-review-template.md"
EXAMPLE="configs/animation/animation-output-cards-response.example.json"
MILESTONES="docs/milestones.md"
CODEX_PROMPTS="docs/codex-prompts.md"
README="README.md"
ARCH="docs/architecture.md"

for path in "$DOC" "$REVIEW" "$EXAMPLE" "$MILESTONES" "$CODEX_PROMPTS" "$README" "$ARCH"; do
  if [ ! -f "$path" ]; then
    echo "missing animation output card API plan file: $path" >&2
    exit 1
  fi
done

jq empty "$EXAMPLE"
jq -e '.status == "ok"' "$EXAMPLE" >/dev/null
jq -e '.service == "gateway-animation-output-cards"' "$EXAMPLE" >/dev/null
jq -e '.runtime_scope == "runtime/media/animation"' "$EXAMPLE" >/dev/null
jq -e '.metadata_dir_available == true' "$EXAMPLE" >/dev/null
jq -e '.reports_dir_available == true' "$EXAMPLE" >/dev/null
jq -e '.card_count == 2' "$EXAMPLE" >/dev/null
jq -e '.invalid_count == 0' "$EXAMPLE" >/dev/null
jq -e '.preview_report_count == 1' "$EXAMPLE" >/dev/null
jq -e '.verified_preview_count == 1' "$EXAMPLE" >/dev/null
jq -e '.cards | length == 2' "$EXAMPLE" >/dev/null
jq -e '.cards[0].type == "animation" and .cards[1].type == "animation"' "$EXAMPLE" >/dev/null
jq -e '.cards[0].id == "animation:media/animation/metadata/object-transform-demo.json"' "$EXAMPLE" >/dev/null
jq -e '.cards[0].preview.available == false' "$EXAMPLE" >/dev/null
jq -e '.cards[0].relative_runtime_paths.declared_video_preview == "media/animation/previews/object-transform-demo.mp4"' "$EXAMPLE" >/dev/null
jq -e '.cards[0].verification.valid == true and .cards[0].verification.provenance_checked == false' "$EXAMPLE" >/dev/null
jq -e '.cards[1].preview.available == true' "$EXAMPLE" >/dev/null
jq -e '.cards[1].preview.frame_count == 8' "$EXAMPLE" >/dev/null
jq -e '.cards[1].preview.first_frame_relative_path == "media/animation/previews/object-transform-demo-preview/frames/frame-000001.png"' "$EXAMPLE" >/dev/null
jq -e '.cards[1].preview.format == "PNG"' "$EXAMPLE" >/dev/null
jq -e '.cards[1].verification.preview_report_valid == true and .cards[1].verification.runtime_preview_verified == true' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.read_only == true' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.generation_triggered == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.animation_execution_attempted == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.preview_render_attempted == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.runtime_assets_written == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.runtime_assets_modified == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.runtime_assets_deleted == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.external_process_started == false' "$EXAMPLE" >/dev/null
jq -e '.safety_flags.shell_execution == false' "$EXAMPLE" >/dev/null

if grep -R "/home/cuneyt/MoE/runtime\|/home/cuneyt/DiskD/Projects/MoE/codebase\|MoE_Models_Backup" "$EXAMPLE" >/dev/null; then
  echo "animation output card example leaked absolute repo/runtime/model path" >&2
  exit 1
fi

for heading in \
  "Purpose" \
  "Scope" \
  "Non-goals" \
  "Existing 3D output-card lessons" \
  "Planned endpoint" \
  "Gateway module boundary" \
  "Runtime scope" \
  "Metadata discovery" \
  "Report discovery" \
  "Direct-child scan rule" \
  "Scan and file-size limits" \
  "Metadata validation reuse" \
  "Artifact verifier reuse" \
  "Card identity" \
  "Top-level response contract" \
  "Card contract" \
  "Timeline and summary fields" \
  "Metadata-only cards" \
  "Preview report matching" \
  "Ambiguous report handling" \
  "Preview availability" \
  "Future video declaration" \
  "First-frame path" \
  "Binary serving boundary" \
  "Path safety" \
  "Symlink protection" \
  "Warning safety" \
  "Determinism" \
  "Failure behavior" \
  "Read-only safety flags" \
  "M36.14 implementation contract" \
  "Test strategy" \
  "Final decision"; do
  grep -q "## $heading" "$DOC"
done

for heading in \
  "Repository state" \
  "Plan document" \
  "Response example" \
  "Endpoint contract" \
  "Sync route requirement" \
  "Gateway module boundary" \
  "Fixed runtime scope" \
  "No public runtime override" \
  "Metadata root" \
  "Report root" \
  "Direct-child scanning" \
  "No recursive scan" \
  "Scan limits" \
  "File-size limits" \
  "Symlink handling" \
  "Metadata validator reuse" \
  "Artifact verifier reuse" \
  "Card identity" \
  "Card response fields" \
  "Metadata-only card" \
  "Preview matching" \
  "Ambiguous report handling" \
  "Preview availability" \
  "Future video behavior" \
  "First-frame path" \
  "No binary serving" \
  "Path containment" \
  "Warning sanitization" \
  "Response determinism" \
  "Failure isolation" \
  "Read-only flags" \
  "No Gateway implementation" \
  "No Dashboard changes" \
  "No runtime writes" \
  "M36.14 boundary" \
  "Regression results" \
  "Final decision"; do
  grep -q "## $heading" "$REVIEW"
done

[ "$(grep -c 'Status: PASS / FAIL / BLOCKED / NOT APPLICABLE' "$REVIEW")" -ge 37 ]

grep -q "GET /gateway/media/animation/cards" "$DOC"
grep -q "def media_animation_output_cards() -> dict\\[str, Any\\]" "$DOC"
grep -q "def build_animation_output_cards() -> dict\\[str, Any\\]" "$DOC"
grep -q "_build_animation_output_cards_from_root" "$DOC"
grep -q "production function must not accept a runtime root parameter" "$DOC"
grep -q "runtime/media/animation" "$DOC"
grep -q "metadata_dir.iterdir()" "$DOC"
grep -q "reports_dir.iterdir()" "$DOC"
grep -Fq 'rglob' "$DOC"
grep -Fq 'glob("**/*")' "$DOC"
grep -Fq 'os.walk' "$DOC"
grep -q "MAX_METADATA_SIDECARS = 200" "$DOC"
grep -q "MAX_PREVIEW_REPORTS = 200" "$DOC"
grep -q "MAX_METADATA_BYTES = 512 KiB" "$DOC"
grep -q "MAX_PREVIEW_REPORT_BYTES = 1 MiB" "$DOC"
grep -q "MAX_WARNINGS = 200" "$DOC"
grep -q "MAX_CARDS = 200" "$DOC"
grep -q "M36.9 metadata validator" "$DOC"
grep -q "M36.12 artifact verifier" "$DOC"
grep -q "must not duplicate" "$DOC"
grep -q "animation:<metadata-runtime-relative-path>" "$DOC"
grep -q "Metadata-only" "$DOC"
grep -q "preview.available=false" "$DOC"
grep -q "declared_video_preview" "$DOC"
grep -q "source_kind" "$DOC"
grep -q "source_request_sha256" "$DOC"
grep -q "canonical_plan_sha256" "$DOC"
grep -q "Filename-only" "$DOC"
grep -q "ambiguous_preview_reports" "$DOC"
grep -q "mtime" "$DOC"
grep -q "preview.available=true" "$DOC"
grep -q "valid=true" "$DOC"
grep -Fq 'frame-{frames[0]:06d}.png' "$DOC"
grep -q "base64" "$DOC"
grep -q "FileResponse" "$DOC"
grep -q "shell_execution" "$DOC"
grep -q "M36.14 may implement" "$DOC"

grep -q -- "- M36.12 Animation Artifact Verifier DONE" "$MILESTONES"
grep -q -- "- M36.13 Animation Output Card API Plan DONE" "$MILESTONES"
grep -q -- "- M36.14 Animation Output Card API DONE" "$MILESTONES"
grep -q -- "- M36.15 Dashboard Animation Cards UI PLANNED" "$MILESTONES"
grep -q -- "- M36.13 Animation Output Card API Plan DONE" "$CODEX_PROMPTS"
grep -q -- "- M36.14 Animation Output Card API DONE" "$CODEX_PROMPTS"
grep -q -- "- M36.15 Dashboard Animation Cards UI PLANNED" "$CODEX_PROMPTS"
grep -q "Completed through Milestone 36.14: Animation Output Card API" "$README"
grep -q "Milestone 36.15: Dashboard Animation Cards UI" "$README"
grep -q "M36.14 implements that read-only Gateway endpoint" "$ARCH"

if find apps/dashboard-ui -type f \( -name '*Animation*Cards*.tsx' -o -name '*animation*cards*.tsx' -o -name '*Animation*Cards*.ts' \) -print -quit | grep -q .; then
  echo "M36.15 Dashboard animation card component appears to have started" >&2
  exit 1
fi

if grep -R '/gateway/media/animation/preview\|render-preview\|execute-animation\|animation.*FileResponse\|base64.*animation' apps/gateway-api >/dev/null; then
  echo "binary serving or execution surface found in M36.13 scope" >&2
  exit 1
fi

if [ -d "runtime/media/animation" ] || [ -d "media/animation" ]; then
  echo "runtime animation directory was created in source checkout" >&2
  exit 1
fi

if rg -n "M36\\.15.*DONE|M37\\.0.*DONE|M38" README.md docs scripts --glob '!scripts/test-animation-output-card-api-plan.sh' --glob '!scripts/test-animation-output-card-api.sh' --glob '!scripts/test-animation-preview-renderer.sh' >/dev/null; then
  echo "future milestone state changed unexpectedly" >&2
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

echo "Animation output card API plan OK"
