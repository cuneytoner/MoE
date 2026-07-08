# Output Card UI Plan

## Dashboard Card Layout

Future output cards should present generated outputs as compact, scan-friendly cards in the media dashboard.

M34.6 implements the first read-only dashboard output cards UI.

## Card Sections

- thumbnail/icon
- title
- type badge
- safety badge
- modified time
- file size
- source
- path copy field
- metadata badges

Cards should show metadata badges and a future metadata detail drawer.

## Filters

- images
- SVG drawings
- latest only
- visual reference only
- draft drawings

## Empty State

If no cards are available, the dashboard should show a plain read-only empty state explaining that no output cards were found in allowlisted runtime folders.

The empty state should not include generation buttons or service controls.

## Error State

If card metadata cannot be loaded, the dashboard should show a read-only error state with the endpoint status and a short operator-safe explanation.

The error state should not suggest destructive cleanup or runtime mutation.

## Forbidden Actions

- No destructive actions.
- No generation buttons.
- No shell buttons.
- No delete, move, or rename controls.
- No service start or stop controls.

## Later

- compare view
- reference board selection
- prompt metadata drawer
- metadata detail drawer
