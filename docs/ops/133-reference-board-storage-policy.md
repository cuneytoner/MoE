# Reference Board Storage Policy

## Proposed Runtime Folder

```text
/home/cuneyt/MoE/runtime/reference-boards
```

## Storage Format

Boards are JSON files. They should remain runtime output by default.

M34.16 implements the first safe runtime storage helper for board JSON files.

Reference board API writes only board JSON files under the runtime reference board folder.

## Asset References

Boards reference assets by `relative_runtime_path`.

Boards do not copy assets by default.

## Forbidden Storage Behavior

- Boards do not move assets.
- Boards do not delete assets.
- Boards do not rename assets.
- Boards should not store secrets.
- Boards should not store arbitrary shell history.
- Boards should not point outside runtime.

## Future Exports

Boards may later be exported to a report package. Export behavior must be designed separately and must preserve source/runtime/Git boundaries.
