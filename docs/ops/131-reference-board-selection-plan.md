# Reference Board Selection Plan

## Why Reference Boards Are Needed

A reference board is a curated list of selected generated assets. It helps operators compare, organize, and explain useful outputs without copying binaries into the repo or moving runtime files.

Reference boards are the curation layer for generated images and deterministic drawings.

## Current State

The dashboard output cards endpoint reports:

- image cards
- `drawing_svg` cards
- `safety_label`
- `relative_runtime_path`
- `metadata_available`
- `metadata_path`

The dashboard can display output cards, but there is no selection workflow yet.

## Target State

Future reference boards should let an operator select output cards into named boards, add selection reasons, preserve safety labels, and prepare review sets for later UI workflows.

Reference boards will benefit from safe output previews so operators can select images and drawings without opening runtime folders directly.

Reference board selection will build on the safe runtime store introduced in M34.16.

M34.11 provides the initial API foundation before item selection.

## Reference Board Use Cases

- choose best generated concept images
- compare prompt variants
- collect architecture references
- collect pergola case-study outputs
- collect draft drawings
- prepare review sets for later UI

## Asset Types Supported

- generated images
- deterministic SVG drawings
- future PDF drawings
- future reference-board exports

## Safety Policy

- AI-generated images are visual references only.
- Draft SVG drawings are not construction documents.
- Reference boards must not imply engineering approval.
- Reference board selection must not trigger generation.
- Reference board selection must not move/delete/rename runtime files.

## Runtime-only Policy

Reference board data should live under runtime by default. Boards should reference generated assets by `relative_runtime_path` instead of copying asset binaries.

## Read-only Selection Model

The first design should treat output cards as source items and board JSON as the only mutable runtime artifact. Asset files remain untouched.

## What This Milestone Does NOT Implement

- No API changes.
- No UI changes.
- No runtime reference board files.
- No copy, move, delete, or rename behavior.
- No image generation.

## Next Milestones

- Implement a safe reference board API.
- Implement dashboard selection UI.
- Add reference board review/export workflows.
