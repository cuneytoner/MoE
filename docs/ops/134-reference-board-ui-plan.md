# Reference Board UI Plan

## Future Dashboard UI Behavior

The dashboard should eventually let operators build reference boards from output cards while keeping generated assets untouched.

Reference board UI should reuse the same safe preview endpoint planned for output cards.

## Planned Actions

- Select card for board.
- Remove from board.
- Create board.
- Rename board.
- Add `selected_reason`.
- Filter by `safety_label`.
- Show board item count.
- Show visual-only warning.

## Safety Constraints

- no generation button
- no delete/move/rename runtime files
- no arbitrary file picker
- no shell actions
- no service start/stop controls

Initial implementation should probably be read-only plus selection JSON generation through an explicit safe endpoint later.

## Warning Copy

The UI should clearly show that AI-generated images are visual references only and draft drawings are not construction documents.
