#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
TMP_DIR="$(mktemp -d /tmp/moe-animation-reference-board-selection.XXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="apps/gateway-api:packages/animation-validation" "$PYTHON_BIN" - "$TMP_DIR" <<'PY'
import hashlib
import json
import os
import sys
from pathlib import Path

from app import media_animation_output_cards as animation_cards
from app import reference_boards as boards


tmp = Path(sys.argv[1])
runtime_root = tmp / "runtime"
reference_root = tmp / "reference-boards"
metadata_dir = runtime_root / "media" / "animation" / "metadata"
reports_dir = runtime_root / "media" / "animation" / "reports"
preview_dir = runtime_root / "media" / "animation" / "previews" / "object-transform-demo-preview" / "frames"
for path in (reference_root, metadata_dir, reports_dir, preview_dir):
    path.mkdir(parents=True, exist_ok=True)

boards.REFERENCE_BOARDS_ROOT = reference_root
animation_cards.DEFAULT_RUNTIME_ROOT = runtime_root


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def animation_card_is_safe(card: dict) -> bool:
    verification = card.get("verification")
    if not isinstance(verification, dict):
        return False
    try:
        metadata_reference_safe = boards.is_safe_animation_metadata_reference(
            boards.animation_metadata_reference_path(card)
        )
    except ValueError:
        metadata_reference_safe = False
    return (
        card.get("type") == "animation"
        and verification.get("metadata_valid") is True
        and verification.get("valid") is True
        and card.get("visual_reference_only") is True
        and card.get("structural_certification") is False
        and card.get("operator_review_required") is True
        and metadata_reference_safe
    )


def add_animation(
    board_id: str,
    selected_card_id: str,
    selected_reason: str | None = None,
    tags: list[str] | None = None,
) -> dict:
    selected_card = animation_cards.find_animation_output_card_by_id(selected_card_id)
    if selected_card is None:
        raise LookupError("animation_output_card_not_found")
    if not animation_card_is_safe(selected_card):
        raise ValueError("animation_output_card_not_selectable")
    item = boards.build_animation_reference_board_item(
        card=selected_card,
        selected_reason=selected_reason,
        request_tags=tags,
    )
    return boards.add_item_to_reference_board(board_id, item)


def write_animation_metadata(name: str, *, valid: bool = True, title: str = "Animation demo") -> Path:
    payload = json.loads(Path("configs/animation/animation-metadata.example.json").read_text(encoding="utf-8"))
    payload["title"] = title
    payload["output_files"]["metadata"] = f"media/animation/metadata/{name}"
    if not valid:
        payload["asset_type"] = "bad_animation"
    path = metadata_dir / name
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    return path


metadata_path = write_animation_metadata("object-transform-demo.json", title="Move demo object")
invalid_metadata_path = write_animation_metadata("invalid.json", valid=False)
preview_frame = preview_dir / "frame-000001.png"
preview_frame.write_bytes(b"\x89PNG\r\n\x1a\nplaceholder")
asset_hashes = {
    metadata_path: digest(metadata_path),
    invalid_metadata_path: digest(invalid_metadata_path),
    preview_frame: digest(preview_frame),
}
runtime_before = sorted(path.relative_to(runtime_root).as_posix() for path in runtime_root.rglob("*") if path.is_file())

card_id = "animation:media/animation/metadata/object-transform-demo.json"
card = animation_cards.find_animation_output_card_by_id(card_id)
assert card is not None
assert card["id"] == card_id
assert animation_cards.find_animation_output_card_by_id("media/animation/metadata/object-transform-demo.json") is None
assert animation_cards.find_animation_output_card_by_id("animation:media/animation/metadata/object-transform") is None
assert animation_cards.find_animation_output_card_by_id("animation:media/animation/metadata/unknown.json") is None
assert animation_cards.find_animation_output_card_by_id("animation:media/animation/metadata/invalid.json") is None
assert animation_cards.find_animation_output_card_by_id("animation:media/animation/metadata/object-transform-demo.json\n") is None
assert card["preview"]["available"] is False
assert card["verification"]["metadata_valid"] is True
assert card["verification"]["valid"] is True

