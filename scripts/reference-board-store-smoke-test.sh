#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
export PYTHONPATH="$ROOT/apps/gateway-api"

python3 - <<'PY'
from app.reference_boards import (
    build_empty_reference_board,
    load_reference_board,
    write_reference_board,
)

board = build_empty_reference_board(
    board_id="smoke-test-board",
    title="Smoke Test Board",
    description="Runtime-only smoke test board.",
)
path = write_reference_board(board)
loaded = load_reference_board("smoke-test-board")

print(f"REFERENCE_BOARD_PATH={path}")
print(f"BOARD_ID={loaded['board_id']}")
print(f"ITEM_COUNT={len(loaded['items'])}")
PY
