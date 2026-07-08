# Reference Board Store Review Template

Use this template when reviewing the safe runtime reference board store.

## Review

- Date/time:
- Smoke test command:
- Runtime board folder exists?:
- Board file created?:
- Board id valid?:
- JSON valid?:
- schema_version present?:
- items list present?:
- Absolute paths rejected?:
- Traversal rejected?:
- Source assets untouched?:
- No generation triggered?:
- Git safety result:
- Issues found:

## Notes

- Board JSON should live only under `/home/cuneyt/MoE/runtime/reference-boards`.
- Board items should reference assets by safe relative runtime paths.
- Generated assets should not be copied, moved, renamed, or deleted.
