#!/usr/bin/env bash
set -euo pipefail

DOC="docs/ops/297-preview-render-safety-plan.md"
REVIEW="docs/ops/298-preview-render-safety-plan-review-template.md"
SCHEMA="configs/animation/preview-render-request.schema.json"
EXAMPLE="configs/animation/preview-render-request.example.json"
OP_PLAN="configs/animation/preview-render-operation-plan.example.json"
MILESTONES="docs/milestones.md"
CODEX_PROMPTS="docs/codex-prompts.md"
README="README.md"

for path in "$DOC" "$REVIEW" "$SCHEMA" "$EXAMPLE" "$OP_PLAN" "$MILESTONES" "$CODEX_PROMPTS" "$README"; do
  if [ ! -f "$path" ]; then
    echo "missing preview render safety file: $path" >&2
    exit 1
  fi
done

jq empty "$SCHEMA"
jq empty "$EXAMPLE"
jq empty "$OP_PLAN"

jq -e '.["$schema"] == "https://json-schema.org/draft/2020-12/schema"' "$SCHEMA" >/dev/null
jq -e '.["$id"] == "urn:moe:animation-preview-render-request:1.0"' "$SCHEMA" >/dev/null
jq -e '.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.schema_version.const == "1.0"' "$SCHEMA" >/dev/null
jq -e '.properties.request_type.const == "animation_preview_render_request"' "$SCHEMA" >/dev/null
jq -e '.properties.render_mode.const == "sampled_frames"' "$SCHEMA" >/dev/null
jq -e '.properties.render.properties.format.const == "PNG"' "$SCHEMA" >/dev/null
jq -e '.properties.render.properties.engine.const == "BLENDER_EEVEE_NEXT"' "$SCHEMA" >/dev/null
jq -e '.properties.frame_selection.properties.sample_count.minimum == 2' "$SCHEMA" >/dev/null
jq -e '.properties.frame_selection.properties.sample_count.maximum == 24' "$SCHEMA" >/dev/null
jq -e '.properties.frame_selection.properties.include_start_frame.const == true' "$SCHEMA" >/dev/null
jq -e '.properties.frame_selection.properties.include_end_frame.const == true' "$SCHEMA" >/dev/null
jq -e '.properties.render.properties.width.maximum == 1920' "$SCHEMA" >/dev/null
jq -e '.properties.render.properties.height.maximum == 1080' "$SCHEMA" >/dev/null
jq -e '.properties.render.properties.width.minimum == 64' "$SCHEMA" >/dev/null
jq -e '.properties.render.properties.height.minimum == 64' "$SCHEMA" >/dev/null
jq -e '.properties.render.properties.resolution_percentage.const == 100' "$SCHEMA" >/dev/null
jq -e '.properties.output.properties.filename_pattern.const == "frame-{frame:06d}.png"' "$SCHEMA" >/dev/null
jq -e '.properties.output.properties.overwrite_existing.const == false' "$SCHEMA" >/dev/null
jq -e '.properties.limits.properties.max_frames.const == 24' "$SCHEMA" >/dev/null
jq -e '.properties.limits.properties.max_total_output_bytes.const == 536870912' "$SCHEMA" >/dev/null
jq -e '.properties.limits.properties.timeout_seconds.maximum == 300' "$SCHEMA" >/dev/null
jq -e '.properties.camera_id == {"$ref":"#/$defs/safeIdentifier"}' "$SCHEMA" >/dev/null
jq -e '.["$defs"].safeIdentifier.pattern == "^[a-z0-9][a-z0-9-]*$"' "$SCHEMA" >/dev/null
jq -e '.properties.safety.properties.real_animation_enabled.const == false' "$SCHEMA" >/dev/null
jq -e '.properties.safety.properties.preview_render_enabled.const == false' "$SCHEMA" >/dev/null
jq -e '.properties.safety.properties.runtime_write_planned.const == false' "$SCHEMA" >/dev/null
jq -e '.properties.safety.properties.blend_file_save_planned.const == false' "$SCHEMA" >/dev/null
jq -e '.properties.safety.properties.video_encode_planned.const == false' "$SCHEMA" >/dev/null
jq -e '.properties.safety.properties.external_process_planned.const == false' "$SCHEMA" >/dev/null
jq -e '.properties.frame_selection.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.render.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.output.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.limits.additionalProperties == false' "$SCHEMA" >/dev/null
jq -e '.properties.safety.additionalProperties == false' "$SCHEMA" >/dev/null

