# Reference Board JSON Export Review Template

Use this template when reviewing the M34.23 JSON export endpoint.

## Review Fields

- Date/time:
- Board id:
- Endpoint status:
- export_type correct?
- board metadata included?
- items included?
- selected_reason included?
- tags included?
- metadata_summary included?
- absolute paths excluded?
- source assets untouched?
- generation_triggered false?
- source_assets_copied false?
- source_assets_deleted false?
- model files excluded?
- secrets excluded?
- Git safety result:
- Issues found:

## Suggested Evidence

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/export/json \
  | jq '.export_type, .board.board_id, .board.item_count, .safety'
```

### Run on PC-1
```bash
curl -fsS http://127.0.0.1:8100/gateway/media/reference-boards/api-test-board/export/json \
  | grep -E '/home/cuneyt|/mnt|/media'
```

Expected: no output.
