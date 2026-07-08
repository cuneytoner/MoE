# Image Metadata Sidecar Review Template

Use this template after a controlled image generation run that should create a metadata sidecar.

## Review

- Date/time:
- Image generation command:
- Output image path:
- Output metadata path:
- asset_name matches image?:
- asset_path exists?:
- relative_runtime_path correct?:
- prompt captured?:
- seed captured?:
- width/height captured?:
- steps captured?:
- workflow captured?:
- safety_label present?:
- no secret detected?:
- output card metadata_available true?:
- Issues found:
- Git safety result:

## Notes

- Confirm the image and sidecar are both under `/home/cuneyt/MoE/runtime/media/outputs/images`.
- Do not commit generated images or routine runtime sidecars.
- If metadata is missing, inspect `scripts/comfyui-first-image.sh` output for the `METADATA:` line.
