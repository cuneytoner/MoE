# Reference Board Stale Item Handling Plan

## Purpose

Plan future handling for reference board items whose referenced output cards are no longer available.

M34.45 is documentation only. It does not implement stale item marking, stale item deletion, source asset repair, metadata repair, Gateway behavior, dashboard behavior, ZIP/PDF behavior, or generation.

Duplicate removal remains separate from stale item handling.

## Current Behavior

- Reference board items are runtime JSON review metadata.
- Output cards are discovered from allowlisted runtime output folders.
- A board item can become stale if its output card is no longer discoverable.
- Current repair CLI does not mark or remove stale items.
- Source assets are never recreated by reference board repair.

## Stale Item Principles

- dry-run first
- `APPLY=1` required for future board mutation
- backup required before apply
- never delete source assets
- never delete metadata sidecars
- never recreate generated assets
- never invent metadata
- keep stale handling separate from duplicate item repair
- report stale items before any mutation

## Future Strategy

M34.48 adds stale item marking as a separate repair mode.

Default behavior should preserve board items and report stale references. Any future marking should write only board JSON after explicit review, backup, and `APPLY=1`.

M34.48 implements `MODE=mark-stale-items` with mark-not-remove behavior.

M34.49 verifies stale marking behavior with a controlled fixture.

## Non-Goals

- no stale item implementation in this milestone
- no stale item deletion
- no source asset repair
- no metadata sidecar repair
- no dashboard repair button
- no backend repair endpoint
- no ZIP/PDF
- no generation
- no shell execution through dashboard/API

## Future Milestones

- M34.48 Reference Board Stale Item Marking Implementation
- M34.49 Reference Board Stale Item Regression
