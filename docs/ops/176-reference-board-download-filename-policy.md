# Reference Board Download Filename Policy

## Purpose

Reference board download filenames must be deterministic, safe for browser attachment headers, and independent of arbitrary user-provided paths.

## Safe Filename Format

Use:

```text
reference-board-{board_id}-{YYYYMMDD-HHMMSS}.json
reference-board-{board_id}-{YYYYMMDD-HHMMSS}.md
```

Examples:

```text
reference-board-api-test-board-20260709-150501.json
reference-board-api-test-board-20260709-150501.md
```

M34.27 uses safe `board_id` + UTC timestamp + `.md` extension.

M34.28 uses safe `board_id` + UTC timestamp + `.json` extension.

## Board ID Sanitization

The filename must use sanitized `board_id` only.

Allowed `board_id` characters:

- lowercase letters
- numbers
- dash
- underscore

Denied in `board_id` and filenames:

- slash
- backslash
- dot-dot
- absolute paths
- spaces
- shell-sensitive chars
- hidden path prefixes

## Timestamp Format

Use UTC server time:

```text
YYYYMMDD-HHMMSS
```

Do not use locale-specific strings in filenames.

## Extension Rules

The endpoint chooses the extension.

- JSON endpoint uses `.json`
- Markdown endpoint uses `.md`

Do not accept user-supplied extensions.

## Deny Rules

Do not allow:

- slash
- backslash
- dot-dot
- absolute paths
- spaces
- shell-sensitive chars
- user-supplied extension
- raw title in filename unless sanitized in a later milestone

## Notes

The filename is only for browser download convenience. Export content should still be generated from safe reference-board export helpers and should not include absolute host paths, model files, secrets, or source asset bytes.