unsafe_card = dict(card)
unsafe_card["type"] = "image"
assert animation_card_is_safe(unsafe_card) is False
unsafe_card = dict(card)
unsafe_card["visual_reference_only"] = False
assert animation_card_is_safe(unsafe_card) is False
unsafe_card = dict(card)
unsafe_card["structural_certification"] = True
assert animation_card_is_safe(unsafe_card) is False
unsafe_card = dict(card)
unsafe_card["operator_review_required"] = False
assert animation_card_is_safe(unsafe_card) is False
unsafe_card = dict(card)
unsafe_card["verification"] = {**card["verification"], "valid": False}
assert animation_card_is_safe(unsafe_card) is False
unsafe_card = dict(card)
unsafe_card["relative_runtime_paths"] = {**card["relative_runtime_paths"], "metadata": "../bad.json"}
assert animation_card_is_safe(unsafe_card) is False

boards.write_reference_board(boards.build_empty_reference_board("animation-board", "Animation Board"))
try:
    add_animation("missing-board", card_id)
except FileNotFoundError:
    pass
else:
    raise AssertionError("missing board accepted")

try:
    add_animation("animation-board", "animation:media/animation/metadata/missing.json")
except LookupError as exc:
    assert str(exc) == "animation_output_card_not_found"
else:
    raise AssertionError("missing animation card accepted")

try:
    add_animation(
        "animation-board",
        card_id,
        " Selected for animation review. ",
        ["animation", "object_transform_animation_plan", "animation", "bad/tag"],
    )
except ValueError:
    pass
else:
    raise AssertionError("unsafe tag accepted")

board = add_animation(
    "animation-board",
    card_id,
    " Selected for animation review. ",
    ["animation", "object_transform_animation_plan", "metadata_only", "animation"],
)
item = board["items"][0]
assert item["asset_type"] == "animation"
assert item["card_id"] == card_id
assert item["name"] == "Move demo object"
assert item["relative_runtime_path"] == "media/animation/metadata/object-transform-demo.json"
assert item["metadata_path"] == "media/animation/metadata/object-transform-demo.json"
assert item["selected_reason"] == "Selected for animation review."
assert item["safety_label"] == "visual-reference-only"
assert item["tags"] == ["animation", "object_transform_animation_plan", "metadata_only"]
assert "preview" not in item["relative_runtime_path"]
assert not item["relative_runtime_path"].startswith("/")
assert ".." not in Path(item["relative_runtime_path"]).parts

try:
    add_animation("animation-board", card_id)
except ValueError as exc:
    assert str(exc) == "reference_board_item_exists"
else:
    raise AssertionError("duplicate animation card accepted")

loaded = boards.load_reference_board("animation-board")
assert boards.validate_reference_board_shape(loaded) == []
assert loaded["items"][0]["card_id"] == card_id
assert loaded["items"][0]["asset_type"] == "animation"
assert len(loaded["items"]) == 1

json_export = boards.build_reference_board_json_export("animation-board")
assert json_export["items"][0]["asset_type"] == "animation"
assert json_export["items"][0]["relative_runtime_path"] == "media/animation/metadata/object-transform-demo.json"
assert "/home/" not in json.dumps(json_export, sort_keys=True)
markdown_export = boards.build_reference_board_markdown_export("animation-board")
assert "Animation Board" in markdown_export
assert "Asset type: animation" in markdown_export
assert "media/animation/metadata/object-transform-demo.json" in markdown_export
assert "/home/" not in markdown_export
assert "frame-000001.png" not in markdown_export
assert ".mp4" not in markdown_export

