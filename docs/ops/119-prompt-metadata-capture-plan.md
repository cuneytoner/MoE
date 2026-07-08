# Prompt Metadata Capture Plan

## Why Metadata Capture Is Needed

Generated assets become much more useful when the system can explain how they were created. Output cards, reference boards, and future compare views need prompt, seed, workflow, model/runtime, command, geometry, and safety metadata.

Without metadata, an output card can only show file name, path, time, and size. With metadata, an operator can understand the intent and limitations of the asset without rerunning anything.

## Current State

- Generated images live under `/home/cuneyt/MoE/runtime/media/outputs/images`.
- Pergola SVG drawings live under `/home/cuneyt/MoE/runtime/pergola/drawings`.
- Generic drawing demo SVGs live under `/home/cuneyt/MoE/runtime/drawings/demo`.
- Existing scripts do not write metadata sidecars yet.

Existing generation scripts:

- `scripts/comfyui-first-image.sh`
- `tools/pergola-drawings/generate_pergola_svg.py`
- `tools/drawing-engine/generate_demo_svg.py`

## Target State

Each generated output should have optional runtime metadata that future dashboard output cards and reference boards can read.

The target is a sidecar JSON file next to each generated output. The sidecar should describe the asset, creation context, key parameters, safety label, and operator notes.

## Metadata File Strategy

Recommended strategy: sidecar JSON files next to generated outputs.

For image:

```text
image filename:
  moe_pergola_project_20260707_131301_00001_.png
metadata filename:
  moe_pergola_project_20260707_131301_00001_.json
```

For drawing:

```text
drawing filename:
  side_elevation.svg
metadata filename:
  side_elevation.json
```

Metadata is runtime output. Metadata should not be committed by default.

## Image Metadata

Image metadata should capture:

- prompt
- negative prompt when used
- width and height
- steps
- seed
- filename prefix
- workflow
- model family and model name
- source script
- safety label
- notes

See [120-image-metadata-schema.md](120-image-metadata-schema.md).

## Drawing Metadata

Drawing metadata should capture:

- drawing kind
- source script
- project or case study
- units
- geometry inputs
- safety label
- notes

See [121-drawing-metadata-schema.md](121-drawing-metadata-schema.md).

## Output Card Integration

Future output cards should read sidecar JSON when available. Metadata can improve card titles, badges, safety labels, source labels, prompt display, and detail drawers.

If no sidecar exists, the output card should still render a basic file card from file metadata.

## Reference-board Integration

Reference boards should use metadata to record why an asset was selected, which prompt or geometry produced it, and whether it is a visual reference, draft drawing, or deterministic drawing.

Prompt metadata capture is needed before reference boards can become reliable across multiple projects.

## Safety Policy

- Metadata is runtime output.
- Metadata should not be committed by default.
- Metadata should not contain secrets.
- Metadata should not contain API keys.
- Metadata should not contain arbitrary shell history.
- Prompt text may be stored, but it must never be executed from metadata.
- Metadata must not trigger generation.

## What This Milestone Does NOT Implement

- No metadata writing.
- No generation script changes.
- No Gateway API changes.
- No dashboard UI changes.
- No runtime folder scan.
- No runtime files.

## Next Milestones

- Implement sidecar metadata writing for controlled generation scripts.
- Teach output cards API to read sidecars safely.
- Add dashboard metadata badges and detail drawer.
- Use metadata for reference-board and compare workflows.
