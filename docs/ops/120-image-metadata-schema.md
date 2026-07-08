# Image Metadata Schema

This document defines the proposed sidecar JSON schema for generated image outputs.

## JSON Example

```json
{
  "schema_version": "1.0",
  "asset_type": "image",
  "asset_name": "moe_pergola_project_20260707_131301_00001_.png",
  "asset_path": "/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_project_20260707_131301_00001_.png",
  "relative_runtime_path": "media/outputs/images/flux-first/moe_pergola_project_20260707_131301_00001_.png",
  "created_at": "2026-07-07T10:13:14Z",
  "source": "comfyui",
  "script": "scripts/comfyui-first-image.sh",
  "workflow": "flux-schnell-first-image.json",
  "model_family": "flux",
  "model_name": "flux1-schnell",
  "prompt": "realistic ...",
  "negative_prompt": null,
  "width": 512,
  "height": 512,
  "steps": 4,
  "seed": 1783334081,
  "filename_prefix": "moe_pergola_project_20260707_131301",
  "safety_label": "visual_reference_only",
  "notes": "Generated visual reference. Not a construction document."
}
```

## Required Fields

- `schema_version`
- `asset_type`
- `asset_name`
- `asset_path`
- `relative_runtime_path`
- `created_at`
- `source`
- `script`
- `prompt`
- `width`
- `height`
- `steps`
- `seed`
- `safety_label`

## Optional Fields

- `negative_prompt`
- `workflow`
- `model_family`
- `model_name`
- `filename_prefix`
- `notes`
- `tags`
- `operator`
- `review_status`
- `reference_board_status`

## Safety Notes

- Store metadata as sidecar JSON in runtime.
- Do not store secrets or API keys.
- Do not store arbitrary shell history.
- Treat prompt text as display-only text.
- Do not add a rerun command to the schema until a later safety review.
