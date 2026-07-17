#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
TMP_DIR="$(mktemp -d /tmp/moe-3d-reference-board-selection.XXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api" "$PYTHON_BIN" - "$TMP_DIR" <<'PY'
import asyncio
import hashlib
import json
import os
import sys
from pathlib import Path

from app import media_3d_output_cards as cards
from app import reference_boards as boards


tmp = Path(sys.argv[1])
reference_root = tmp / "reference-boards"
runtime_root = tmp / "media" / "outputs" / "3d"
metadata_dir = runtime_root / "metadata"
glb_dir = runtime_root / "glb"
blend_dir = runtime_root / "blender"
obj_dir = runtime_root / "obj"
report_dir = runtime_root / "reports"
for path in (reference_root, metadata_dir, glb_dir, blend_dir, obj_dir, report_dir):
    path.mkdir(parents=True, exist_ok=True)

boards.REFERENCE_BOARDS_ROOT = reference_root
cards.DEFAULT_RUNTIME_3D_ROOT = runtime_root


def write_sidecar(
    name: str,
    *,
    asset_name: str = "demo 3d asset",
    category: str = "architecture",
    glb: str | None = "glb/demo.glb",
    blend: str | None = "blender/demo.blend",
    obj: str | None = None,
    valid: bool = True,
) -> Path:
    payload = {
        "schema_version": "1.0",
        "asset_type": "3d_model" if valid else "bad_asset",
        "source": "blender_parametric",
        "asset_name": asset_name,
        "asset_category": category,
        "created_at": "2026-07-17T00:00:00Z",
        "output_files": {
            "blend": blend,
            "glb": glb,
            "obj": obj,
            "preview": None,
            "metadata": f"metadata/{name}",
            "report": "reports/demo.json",
        },
        "safety_label": "visual_reference_only",
        "structural_certification": False,
        "operator_review_required": True,
        "generation_mode": "guarded_blender",
    }
    path = metadata_dir / name
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return path


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def add_3d(board_id: str, card_id: str, selected_reason: str | None = None, tags: list[str] | None = None) -> dict:
    card = cards.find_3d_output_card_by_id(card_id)
    if card is None:
        raise LookupError("3d_output_card_not_found")
    item = boards.build_3d_reference_board_item(card, selected_reason, tags)
    return boards.add_item_to_reference_board(board_id, item)


(glb_dir / "demo.glb").write_text("glb", encoding="utf-8")
(blend_dir / "demo.blend").write_text("blend", encoding="utf-8")
(report_dir / "demo.json").write_text("{}", encoding="utf-8")
sidecar = write_sidecar("demo.json")
asset_hashes = {path: digest(path) for path in (glb_dir / "demo.glb", blend_dir / "demo.blend", sidecar)}
runtime_before = sorted(path.relative_to(runtime_root).as_posix() for path in runtime_root.rglob("*") if path.is_file())

boards.write_reference_board(boards.build_empty_reference_board("three-d-board", "3D Board"))
result = add_3d(
    "three-d-board",
    "3d_model:metadata/demo.json",
    "Selected from dashboard 3D output cards.",
    ["3d", "architecture", "glb"],
)
assert isinstance(result, dict), result
item = result["items"][0]
assert item["asset_type"] == "3d_model"
assert item["card_id"] == "3d_model:metadata/demo.json"
assert item["name"] == "demo 3d asset"
assert item["relative_runtime_path"] == "glb/demo.glb"
assert item["metadata_path"] == "metadata/demo.json"
assert item["selected_reason"] == "Selected from dashboard 3D output cards."
assert item["safety_label"] == "visual_reference_only"
assert set(item["tags"]) >= {"3d", "architecture", "glb"}
assert not item["relative_runtime_path"].startswith("/")
assert ".." not in Path(item["relative_runtime_path"]).parts
assert sorted(path.relative_to(runtime_root).as_posix() for path in runtime_root.rglob("*") if path.is_file()) == runtime_before
for path, before_hash in asset_hashes.items():
    assert digest(path) == before_hash

board_files = sorted(path.name for path in reference_root.glob("*.json"))
assert board_files == ["three-d-board.json"], board_files
loaded = boards.load_reference_board("three-d-board")
assert loaded["items"][0]["asset_type"] == "3d_model"
assert boards.validate_reference_board_shape(loaded) == []

try:
    add_3d("three-d-board", "3d_model:metadata/demo.json")
except ValueError as exc:
    assert str(exc) == "reference_board_item_exists"
