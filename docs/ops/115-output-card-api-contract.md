# Output Card API Contract

## Purpose

This document defines a future read-only API contract for generic media dashboard output cards.

Proposed endpoint:

```text
GET /gateway/media/output-cards
```

## Response Example

```json
{
  "status": "ok",
  "service": "gateway-media-output-cards",
  "safety": {
    "read_only": true,
    "starts_services": false,
    "stops_services": false,
    "real_generation_trigger": false,
    "arbitrary_shell": false
  },
  "cards": [
    {
      "id": "image:moe_pergola_project_20260707_131301_00001_.png",
      "type": "image",
      "name": "moe_pergola_project_20260707_131301_00001_.png",
      "path": "/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_project_20260707_131301_00001_.png",
      "relative_runtime_path": "media/outputs/images/flux-first/moe_pergola_project_20260707_131301_00001_.png",
      "modified": "2026-07-07T10:13:14Z",
      "size_bytes": 552560,
      "preview_available": true,
      "source": "comfyui",
      "tags": ["image", "pergola", "visual-reference"],
      "safety_label": "visual_reference_only"
    },
    {
      "id": "drawing_svg:side_elevation.svg",
      "type": "drawing_svg",
      "name": "side_elevation.svg",
      "path": "/home/cuneyt/MoE/runtime/pergola/drawings/side_elevation.svg",
      "relative_runtime_path": "pergola/drawings/side_elevation.svg",
      "modified": "2026-07-07T18:17:00Z",
      "size_bytes": 2160,
      "preview_available": false,
      "source": "deterministic-svg",
      "tags": ["drawing", "svg", "pergola", "draft"],
      "safety_label": "draft_drawing"
    }
  ]
}
```

## Rules

- API must be read-only.
- API must scan only allowlisted runtime folders.
- API must not execute shell commands.
- API must not trigger generation.
- API must not expose arbitrary filesystem browsing.
- API must limit result count.
- API must sort newest first.

## Future Notes

The API should use structured filesystem APIs and explicit allowlists. It should never accept arbitrary user-provided paths for browsing.