updated_board, updated_item = boards.update_reference_board_item(
    "animation-board",
    item["item_id"],
    {"selected_reason": "Updated animation note.", "tags": ["animation", "reviewed"]},
)
assert updated_item["selected_reason"] == "Updated animation note."
assert updated_item["tags"] == ["animation", "reviewed"]

removed_board = boards.remove_item_from_reference_board("animation-board", item["item_id"])
assert removed_board["items"] == []

assert boards.validate_reference_board_item_shape(
    {
        "item_id": "bad",
        "card_id": "bad",
        "asset_type": "unknown",
        "name": "bad",
        "relative_runtime_path": "media/animation/metadata/object-transform-demo.json",
        "safety_label": "visual-reference-only",
        "added_at": "2026-01-01T00:00:00Z",
        "tags": [],
    }
)

boards.write_reference_board(boards.build_empty_reference_board("image-board", "Image Board"))
image_item = {
    "item_id": "image-card",
    "card_id": "image:demo.png",
    "asset_type": "image",
    "name": "Image",
    "relative_runtime_path": "media/outputs/images/demo.png",
    "metadata_path": None,
    "selected_reason": None,
    "tags": [],
    "safety_label": "visual_reference_only",
    "added_at": boards.utc_now_iso(),
}
boards.add_item_to_reference_board("image-board", image_item)
assert boards.load_reference_board("image-board")["items"][0]["asset_type"] == "image"

boards.write_reference_board(boards.build_empty_reference_board("limit-board", "Limit Board"))
large_board = boards.load_reference_board("limit-board")
large_board["description"] = "x" * (boards.MAX_REFERENCE_BOARD_BYTES + 1)
try:
    boards.write_reference_board(large_board)
except ValueError as exc:
    assert "exceeds size limit" in str(exc) or "description is too long" in str(exc)
else:
    raise AssertionError("oversized board accepted")

target = reference_root / "target.json"
target.write_text("{}", encoding="utf-8")
symlink_path = reference_root / "link-board.json"
try:
    symlink_path.symlink_to(target)
except OSError:
    symlink_path = None
if symlink_path is not None:
    try:
        boards.write_reference_board(boards.build_empty_reference_board("link-board", "Link Board"))
    except (ValueError, boards.ReferenceBoardStoreUnavailableError):
        pass
    else:
        raise AssertionError("symlink board file accepted")

real_reference_root = reference_root
root_symlink = tmp / "reference-root-link"
try:
    root_symlink.symlink_to(real_reference_root, target_is_directory=True)
except OSError:
    root_symlink = None
if root_symlink is not None:
    boards.REFERENCE_BOARDS_ROOT = root_symlink
    try:
        boards.write_reference_board(boards.build_empty_reference_board("symlink-root", "Symlink Root"))
    except boards.ReferenceBoardStoreUnavailableError:
        pass
    else:
        raise AssertionError("symlink board root accepted")
    boards.REFERENCE_BOARDS_ROOT = real_reference_root

assert "os.replace" in Path("apps/gateway-api/app/reference_boards.py").read_text(encoding="utf-8")
assert sorted(path.relative_to(runtime_root).as_posix() for path in runtime_root.rglob("*") if path.is_file()) == runtime_before
for path, before_hash in asset_hashes.items():
    assert digest(path) == before_hash
PY

grep -q 'def find_animation_output_card_by_id' apps/gateway-api/app/media_animation_output_cards.py
grep -q 'def _find_animation_output_card_by_id_from_root' apps/gateway-api/app/media_animation_output_cards.py
grep -q 'verification.get("metadata_valid") is not True or verification.get("valid") is not True' apps/gateway-api/app/media_animation_output_cards.py
grep -q 'class ReferenceBoardAddAnimationItemRequest' apps/gateway-api/app/models/gateway.py
grep -q 'model_config = ConfigDict(extra="forbid")' apps/gateway-api/app/models/gateway.py
grep -q '@app.post("/gateway/media/reference-boards/{board_id}/items/animation"' apps/gateway-api/app/main.py
grep -q 'find_animation_output_card_by_id(request.card_id)' apps/gateway-api/app/main.py
grep -q 'Animation output card is already selected in this board.' apps/gateway-api/app/main.py
grep -q 'build_animation_reference_board_item' apps/gateway-api/app/reference_boards.py
grep -q '"asset_type": "animation"' apps/gateway-api/app/reference_boards.py
grep -q '"relative_runtime_path": metadata_path' apps/gateway-api/app/reference_boards.py
grep -q '"metadata_path": metadata_path' apps/gateway-api/app/reference_boards.py
grep -q 'os.replace' apps/gateway-api/app/reference_boards.py