jq -e '.request_type == "animation_preview_render_request"' "$EXAMPLE" >/dev/null
jq -e '.render_mode == "sampled_frames"' "$EXAMPLE" >/dev/null
jq -e '.render.format == "PNG"' "$EXAMPLE" >/dev/null
jq -e '.render.engine == "BLENDER_EEVEE_NEXT"' "$EXAMPLE" >/dev/null
jq -e '.camera_id == "camera"' "$EXAMPLE" >/dev/null
jq -e '.frame_selection.sample_count == 8' "$EXAMPLE" >/dev/null
jq -e '.frame_selection.include_start_frame == true and .frame_selection.include_end_frame == true' "$EXAMPLE" >/dev/null
jq -e '.render.width == 1280 and .render.height == 720 and .render.resolution_percentage == 100' "$EXAMPLE" >/dev/null
jq -e '.output.relative_runtime_directory == "media/animation/previews/object-transform-demo-preview/frames"' "$EXAMPLE" >/dev/null
jq -e '.output.overwrite_existing == false' "$EXAMPLE" >/dev/null
jq -e '.limits.max_frames == 24 and .limits.max_total_output_bytes == 536870912 and .limits.timeout_seconds == 300' "$EXAMPLE" >/dev/null
jq -e '.safety.real_animation_enabled == false and .safety.preview_render_enabled == false and .safety.runtime_write_planned == false' "$EXAMPLE" >/dev/null
jq -e '.safety.blend_file_save_planned == false and .safety.video_encode_planned == false and .safety.external_process_planned == false' "$EXAMPLE" >/dev/null
jq -e '.source_request_sha256 | test("^[a-f0-9]{64}$")' "$EXAMPLE" >/dev/null
jq -e '.canonical_plan_sha256 | test("^[a-f0-9]{64}$")' "$EXAMPLE" >/dev/null

jq -e '.plan_type == "animation_preview_render_operation_plan"' "$OP_PLAN" >/dev/null
jq -e '.status == "planned"' "$OP_PLAN" >/dev/null
jq -e '.render_mode == "sampled_frames"' "$OP_PLAN" >/dev/null
jq -e '.frames == [1,18,35,52,69,86,103,120]' "$OP_PLAN" >/dev/null
jq -e '.operation_count == (.operation_types | length)' "$OP_PLAN" >/dev/null
for operation_type in \
  validate_preview_request \
  validate_adapter_request \
  resolve_camera \
  select_preview_frames \
  validate_output_directory \
  snapshot_render_settings \
  apply_animation_operations \
  configure_preview_render \
  render_preview_frame \
  verify_preview_frame \
  restore_render_settings \
  publish_preview_directory; do
  jq -e --arg operation_type "$operation_type" '.operation_types | index($operation_type)' "$OP_PLAN" >/dev/null
done

if jq -e '.operation_types[] | select(. == "run_ffmpeg" or . == "encode_video" or . == "save_blend" or . == "create_camera" or . == "delete_object" or . == "run_shell" or . == "execute_python" or . == "launch_blender" or . == "upload_artifact")' "$OP_PLAN" >/dev/null; then
  echo "preview operation plan contains forbidden operation type" >&2
  exit 1
fi

for heading in \
  "Purpose" \
  "Scope" \
  "Non-goals" \
  "Existing Animation Pipeline Integration" \
  "Preview Request Contract" \
  "Source And Hash Validation" \
  "Camera Resolution" \
  "Frame Selection" \
  "Frame Limits" \
  "Resolution And Pixel Limits" \
  "Render Engine Allowlist" \
  "Render Settings Boundary" \
  "M36.7 Execution Relationship" \
  "Execution Guards" \
  "Runtime Output Root" \
  "Output Path Safety" \
  "Staging Behavior" \
  "Atomic Publish" \
  "Overwrite Policy" \
  "Output Size Limit" \
  "Timeout Behavior" \
  "Failure And Partial Behavior" \
  "Preview Report" \
  "Blender Import Boundary" \
  "No-ffmpeg Boundary" \
  "M36.11 Implementation Contract" \
  "Test Strategy" \
  "Final Decision"; do
  grep -q "## $heading" "$DOC"
done

for heading in \
  "Repository State" \
  "Preview Request Schema" \
  "Preview Request Example" \
  "Operation Plan Example" \
  "Source Validation" \
  "Hash Validation" \
  "Camera Resolution" \
  "Frame Selection" \
  "Frame Limits" \
  "Resolution Limits" \
  "Pixel Budget" \
  "Render Engine" \
  "Render Settings Boundary" \
  "Animation Execution Guards" \
  "Preview Render Guards" \
  "Runtime Output Root" \
  "Output Path Safety" \
  "Symlink Handling" \
  "Staging" \
  "Atomic Publish" \
  "Overwrite Policy" \
  "Size Limit" \
  "Timeout" \
  "Failure Behavior" \
  "Render Settings Restore" \
  "No Video Encoding" \
  "No Ffmpeg" \
  "No Blender Implementation" \
  "No Runtime Writes" \
  "M36.11 Boundary" \
  "Regression Results" \
  "Final Decision"; do
  grep -q "## $heading" "$REVIEW"
