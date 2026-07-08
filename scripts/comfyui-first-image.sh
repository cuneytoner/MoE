#!/usr/bin/env bash
set -euo pipefail

APPLY="${APPLY:-0}"
COMFYUI_URL="${COMFYUI_URL:-http://127.0.0.1:8188}"
RUNTIME_ROOT="${RUNTIME_ROOT:-/home/cuneyt/MoE/runtime}"
COMFYUI_RUNTIME_DIR="${COMFYUI_RUNTIME_DIR:-$RUNTIME_ROOT/media-engines/comfyui}"
COMFYUI_LOG_FILE="${COMFYUI_LOG_FILE:-$COMFYUI_RUNTIME_DIR/logs/comfyui.log}"
OUTPUT_DIR="${MEDIA_IMAGE_OUTPUT_DIR:-$RUNTIME_ROOT/media/outputs/images}"
FLUX_FIRST_DIR="$OUTPUT_DIR/flux-first"
COMFYUI_OUTPUT_DIR="$COMFYUI_RUNTIME_DIR/ComfyUI/output"
WORKFLOW_DIR="$RUNTIME_ROOT/media/workflows"
WORKFLOW_JSON="$WORKFLOW_DIR/flux-schnell-first-image.json"
PROMPT="${PROMPT:-realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight}"
WIDTH="${WIDTH:-512}"
HEIGHT="${HEIGHT:-512}"
STEPS="${STEPS:-4}"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
FILENAME_PREFIX="${FILENAME_PREFIX:-moe_flux_first_${RUN_ID}}"
SEED="${SEED:-$(date +%s)}"
STRICT_NEW_OUTPUT="${STRICT_NEW_OUTPUT:-0}"
SCRIPT_NAME="scripts/comfyui-first-image.sh"
WORKFLOW_NAME="flux-schnell-first-image"
MODEL_FAMILY="flux"
MODEL_NAME="flux1-schnell"
SAFETY_LABEL="visual_reference_only"

echo "ComfyUI first Flux Schnell image"
echo "  apply: $APPLY"
echo "  ComfyUI url: $COMFYUI_URL"
echo "  output dir: $OUTPUT_DIR"
echo "  flux-first dir: $FLUX_FIRST_DIR"
echo "  ComfyUI output dir: $COMFYUI_OUTPUT_DIR"
echo "  workflow json: $WORKFLOW_JSON"
echo "  prompt: $PROMPT"
echo "  size: ${WIDTH}x${HEIGHT}"
echo "  steps: $STEPS"
echo "  seed: $SEED"
echo "  filename prefix: $FILENAME_PREFIX"
echo "  strict new output: $STRICT_NEW_OUTPUT"

write_image_metadata() {
  local image_path="$1"
  local metadata_path="${image_path%.*}.json"

  if [ ! -f "$image_path" ]; then
    echo "WARN: cannot write metadata, output image missing: $image_path"
    return 0
  fi

  python3 - "$image_path" "$metadata_path" "$RUNTIME_ROOT" "$PROMPT" "$WIDTH" "$HEIGHT" "$STEPS" "$SEED" "$FILENAME_PREFIX" "$SCRIPT_NAME" "$WORKFLOW_NAME" "$MODEL_FAMILY" "$MODEL_NAME" "$SAFETY_LABEL" <<'PY'
import json
import pathlib
import sys
from datetime import datetime, timezone

(
    image_path,
    metadata_path,
    runtime_root,
    prompt,
    width,
    height,
    steps,
    seed,
    filename_prefix,
    script_name,
    workflow_name,
    model_family,
    model_name,
    safety_label,
) = sys.argv[1:]

image = pathlib.Path(image_path)
metadata = pathlib.Path(metadata_path)
runtime = pathlib.Path(runtime_root)

try:
    relative_runtime_path = image.relative_to(runtime).as_posix()
except ValueError:
    relative_runtime_path = ""

payload = {
    "schema_version": "1.0",
    "asset_type": "image",
    "asset_name": image.name,
    "asset_path": str(image),
    "relative_runtime_path": relative_runtime_path,
    "created_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    "source": "comfyui",
    "script": script_name,
    "workflow": workflow_name,
    "model_family": model_family,
    "model_name": model_name,
    "prompt": prompt,
    "negative_prompt": None,
    "width": int(width),
    "height": int(height),
    "steps": int(steps),
    "seed": int(seed),
    "filename_prefix": filename_prefix,
    "safety_label": safety_label,
    "notes": "Generated visual reference. Not a construction document.",
}

metadata.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
  echo "METADATA: $metadata_path"
}

if [ "$APPLY" != "1" ]; then
  echo ""
  echo "DRY RUN: no workflow will be submitted."
  echo "Run APPLY=1 scripts/comfyui-first-image.sh only after models are downloaded, linked, and smoke test is ready."
  exit 0
fi

mkdir -p "$OUTPUT_DIR" "$FLUX_FIRST_DIR" "$WORKFLOW_DIR"

if ! curl -fsS "$COMFYUI_URL/" >/dev/null 2>&1; then
  echo "FAIL: ComfyUI is not reachable at $COMFYUI_URL"
  exit 1
fi

REQUIRE_READY=1 "$(dirname "${BASH_SOURCE[0]}")/check-flux-schnell-models.sh"
APPLY=1 "$(dirname "${BASH_SOURCE[0]}")/link-comfyui-models.sh"
"$(dirname "${BASH_SOURCE[0]}")/comfyui-flux-smoke-test.sh"
"$(dirname "${BASH_SOURCE[0]}")/comfyui-vram-status.sh" || true

