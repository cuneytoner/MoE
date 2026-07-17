# Dashboard 3D Output Cards UI

M35.18 adds a read-only Dashboard panel for 3D output cards from:

```text
GET /gateway/media/3d/cards
```

## What Was Implemented

- `apps/dashboard-ui/src/components/ThreeDOutputCards.tsx`
- 3D output card response types in `apps/dashboard-ui/src/types.ts`
- `fetchThreeDOutputCards()` in `apps/dashboard-ui/src/api.ts`
- independent 3D output-card state and error handling in `apps/dashboard-ui/src/App.tsx`
- `scripts/test-3d-output-cards-ui.sh`
- `make test-3d-output-cards-ui`

## UI Behavior

The panel title is:

```text
3D Output Cards
```

The panel subtitle is:

```text
Read-only view of guarded Blender outputs and metadata verification.
```

The panel shows up to 12 cards and displays:

- asset name
- asset category
- created time
- existing formats
- safety label
- structural certification status
- operator review requirement
- generation mode metadata value
- verification counts
- verification warning messages
- runtime-relative metadata path
- preview placeholder

## Empty, Loading, And Error States

Loading:

```text
Loading 3D output cards.
```

Endpoint unavailable:

```text
3D output cards unavailable: ...
```

Metadata directory missing:

```text
3D metadata directory is not available yet.
```

Empty cards:

```text
No verified 3D output metadata reported yet.
```

Invalid sidecars:

```text
N invalid metadata sidecar(s) were skipped.
```

## Read-Only Boundary

The Dashboard UI does not add:

- generation controls
- delete/move/rename controls
- repair/cleanup controls
- shell controls
- Docker controls
- model switch controls
- Blender start/stop controls
- reference board selection controls for 3D cards
- preview fetching for 3D cards
- absolute filesystem links

The panel consumes the hardened API response and displays only runtime-relative metadata paths.

## How To Test

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-output-cards-ui
```

The test copies `apps/dashboard-ui` into a temporary workspace under `/tmp` and runs the build inside a Docker container with `--network none` when `node:22-alpine` is already present locally. It refuses to pull the image automatically and fails clearly if the image or Docker is unavailable.

The source checkout must remain free of:

- `node_modules`
- `dist`
- `build`
- `.cache`

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make check-layout
make check-python-syntax
```

Expected output:

```text
3D output cards UI OK
```

## Fixed Roadmap

- M35.18 Dashboard 3D Output Cards UI DONE
- M35.19 3D Reference Board Selection PLANNED
- M35.20 M35 Phase Closure PLANNED
