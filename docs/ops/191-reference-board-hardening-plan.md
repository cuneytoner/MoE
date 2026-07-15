# Reference Board Hardening Plan

## Purpose

This document plans additional reliability and security hardening for reference board workflows.

The completed workflow already supports board creation, item selection, note/tag edits, metadata review, JSON/Markdown export, JSON/Markdown download, and export regression coverage. M34.33 identifies the next failure cases and safety checks to tighten before the workflow becomes a broader media review foundation.

M34.34 implements the first error-handling polish slice.

M34.35 implements explicit validation limits.

M34.36 adds regression coverage for malformed runtime board files.

M34.37 plans safe operator repair workflows for runtime store issues.

M34.38 defines backup strategy for runtime board files.

M34.39 plans the CLI used for future validate/backup/repair work.

M34.40 adds a read-only validation CLI for board runtime store integrity.

M34.41 adds a safe single-board backup CLI for runtime board JSON files.

M34.42 introduces guarded `APPLY=1` repair behavior.

M34.43 adds repair regression coverage.

## Current Safety Baseline

The current baseline includes:

- read-only dashboard posture
- no source asset copy/move/delete
- no approve action
- no generation trigger
- no arbitrary filesystem browsing
- response-only exports/downloads
- safe `board_id` based routing
- regression script exists

The dashboard and Gateway should continue to treat reference boards as review records, not asset management or generation controls.

## Input Validation Hardening

Future validation work should review:

- `board_id` validation
- `item_id` validation
- `card_id` validation
- `selected_reason` length limits
- tag count limits
- tag length limits
- tag character policy
- title/description length limits
- reject unexpected payload fields if needed
- JSON body size limits if applicable

Validation should prefer clear operator-facing errors and should avoid accepting path-like identifiers where a stable id is expected.

## Runtime Store Hardening

Future runtime-store work should cover:

- malformed board JSON
- missing board file
- unreadable board file
- duplicate item references
- stale item references
- metadata sidecar missing
- metadata sidecar invalid JSON
- output card missing
- runtime root missing
- write permission errors
- atomic write expectations

The store should fail closed when board data cannot be trusted. Recovery should preserve source assets and avoid deleting runtime media or drawing outputs.

## Export/Download Hardening

Future export/download work should cover:

- export unavailable when board malformed
- metadata unavailable behavior
- no absolute host paths
- no model paths
- no secrets
- `Content-Disposition` filename safety
- stable JSON schema
- Markdown escaping / plain text rendering
- future ZIP/PDF risks

JSON and Markdown exports should remain review artifacts. If future milestones add ZIP/PDF or archive behavior, those milestones need separate safety design and regression coverage.

## Dashboard Hardening

Future dashboard work should cover:

- loading states
- empty boards
- empty items
- failed export
- failed download
- stale board after edit/remove
- copy-to-clipboard failure
- CORS errors
- refresh behavior
- avoid duplicate React keys

The dashboard should keep safe failure states visible and should never convert review UI into approve/delete/move/generate controls.

## Regression Expansion

Future tests should cover:

- board not found
- invalid board id
- missing metadata
- missing output card
- malformed board JSON fixture
- large `selected_reason`
- many tags
- download filename check
- host path leakage check
- dashboard smoke test if feasible later

The existing `make reference-board-export-regression` target is the baseline. Future regression expansion should keep temporary data outside the repo and avoid creating runtime export archives.

## Recovery / Operator Playbook

Operators should be able to:

- inspect boards through the dashboard and Gateway read endpoints
- remove a broken test board safely through an explicit future maintenance procedure
- rerun `make reference-board-export-regression`
- rebuild Gateway and dashboard containers when code changes are deployed
- handle accidental untracked files by inspecting `git status --short`
- avoid committing runtime media, generated drawings, model files, logs, secrets, or downloaded review artifacts

Recovery guidance should prefer inspection before mutation. Broken board data should not lead to source asset deletion.

## Explicit Non-Goals

- no ZIP
- no PDF
- no runtime export archive
- no source asset bundle
- no approval workflow
- no generation workflow
- no shell execution

## Proposed Future Milestones

- M34.34 Reference Board Error Handling Polish
- M34.35 Reference Board Validation Limits
- M34.36 Reference Board Malformed Store Regression
- M34.37 Reference Board Store Repair Plan
- M34.38 Reference Board Store Backup Plan
- M34.39 Reference Board Store Repair CLI Plan
- M34.40 Reference Board Store Validate CLI Implementation
- M35 Media Review Workflow Phase