marker="$(mktemp /tmp/moe-comfyui-first-image-marker.XXXXXX)"
touch "$marker"

submit_response="$(python3 - "$COMFYUI_URL" "$WORKFLOW_JSON" "$PROMPT" "$WIDTH" "$HEIGHT" "$STEPS" "$SEED" "$FILENAME_PREFIX" <<'PY'
import json
import pathlib
import sys
import urllib.request

url, workflow_path, prompt, width, height, steps, seed, filename_prefix = sys.argv[1:]
workflow = {
    "3": {
        "class_type": "KSampler",
        "inputs": {
            "seed": int(seed),
            "steps": int(steps),
            "cfg": 1.0,
            "sampler_name": "euler",
            "scheduler": "simple",
            "denoise": 1.0,
            "model": ["10", 0],
            "positive": ["6", 0],
            "negative": ["7", 0],
            "latent_image": ["5", 0],
        },
    },
    "4": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["11", 0]}},
    "5": {"class_type": "EmptyLatentImage", "inputs": {"width": int(width), "height": int(height), "batch_size": 1}},
    "6": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["12", 0]}},
    "7": {"class_type": "CLIPTextEncode", "inputs": {"text": "", "clip": ["12", 0]}},
    "8": {"class_type": "SaveImage", "inputs": {"filename_prefix": filename_prefix, "images": ["4", 0]}},
    "10": {"class_type": "UNETLoader", "inputs": {"unet_name": "flux1-schnell.safetensors", "weight_dtype": "default"}},
    "11": {"class_type": "VAELoader", "inputs": {"vae_name": "ae.safetensors"}},
    "12": {
        "class_type": "DualCLIPLoader",
        "inputs": {
            "clip_name1": "clip_l.safetensors",
            "clip_name2": "t5xxl_fp8_e4m3fn.safetensors",
            "type": "flux",
        },
    },
}
path = pathlib.Path(workflow_path)
path.write_text(json.dumps(workflow, indent=2), encoding="utf-8")
payload = json.dumps({"prompt": workflow}).encode("utf-8")
request = urllib.request.Request(f"{url.rstrip('/')}/prompt", data=payload, headers={"Content-Type": "application/json"})
with urllib.request.urlopen(request, timeout=30) as response:
    body = response.read().decode("utf-8")
print(body)
PY
)"

printf '%s\n' "$submit_response"
prompt_id="$(printf '%s\n' "$submit_response" | sed -n 's/.*"prompt_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"

echo "PASS: Workflow submitted to ComfyUI."
if [ -n "$prompt_id" ]; then
  echo "INFO: prompt_id: $prompt_id"
else
  echo "WARN: prompt_id was not found in ComfyUI response."
fi

echo "Polling for new image outputs for up to 120 seconds"
echo "  checked dirs:"
echo "    $COMFYUI_OUTPUT_DIR"
echo "    $OUTPUT_DIR"

found_list="$(mktemp /tmp/moe-comfyui-first-image-found.XXXXXX)"
for attempt in $(seq 1 120); do
  : >"$found_list"
  for search_dir in "$COMFYUI_OUTPUT_DIR" "$OUTPUT_DIR"; do
    if [ -d "$search_dir" ]; then
      find "$search_dir" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -newer "$marker" -print 2>/dev/null >>"$found_list" || true
    fi
  done
  if [ -s "$found_list" ]; then
    echo "PASS: new image file(s) detected"
    copied=0
    while IFS= read -r image_path; do
      [ -n "$image_path" ] || continue
      target="$FLUX_FIRST_DIR/$(basename "$image_path")"
      if [ "$image_path" = "$target" ]; then
        echo "OUTPUT: $target"
      else
        if [ -e "$target" ]; then
          stem="${target%.*}"
          ext="${target##*.}"
          target="${stem}-$(date +%Y%m%d%H%M%S).${ext}"
        fi
        cp "$image_path" "$target"
        echo "COPIED: $target"
      fi
      write_image_metadata "$target"
      copied=1
    done <"$found_list"
    if [ "$copied" = "1" ]; then
      echo "PASS: generated image(s) surfaced under $FLUX_FIRST_DIR"
      exit 0
    fi
  fi
  sleep 1
done

echo "FAIL: no new image files were found after 120 seconds."
if [ -n "$prompt_id" ]; then
  echo "prompt_id: $prompt_id"
else
  echo "prompt_id: unavailable"
fi
echo "Output dirs checked:"
echo "  $COMFYUI_OUTPUT_DIR"
echo "  $OUTPUT_DIR"

latest_existing="$(mktemp /tmp/moe-comfyui-first-image-existing.XXXXXX)"
if [ -d "$FLUX_FIRST_DIR" ]; then
  find "$FLUX_FIRST_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 10 >"$latest_existing" || true
fi

if [ -s "$latest_existing" ] && [ "$STRICT_NEW_OUTPUT" != "1" ]; then
  echo "WARN: no truly new image was detected, but existing flux-first images are present."
  echo "WARN: ComfyUI may have reused cache or produced no new file for this prompt."
  echo "Latest existing images:"
  sed 's/^[^ ]* //' "$latest_existing"
  echo "Set STRICT_NEW_OUTPUT=1 to fail when a new image is not detected."
  exit 0
fi

if [ -s "$latest_existing" ]; then
  echo "Latest existing images:"
  sed 's/^[^ ]* //' "$latest_existing"
fi

echo "ComfyUI log tail:"
if [ -f "$COMFYUI_LOG_FILE" ]; then
  tail -n 80 "$COMFYUI_LOG_FILE" || true
else
  echo "  missing log file: $COMFYUI_LOG_FILE"
fi
exit 1
