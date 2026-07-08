# Preview Serving Review Template

Use this template when a future preview endpoint or UI preview implementation is tested.

## Review

- Date/time:
- Endpoint tested:
- Card id tested:
- Asset type:
- Preview returned?:
- Content-type correct?:
- Traversal blocked?:
- Model extensions blocked?:
- Hidden files blocked?:
- SVG handling safe?:
- No generation triggered?:
- No asset mutation?:
- Issues found:
- Git safety result:

## Notes

- Preview serving should resolve through output cards by `card_id`.
- Preview serving should reuse allowlisted runtime folder validation.
- A failed preview should not imply the underlying output card is invalid.
