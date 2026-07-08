# Metadata Sidecar Policy

## Sidecar JSON Naming

Use the same basename as the generated asset and replace the extension with `.json`.

M34.7 implements runtime sidecars for deterministic SVG drawing outputs.

Examples:

```text
moe_pergola_project_20260707_131301_00001_.png
moe_pergola_project_20260707_131301_00001_.json

side_elevation.svg
side_elevation.json
```

## Sidecar Location

Place the sidecar JSON next to the generated output file in runtime.

Metadata should stay close to the asset so future output cards can match the file and metadata without a central database.

## Runtime-only Default

Metadata is runtime output by default. It should not be committed to Git by default.

## No Secrets

- No secrets.
- No API keys.
- No tokens.
- No passwords.
- No private environment values.

## Command History

Do not store shell command history unless it has been explicitly sanitized. Metadata should record structured generation context, not arbitrary terminal history.

## Git Policy

No generated media committed to Git by default.

Metadata may be committed only if intentionally used as a small sample fixture and reviewed for secrets, paths, and size.

## Sorting / Matching Rules

- same basename preferred
- output card should look for sidecar JSON
- if no sidecar exists, card should still render basic file card

## Supported Pairing

Sidecar `.json` files should pair only with supported media or drawing assets. Unmatched JSON files should not become output cards on their own unless a future milestone defines metadata-only card behavior.
