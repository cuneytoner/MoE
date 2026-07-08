# Preview Serving UI Plan

## Dashboard Card Thumbnail Area

Output cards should reserve a stable thumbnail area at the top of each card.

The area should show either a safe preview, a placeholder icon, a loading state, or a broken preview fallback.

## Image Preview Behavior

Image cards should use the future `output-preview` endpoint after it is implemented.

The UI should request previews by `card_id`, not by arbitrary path.

Dashboard UI can use the image preview endpoint after M34.13.

M34.14 implements dashboard image previews using the `card_id`-based preview endpoint.

## SVG Placeholder Behavior

SVG cards should continue to show a placeholder until SVG preview serving has a safe sanitization policy.

## Loading State

While a preview is loading, show a compact neutral placeholder. Loading state must not shift card layout.

## Error State

If preview loading fails, show a broken preview fallback and keep the rest of the card usable.

## Broken Preview Fallback

Fallback should still show:

- name
- type
- safety label
- relative runtime path
- metadata availability

## Forbidden UI Actions

- No open arbitrary file action.
- No download action yet.
- No delete/move/rename.
- No generation button.
- No shell action.
- No service controls.

## Future

- preview modal
- compare view
- reference board preview
- PDF preview
- sanitized SVG preview
