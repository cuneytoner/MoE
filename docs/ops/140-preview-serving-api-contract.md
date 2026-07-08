# Preview Serving API Contract

## Purpose

This document proposes a future read-only preview endpoint for output cards.

Recommended endpoint:

```text
GET /gateway/media/output-preview/{card_id}
```

Alternative considered:

```text
GET /gateway/media/output-preview?relative_runtime_path=...
```

Prefer the `card_id` endpoint because the server can resolve the card through the output-cards allowlisted scan. The API must never accept arbitrary absolute path input.

## Resolution Rule

`card_id` must resolve through the same output-card scan used by:

```text
GET /gateway/media/output-cards
```

If no card matches, return `404`.

## Hard Requirements

- API must never accept arbitrary absolute path.
- API must never serve model files.
- API must never serve files outside allowlisted runtime folders.
- API must only serve supported preview extensions.
- API must block traversal attempts.
- API must not execute shell commands.
- API must not trigger generation.

## Supported Extensions

Initial image preview extensions:

- `.png`
- `.jpg`
- `.jpeg`
- `.webp`

SVG may be added later only after an SVG sanitization policy exists.

## Response Behavior

For image cards, return image bytes with a safe content-type:

```http
HTTP/1.1 200 OK
Content-Type: image/png
Cache-Control: no-store
```

For SVG cards, return placeholder or `404` / `preview_unavailable` until safe SVG preview policy exists.

For unsupported cards, return `404` or a structured `preview_unavailable` response.

## Example Success

```http
GET /gateway/media/output-preview/image:moe_flux_first_20260706_133441_00001_.png
```

```http
HTTP/1.1 200 OK
Content-Type: image/png
```

## Example Errors

Unknown card:

```json
{
  "status": "error",
  "error": "preview_unavailable",
  "detail": "No allowlisted output card matched the requested card_id."
}
```

Blocked traversal:

```json
{
  "status": "error",
  "error": "invalid_card_id",
  "detail": "Preview requests must resolve through output cards."
}
```

Blocked model file:

```json
{
  "status": "error",
  "error": "unsupported_preview_type",
  "detail": "Preview serving does not expose model files."
}
```
