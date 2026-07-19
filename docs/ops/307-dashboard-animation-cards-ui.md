# Dashboard Animation Cards UI

## Purpose

M36.15 adds a read-only Dashboard section for animation output cards. It helps operators inspect validated animation metadata and verified sampled PNG preview summaries without serving binaries or mutating runtime assets.

## Dashboard component

The UI component is:

```text
apps/dashboard-ui/src/components/AnimationOutputCards.tsx
```

It renders under:

```text
animation-output-cards
```

The visible title is:

```text
Animation Output Cards
```

## Gateway endpoint

The UI reads:

```text
GET /gateway/media/animation/cards
```

The client uses only the fixed endpoint. It does not pass paths, runtime directories, preview frame names, or source asset paths.

## TypeScript models

M36.15 adds explicit TypeScript models for:

- `AnimationOutputCardsResponse`
- `AnimationOutputCard`
- timeline summary
- animation summary
- preview summary
- relative runtime paths
- verification summary
- read-only safety flags

The models keep animation metadata separate from 3D, image, and reference-board types.

## API client

The Dashboard client adds:

```text
fetchAnimationOutputCards
```

It calls `/gateway/media/animation/cards` with a normal read-only fetch. It does not add POST, PATCH, DELETE, download, preview-serving, or execution behavior.

## App state integration

`App.tsx` stores animation cards separately from other dashboard data. Animation card load errors are isolated so other panels can keep rendering.

If the animation card endpoint fails, the Dashboard clears stale animation cards and shows:

```text
Animation output cards unavailable: <error>
```

## Empty states

The component distinguishes:

- loading with no cards
- missing metadata directory
- missing preview reports directory
- metadata available but no valid cards
- skipped invalid metadata sidecars
- backend warnings

## Metadata cards

Each card shows title, source kind, created time, type, generation mode, visual-reference-only warning, structural-certification warning, and operator-review requirement.

## Timeline display

Cards show FPS, frame range, total frame count, and duration seconds. Invalid date and duration values are handled defensively.

## Animation summary

Cards show track count, keyframe count, segment count, operation count, target types, target ids, animated properties, and interpolation values.

Long chip lists are compacted after six values with a `+N more` chip.

## Preview display boundary

The Dashboard shows only preview metadata:

- whether a sampled PNG preview is verified
- frame count
- width and height
- format
- first frame runtime-relative path as text

The Dashboard does not load sampled PNG frames as images, serve videos, embed base64 data, or expose direct runtime file URLs.

## Relative runtime paths

Runtime paths are displayed as text only:

- metadata
- report
- preview frames
- declared video preview

The declared video preview remains a declaration only. It is not opened or played by this UI.

## Verification display

Cards show:

- metadata valid
- provenance not checked
- preview report valid
- runtime preview verified
- error count
- warning count

`provenance_checked=false` is displayed as an explicit review signal, not as a UI crash or hidden failure.

## Safety flags

The component checks the top-level animation card API safety flags. If a mutation or execution flag is unsafe, it shows:

```text
Unsafe animation card API flags detected. Do not treat these cards as read-only.
```

## No binary serving

M36.15 does not add image, video, GIF, WebM, MP4, FileResponse, base64, download, or browser file URL behavior.

## No reference-board action

M36.15 originally shipped read-only animation cards without reference-board selection. M36.16 adds reviewed metadata-only selection while preserving the no-binary-serving dashboard boundary.

## Responsive layout

The section uses compact cards in a responsive grid. Text paths use wrapping so long runtime-relative paths do not break the layout.

## Accessibility

The sidebar includes an Animation navigation item that links to `#animation-output-cards`. Status text remains visible as normal text and chips.

## Container build

Run on PC-1:

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml --profile dashboard build dashboard-ui
```

## Live verification

Run on PC-1:

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml --profile dashboard up -d --build dashboard-ui
make dashboard-ui-health
curl -fsS http://127.0.0.1:8100/gateway/media/animation/cards | jq '{status, service, card_count, metadata_dir_available, reports_dir_available, safety_flags}'
curl -fsS http://127.0.0.1:8500 >/dev/null
```

Expected:

- Dashboard loads.
- Animation Output Cards section is visible.
- Animation card endpoint errors do not break other sections.
- Preview status is metadata-only.
- No generation, rendering, download, delete, move, repair, or reference-board button exists.

## M36.16 reference-board selection

M36.16 adds an `Add to board` action for animation cards. It posts only the card id, selected reason, and safe tags to the reviewed animation reference-board endpoint. The action stores a metadata reference only and does not copy frames, videos, metadata sidecars, preview reports, or source assets.

## Final decision

M36.15 implements a read-only Dashboard animation cards UI that consumes the M36.14 card endpoint and preserves source/runtime/model safety boundaries.
