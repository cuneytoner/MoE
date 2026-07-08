# Output Card Preview Serving Plan

## Why Previews Are Needed

Output cards currently list generated images and deterministic drawings, but the dashboard uses placeholders instead of real previews.

Safe previews would help operators compare outputs, spot broken files, and prepare reference boards without opening runtime folders manually.

## Current State

- `GET /gateway/media/output-cards` returns image and `drawing_svg` cards.
- Cards include `id`, `type`, `name`, `path`, `relative_runtime_path`, `preview_available`, `source`, `safety_label`, `metadata_available`, and `metadata_path`.
- Dashboard output cards are read-only.
- Current UI placeholder previews are expected.

## Target State

Future output cards should support a safe preview URL for supported assets.

The preview service should resolve a preview request through the output-card allowlisted scan, not through arbitrary user-provided filesystem paths.

## Supported Preview Types

- image thumbnail or direct safe image preview
- `drawing_svg` preview later, only after SVG safety policy exists
- PDF preview later
- placeholder icon fallback

## Security Constraints

- no arbitrary absolute paths
- no `..` traversal
- no shell execution
- no generation trigger
- no delete, move, or rename
- no model files
- no hidden files or hidden folders
- no serving outside allowlisted runtime folders

## Runtime Path Validation

Preview serving must reuse output-card allowlist validation. The preview implementation should scan known runtime roots, resolve a `card_id` to a known card, and serve only the matched output file if the type and extension are supported.

Allowlisted runtime roots remain:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
/home/cuneyt/MoE/runtime/pergola/drawings
/home/cuneyt/MoE/runtime/drawings
```

## Output Card Integration

The output cards API may later expose a `preview_url` only after the safe preview endpoint exists.

Until then, `preview_available` should remain conservative and UI placeholders should remain acceptable.

## Dashboard UI Integration

Dashboard cards should display a thumbnail area. Image cards can use the future safe preview endpoint. SVG cards should use a placeholder until SVG sanitization and serving policy is implemented.

## What This Milestone Does NOT Implement

- No preview API.
- No UI preview changes.
- No file serving.
- No arbitrary filesystem browsing.
- No image generation.
- No runtime file creation.
- No Docker compose behavior change.

## Next Milestones

- M34.11 Reference Board API Implementation.
- M34.12 Reference Board UI Implementation.
- M34.13 Output Preview API Implementation.
- M34.14 Dashboard Preview UI Implementation.