done

if [ "$(grep -c "Status: PASS / FAIL / BLOCKED / NOT APPLICABLE" "$REVIEW")" -lt 32 ]; then
  echo "review template should include status fields for every section" >&2
  exit 1
fi

grep -q "total_pixel_budget = sample_count \* width \* height" "$DOC"
grep -q "49,766,400 pixels" "$DOC"
grep -q "frame_i = start_frame + (i \* (end_frame - start_frame)) // (N - 1)" "$DOC"
grep -q "first frame equals \`start_frame\`" "$DOC"
grep -q "last frame equals \`end_frame\`" "$DOC"
grep -q "bpy.data.objects.get(camera_id)" "$DOC"
grep -q "scene camera" "$DOC"
grep -q "automatic camera creation" "$DOC"
grep -q "REAL_ANIMATION_GENERATION=1" "$DOC"
grep -q "REAL_ANIMATION_PREVIEW_RENDER=1" "$DOC"
grep -q -- "--execute-animation" "$DOC"
grep -q -- "--render-preview" "$DOC"
grep -q "Request safety fields are documentation and validation signals only" "$DOC"
grep -q "/home/cuneyt/MoE/runtime/media/animation" "$DOC"
grep -q "media/animation/previews/<preview-id>/frames" "$DOC"
grep -q "Existing final output is a controlled failure" "$DOC"
grep -q "staging" "$DOC"
grep -q "atomically rename" "$DOC"
grep -q "no partial final publish" "$DOC"
grep -q "536870912" "$DOC"
grep -q "Maximum timeout is 300 seconds" "$DOC"
grep -q "snapshot" "$DOC"
grep -q "restore settings in \`finally\`" "$DOC"
grep -q "M36.11 must not call external \`ffmpeg\`" "$DOC"
grep -q "must not produce" "$DOC"

grep -q -- "- M36.9 Animation Metadata Validator DONE" "$MILESTONES"
grep -q -- "- M36.10 Preview Render Safety Plan DONE" "$MILESTONES"
grep -q -- "- M36.11 Guarded Preview Render Implementation DONE" "$MILESTONES"
grep -q -- "- M36.12 Animation Artifact Verifier DONE" "$MILESTONES"
grep -q -- "- M36.13 Animation Output Card API Plan DONE" "$MILESTONES"
grep -q -- "- M36.14 Animation Output Card API PLANNED" "$MILESTONES"
grep -q -- "- M36.10 Preview Render Safety Plan DONE" "$CODEX_PROMPTS"
grep -q -- "- M36.11 Guarded Preview Render Implementation DONE" "$CODEX_PROMPTS"
grep -q -- "- M36.12 Animation Artifact Verifier DONE" "$CODEX_PROMPTS"
grep -q -- "- M36.13 Animation Output Card API Plan DONE" "$CODEX_PROMPTS"
grep -q -- "- M36.14 Animation Output Card API PLANNED" "$CODEX_PROMPTS"
grep -q "Completed through Milestone 36.13: Animation Output Card API Plan" "$README"
grep -q "Milestone 36.14: Animation Output Card API" "$README"
grep -q "Milestone 37.0: Media Workflow Orchestrator" "$MILESTONES"
grep -q "Status: PLANNED" <(sed -n '/## Milestone 37.0:/,/## Future Homelab Ops/p' "$MILESTONES")

if rg -n '^import bpy|from bpy|mathutils|subprocess|render-preview' apps/media-worker/app configs/animation --glob '*.py' --glob '!blender_animation_adapter.py' --glob '!animation_preview_renderer.py' >/dev/null; then
  echo "preview safety milestone introduced forbidden Python import/execution surface" >&2
  exit 1
fi

if [ -d "runtime" ] || [ -d "media/animation/previews" ] || [ -d "configs/animation/previews" ]; then
  echo "runtime-like preview directory was created in source checkout" >&2
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

if find . -type f \( -name "frame-*.png" -o -name "*.mp4" -o -name "*.webm" -o -name "*.mov" -o -name "*.gif" -o -name "*.blend" -o -name "*.glb" -o -name "*.obj" -o -name "*.fbx" -o -name "*.mtl" \) -print -quit | grep -q .; then
  echo "generated preview/video/3D artifact found in source checkout" >&2
  exit 1
fi

echo "Preview render safety plan OK"
