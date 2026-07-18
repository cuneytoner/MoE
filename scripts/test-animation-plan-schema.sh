#!/usr/bin/env bash
set -euo pipefail

SCHEMA="configs/animation/animation-plan.schema.json"
EXAMPLE="configs/animation/animation-plan.example.yaml"
DOC="docs/ops/279-animation-plan-schema.md"
REVIEW="docs/ops/280-animation-plan-schema-review-template.md"
MILESTONES="docs/milestones.md"

for path in "$SCHEMA" "$EXAMPLE" "$DOC" "$REVIEW" "$MILESTONES"; do
  if [ ! -f "$path" ]; then
    echo "missing animation plan schema file: $path" >&2
    exit 1
  fi
done

jq empty "$SCHEMA"

jq -e '.["$schema"] == "https://json-schema.org/draft/2020-12/schema"' "$SCHEMA" >/dev/null
jq -e '.["$id"] == "urn:moe:animation-plan-schema:1.0"' "$SCHEMA" >/dev/null
jq -e '.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '(.required | sort) == ["description","mode","operator_review_required","outputs","plan_id","safety","scene","schema_version","structural_certification","timeline","title","tracks","visual_reference_only"]' "$SCHEMA" >/dev/null
jq -e '.properties.schema_version.const == "1.0"' "$SCHEMA" >/dev/null
jq -e '.properties.mode.enum == ["dry_run"]' "$SCHEMA" >/dev/null
jq -e '.properties.visual_reference_only.const == true' "$SCHEMA" >/dev/null
jq -e '.properties.structural_certification.const == false' "$SCHEMA" >/dev/null
jq -e '.properties.operator_review_required.const == true' "$SCHEMA" >/dev/null
jq -e '.["$defs"].timeline.properties.fps.minimum == 1 and .["$defs"].timeline.properties.fps.maximum == 120' "$SCHEMA" >/dev/null
jq -e '.properties.tracks.maxItems == 64' "$SCHEMA" >/dev/null
jq -e '.["$defs"].track.properties.keyframes.maxItems == 1000' "$SCHEMA" >/dev/null
jq -e '(.["$defs"].track.properties.target_type.enum | sort) == ["camera","object"]' "$SCHEMA" >/dev/null
jq -e '(.["$defs"].track.properties.property.enum | sort) == ["location","rotation_euler","scale","transform","visibility"]' "$SCHEMA" >/dev/null
jq -e '(.["$defs"].track.properties.interpolation.enum | sort) == ["bezier","constant","linear"]' "$SCHEMA" >/dev/null
jq -e '.["$defs"].track.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.["$defs"].keyframe.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.["$defs"].vector3.minItems == 3 and .["$defs"].vector3.maxItems == 3 and .["$defs"].vector3.items.type == "number"' "$SCHEMA" >/dev/null
jq -e '.["$defs"].previewOutput.properties.enabled.const == false' "$SCHEMA" >/dev/null
jq -e '.["$defs"].safety.properties.runtime_write_planned.const == false' "$SCHEMA" >/dev/null
jq -e '.["$defs"].runtimeRelativePreviewPath.pattern | contains("^media/animation/previews/")' "$SCHEMA" >/dev/null
jq -e '.["$defs"].runtimeRelativeMetadataPath.pattern | contains("^media/animation/metadata/")' "$SCHEMA" >/dev/null

grep -q 'schema_version: "1.0"' "$EXAMPLE"
grep -q 'mode: "dry_run"' "$EXAMPLE"
grep -q 'visual_reference_only: true' "$EXAMPLE"
grep -q 'structural_certification: false' "$EXAMPLE"
grep -q 'operator_review_required: true' "$EXAMPLE"
grep -q 'real_animation_enabled: false' "$EXAMPLE"
grep -q 'blender_execution_enabled: false' "$EXAMPLE"
grep -q 'preview_render_enabled: false' "$EXAMPLE"
grep -q 'runtime_write_planned: false' "$EXAMPLE"
grep -q 'target_type: "camera"' "$EXAMPLE"

