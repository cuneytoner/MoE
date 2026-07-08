# Output Preview API Review Template

Use this template when testing the M34.13 output preview endpoint.

## Review

- Date/time:
- Endpoint tested:
- Image card id:
- HTTP status for image preview:
- Content-type:
- Output file command result:
- SVG card blocked?:
- Traversal blocked?:
- Model extension blocked?:
- Hidden file blocked?:
- No generation triggered?:
- No asset mutation?:
- Issues found:
- Git safety result:

## Notes

- Image preview should return bytes only for known output cards.
- SVG cards should return `preview_unavailable`.
- Unsafe paths should return `preview_blocked`.
- The endpoint should not create, delete, move, rename, or generate assets.
