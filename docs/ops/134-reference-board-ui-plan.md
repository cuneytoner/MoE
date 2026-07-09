# Reference Board UI Plan

## Future Dashboard UI Behavior

The dashboard should eventually let operators build reference boards from output cards while keeping generated assets untouched.

Reference board UI should reuse the same safe preview endpoint planned for output cards.

Dashboard UI should use M34.17 item selection endpoints later.

M34.12 implements the first dashboard reference-board UI using the M34.11 and M34.17 APIs.

M34.19 improves selected board detail and item card display.

## Planned Actions

- Select card for board.
- Remove from board.
- Create board.
- Rename board.
- Add `selected_reason`.
- Filter by `safety_label`.
- Show board item count.
- Show visual-only warning.

M34.12 covers create, select, item count, add-to-board, remove-from-board, and safety note behavior. Rename, filtering, richer reason editing, and export remain future work.

## Safety Constraints

- no generation button
- no delete/move/rename runtime files
- no arbitrary file picker
- no shell actions
- no service start/stop controls

Initial implementation should probably be read-only plus selection JSON generation through an explicit safe endpoint later.

M34.12 keeps source assets untouched and writes only through the safe reference-board API.

## Warning Copy

The UI should clearly show that AI-generated images are visual references only and draft drawings are not construction documents.
