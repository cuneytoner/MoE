#!/usr/bin/env bash
set -euo pipefail

APPLY="${APPLY:-0}"
COMFYUI_URL="${COMFYUI_URL:-http://127.0.0.1:8188}"
RUNTIME_ROOT="${RUNTIME_ROOT:-/home/cuneyt/MoE/runtime}"
OUTPUT_DIR="${MEDIA_IMAGE_OUTPUT_DIR:-$RUNTIME_ROOT/media/outputs/images}"
WORKFLOW_DIR="$RUNTIME_ROOT/media/workflows"
WORKFLOW_JSON="$WORKFLOW_DIR/flux-schnell-first-image.json"
PROMPT="${PROMPT:-realistic sun shaded wooden pergola in a small garden, natural pine wood, covered roof, soft daylight}"
WIDTH="${WIDTH:-512}"
HEIGHT="${HEIGHT:-512}"
STEPS="${STEPS:-4}"
SEED="${SEED:-123456}"

echo "ComfyUI first Flux Schnell image"
echo "  apply: $APPLY"
echo "  ComfyUI url: $COMFYUI_URL"
echo "  output dir: $OUTPUT_DIR"
echo "  workflow json: $WORKFLOW_JSON"
echo "  prompt: $PROMPT"
echo "  size: ${WIDTH}x${HEIGHT}"
echo "  steps: $STEPS"

if [ "$APPLY" != "1" ]; then
  echo ""
  echo "DRY RUN: no workflow will be submitted."
  echo "Run APPLY=1 scripts/comfyui-first-image.sh only after models are downloaded, linked, and smoke test is ready."
  exit 0
fi

mkdir -p "$OUTPUT_DIR" "$WORKFLOW_DIR"

if ! curl -fsS "$COMFYUI_URL/" >/dev/null 2>&1; then
  echo "FAIL: ComfyUI is not reachable at $COMFYUI_URL"
  exit 1
fi

REQUIRE_READY=1 "$(dirname "${BASH_SOURCE[0]}")/check-flux-schnell-models.sh"
APPLY=1 "$(dirname "${BASH_SOURCE[0]}")/link-comfyui-models.sh"
"$(dirname "${BASH_SOURCE[0]}")/comfyui-flux-smoke-test.sh"
"$(dirname "${BASH_SOURCE[0]}")/comfyui-vram-status.sh" || true

python3 - "$COMFYUI_URL" "$WORKFLOW_JSON" "$PROMPT" "$WIDTH" "$HEIGHT" "$STEPS" "$SEED" <<'PY'
import json
import pathlib
import sys
import urllib.request

url, workflow_path, prompt, width, height, steps, seed = sys.argv[1:]
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
    "8": {"class_type": "SaveImage", "inputs": {"filename_prefix": "moe_flux_first", "images": ["4", 0]}},
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

echo "PASS: Workflow submitted to ComfyUI."
echo "INFO: Expected output location: $OUTPUT_DIR"
echo "INFO: Prompt/workflow id is printed above by ComfyUI."
