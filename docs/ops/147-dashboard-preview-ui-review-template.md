# Dashboard Preview UI Review Template

Use this template when reviewing dashboard image previews.

## Review

- Date/time:
- Dashboard URL:
- Image card preview visible?:
- SVG card still placeholder?:
- Preview URL uses card_id?:
- Broken preview fallback works?:
- No arbitrary path usage?:
- No generation button?:
- No delete/move/rename buttons?:
- API endpoint still blocks SVG?:
- Issues found:
- Git safety result:

## Notes

- Image previews should use `card.id` through the Gateway preview endpoint.
- SVG cards should not request previews.
- The UI should not expose download, delete, move, rename, or generation actions.