if [ "$(grep -c '^[[:space:]]*- frame:' "$EXAMPLE")" -lt 2 ]; then
  echo "animation example should contain at least two keyframes" >&2
  exit 1
fi

if grep -E 'relative_runtime_path: "/|relative_runtime_path: "\.\.|/home/cuneyt|MoE_Models_Backup|DiskD/Projects/MoE/codebase' "$EXAMPLE" >/dev/null; then
  echo "unsafe path found in animation example config" >&2
  exit 1
fi

if grep -E '/home/cuneyt|MoE_Models_Backup|DiskD/Projects/MoE/codebase' "$SCHEMA" "$EXAMPLE" >/dev/null; then
  echo "source/model/host path marker found in schema or example" >&2
  exit 1
fi

grep -q "M36.1 defines" "$DOC"
grep -q "M36.2 adds the source-only validator" "$DOC"
grep -q "M36.2 implements loading plus structural and timeline/keyframe semantic validation" "$DOC"
grep -q "Status: PASS / FAIL / BLOCKED / NOT APPLICABLE" "$REVIEW"
grep -q -- "- M36.0 Animation Pipeline Foundation and Roadmap DONE" "$MILESTONES"
grep -q -- "- M36.1 Animation Plan Schema DONE" "$MILESTONES"
grep -q -- "- M36.2 Animation Plan Validator DONE" "$MILESTONES"
grep -q -- "- M36.3 Timeline and Keyframe Planner Core DONE" "$MILESTONES"
grep -q -- "- M36.4 Camera Animation Planner DONE" "$MILESTONES"
grep -q -- "- M36.5 Object Transform Animation Planner DONE" "$MILESTONES"
grep -q -- "- M36.6 Blender Animation Adapter Plan DONE" "$MILESTONES"
grep -q -- "- M36.7 Guarded Blender Animation Implementation DONE" "$MILESTONES"
grep -q -- "- M36.8 Animation Metadata Sidecar Writer DONE" "$MILESTONES"
grep -q -- "- M36.9 Animation Metadata Validator DONE" "$MILESTONES"
grep -q -- "- M36.10 Preview Render Safety Plan DONE" "$MILESTONES"
grep -q -- "- M36.11 Guarded Preview Render Implementation DONE" "$MILESTONES"
grep -q -- "- M36.12 Animation Artifact Verifier DONE" "$MILESTONES"
grep -q -- "- M36.13 Animation Output Card API Plan DONE" "$MILESTONES"
grep -q -- "- M36.14 Animation Output Card API PLANNED" "$MILESTONES"

unexpected_animation_files="$(
  find apps -type f \( -name '*animation*.py' -o -name '*animation*.ts' -o -name '*animation*.tsx' \) \
    ! -path 'apps/media-worker/app/animation_plan_validator.py' \
    ! -path 'apps/media-worker/app/animation_timeline_planner.py' \
    ! -path 'apps/media-worker/app/camera_animation_planner.py' \
    ! -path 'apps/media-worker/app/object_transform_animation_planner.py' \
    ! -path 'apps/media-worker/app/blender_animation_adapter.py' \
    ! -path 'apps/media-worker/app/animation_metadata_sidecar.py' \
    ! -path 'apps/media-worker/app/animation_metadata_validator.py' \
    ! -path 'apps/media-worker/app/animation_preview_renderer.py' \
    ! -path 'apps/media-worker/app/animation_artifact_verifier.py' -print
)"
if [ -n "$unexpected_animation_files" ]; then
  echo "unexpected animation implementation source file found:" >&2
  echo "$unexpected_animation_files" >&2
  exit 1
fi

if grep -R "animation_output_card\|animation_reference_board\|animation_dashboard" apps configs >/dev/null; then
  echo "M36.13+ animation output card behavior found in apps/configs" >&2
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

echo "Animation plan schema OK"