grep -q 'ReferenceBoardAddAnimationItemRequest' apps/dashboard-ui/src/types.ts
grep -q 'addAnimationReferenceBoardItem' apps/dashboard-ui/src/api.ts
grep -q 'items/animation' apps/dashboard-ui/src/api.ts
grep -q 'method: "POST"' apps/dashboard-ui/src/api.ts
grep -q 'addingAnimationBoardCardId' apps/dashboard-ui/src/App.tsx
grep -q 'handleAddAnimationCardToBoard' apps/dashboard-ui/src/App.tsx
grep -q 'Selected from dashboard animation output cards.' apps/dashboard-ui/src/App.tsx
grep -q 'Added animation reference to board.' apps/dashboard-ui/src/App.tsx
grep -q 'Add animation item failed.' apps/dashboard-ui/src/App.tsx
grep -q 'Already in board.' apps/dashboard-ui/src/App.tsx
grep -q 'activeBoardId: string;' apps/dashboard-ui/src/components/AnimationOutputCards.tsx
grep -q 'addingCardId: string;' apps/dashboard-ui/src/components/AnimationOutputCards.tsx
grep -q 'onAddToBoard: (card: AnimationOutputCard) => void;' apps/dashboard-ui/src/components/AnimationOutputCards.tsx
grep -q 'Add to board' apps/dashboard-ui/src/components/AnimationOutputCards.tsx
grep -q 'Adding' apps/dashboard-ui/src/components/AnimationOutputCards.tsx
grep -q 'Select a reference board first.' apps/dashboard-ui/src/components/AnimationOutputCards.tsx
grep -q 'Adds an animation metadata reference only. No frame, video, metadata, or source asset is copied or modified.' apps/dashboard-ui/src/components/AnimationOutputCards.tsx
grep -q 'Animation metadata is reviewed from the Animation Output Cards panel.' apps/dashboard-ui/src/components/ReferenceBoards.tsx

if grep -R 'asset_type.*request\|metadata_path.*request\|relative_runtime_path.*request\|preview.*request' apps/gateway-api/app/main.py apps/dashboard-ui/src/App.tsx apps/dashboard-ui/src/api.ts | grep -i animation >/dev/null; then
  echo "animation reference-board flow trusts client-supplied asset/path fields" >&2
  exit 1
fi

if grep -R '<img\|FileResponse\|base64\|file://\|download/animation\|render-preview\|execute-animation\|REAL_ANIMATION_GENERATION' apps/dashboard-ui/src/components/AnimationOutputCards.tsx apps/dashboard-ui/src/api.ts >/dev/null; then
  echo "animation reference-board UI introduced binary/execution behavior" >&2
  exit 1
fi

if find . -type d \( -name node_modules -o -name dist -o -name build -o -name .cache -o -name __pycache__ \) -print -quit | grep -q .; then
  echo "generated dependency/build/cache directory found in source checkout" >&2
  exit 1
fi

if find . -type f \( -name "frame-*.png" -o -name "*.mp4" -o -name "*.webm" -o -name "*.gif" -o -name "*.blend" \) -print -quit | grep -q .; then
  echo "generated animation artifact found in source checkout" >&2
  exit 1
fi

echo "Animation reference board selection OK"
