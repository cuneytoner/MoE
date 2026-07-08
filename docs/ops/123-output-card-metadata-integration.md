# Output Card Metadata Integration

## How Output Cards Should Use Metadata

Future output cards should read sidecar metadata when available and merge it with basic file metadata.

File metadata should provide name, path, modified time, and size. Sidecar metadata should provide creation context, prompt, seed, workflow, model, script, geometry, safety label, and notes.

## Metadata Fields Shown On Card

- safety label
- source
- asset type
- prompt short preview when available
- seed when available
- workflow when available
- model when available
- metadata availability badge

The card API should expose this as `metadata_available` so the UI can distinguish full metadata cards from basic file cards.

M34.5 exposes `metadata_available` and `metadata_path`, but full metadata parsing/display remains planned.

Output cards can now detect `metadata_available=true` for deterministic SVG drawings after the generators are run.

After M34.10, newly generated image cards can also show `metadata_available=true` when `scripts/comfyui-first-image.sh` creates a matching JSON sidecar.

Reference boards should use output card metadata when available.

## Metadata Fields Shown In Detail Drawer

- prompt
- negative prompt
- seed
- workflow
- model
- script
- drawing geometry
- units
- safety_label
- notes
- relative runtime path

## Missing Metadata Fallback

If no sidecar JSON exists, the card should still render a basic file card with:

- type
- name
- path
- relative runtime path
- modified time
- size
- source inferred from allowlisted folder
- conservative safety label

## Safety Label Handling

If metadata contains `visual_reference_only`, `draft_drawing`, `deterministic_drawing`, `not_construction_document`, or `generated_media`, the dashboard should display that label clearly.

If metadata is missing, use the safest conservative label for the output type.

## Prompt Display Rules

Prompt should be shown but not executed.

The UI should not turn prompt metadata into a rerun action.

Long prompts should be truncated on cards and shown in full only in a future detail drawer.

## Path Display Rules

Cards may show absolute runtime path and relative runtime path for operator copy/review. They must not allow arbitrary path browsing.

## No Rerun Yet

- No "rerun" button yet.
- No automatic generation.
- No shell execution.
- No service controls.

## Card Fields From Metadata

- prompt
- seed
- workflow
- model
- script
- drawing geometry
- safety_label
- notes