else:
    raise AssertionError("duplicate 3D card was accepted")

for bad_id in (
    "/etc/passwd",
    "../metadata/demo.json",
    "..\\metadata\\demo.json",
    "file:///etc/passwd",
    "C:\\temp\\demo.glb",
    "//server/share/demo.glb",
    "3d_model:metadata/unknown.json",
):
    assert cards.find_3d_output_card_by_id(bad_id) is None

write_sidecar("invalid.json", valid=False)
assert cards.find_3d_output_card_by_id("3d_model:metadata/invalid.json") is None

os.symlink(sidecar, metadata_dir / "symlink.json")
assert cards.find_3d_output_card_by_id("3d_model:metadata/symlink.json") is None

runtime_symlink = tmp / "runtime-symlink"
os.symlink(runtime_root, runtime_symlink)
assert cards._find_3d_output_card_by_id_in_root("3d_model:metadata/demo.json", runtime_symlink) is None

write_sidecar("missing.json", asset_name="metadata fallback asset", glb="glb/missing.glb", blend=None)
boards.write_reference_board(boards.build_empty_reference_board("fallback-board", "Fallback Board"))
fallback = add_3d("fallback-board", "3d_model:metadata/missing.json", None, ["3d"])
assert isinstance(fallback, dict), fallback
fallback_item = fallback["items"][0]
assert fallback_item["relative_runtime_path"] == "metadata/missing.json"
assert fallback_item["metadata_path"] == "metadata/missing.json"

export_json = boards.build_reference_board_json_export("fallback-board")
assert export_json["items"][0]["metadata_summary"]["reason"] == "3d_metadata_review_in_output_cards"
export_markdown = boards.build_reference_board_markdown_export("fallback-board")
assert "metadata fallback asset" in export_markdown

stale_board = boards.load_reference_board("fallback-board")
stale_board["items"][0]["stale"] = True
stale_board["items"][0]["stale_reason"] = "card no longer reported"
boards.write_reference_board(stale_board)
assert boards.load_reference_board("fallback-board")["items"][0]["stale"] is True

PY

grep -q 'class ReferenceBoardAddThreeDItemRequest' apps/gateway-api/app/models/gateway.py
grep -q 'model_config = ConfigDict(extra="forbid")' apps/gateway-api/app/models/gateway.py
grep -q '@app.post("/gateway/media/reference-boards/{board_id}/items/3d"' apps/gateway-api/app/main.py
grep -q 'find_3d_output_card_by_id(request.card_id)' apps/gateway-api/app/main.py
grep -q '3D output card is already selected in this board.' apps/gateway-api/app/main.py
grep -q '@app.post("/gateway/media/reference-boards/{board_id}/items"' apps/gateway-api/app/main.py
grep -q "addThreeDReferenceBoardItem" apps/dashboard-ui/src/api.ts
grep -q "items/3d" apps/dashboard-ui/src/api.ts
grep -q "addingThreeDBoardCardId" apps/dashboard-ui/src/App.tsx
grep -q "handleAddThreeDCardToBoard" apps/dashboard-ui/src/App.tsx
grep -q "Selected from dashboard 3D output cards." apps/dashboard-ui/src/App.tsx
grep -q "Added 3D reference to board." apps/dashboard-ui/src/App.tsx
grep -q "Already in board." apps/dashboard-ui/src/App.tsx
grep -q "Select a reference board first." apps/dashboard-ui/src/components/ThreeDOutputCards.tsx
grep -q "Adds a metadata reference only. No 3D asset is copied or modified." apps/dashboard-ui/src/components/ThreeDOutputCards.tsx
grep -q "3D metadata is reviewed from the 3D Output Cards panel." apps/dashboard-ui/src/components/ReferenceBoards.tsx

if grep -E "Generate|Regenerate|Delete asset|Remove asset|Move|Rename|Repair|Cleanup|Execute|Open filesystem|Launch Blender|Download asset" apps/dashboard-ui/src/components/ThreeDOutputCards.tsx >/dev/null; then
  echo "forbidden 3D asset operation text found in ThreeDOutputCards" >&2
  exit 1
fi

if grep -E "fetchOutputCardMetadata\\(item.card_id\\)" apps/dashboard-ui/src/components/ReferenceBoards.tsx >/dev/null &&
   ! grep -q 'item.asset_type === "3d_model"' apps/dashboard-ui/src/components/ReferenceBoards.tsx; then
  echo "3D reference item can still call generic metadata fetch" >&2
  exit 1
fi

echo "3D reference board selection OK"
