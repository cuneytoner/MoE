# Dashboard UI

Milestone 26.8 adds a read-only Dashboard UI MVP. Milestone 26.8.1 upgrades the visual layer with a Material UI / Minimal Dashboard inspired theme.

## Purpose

The dashboard gives one browser surface for:

- system and media service health
- real generation gates
- latest generated image paths
- safe command hints
- runtime mode hints
- PC-1 and PC-2 role summary

It reads Gateway's dashboard endpoints:

```text
GET /gateway/media/dashboard
GET /gateway/runtime/dashboard
```

## What It Does Not Do

The UI does not:

- start or stop services
- call Docker
- suspend PC-1 or PC-2
- trigger real generation
- execute shell commands
- serve generated image bytes
- delete, move, or copy runtime media

## Safety Model

The UI displays the Gateway safety model and treats unsafe flags as a red warning. The expected safe values are:

```text
read_only=true
starts_services=false
stops_services=false
real_generation_trigger=false
arbitrary_shell=false
```

Safe command hints are rendered as text only.

## Material UI Theme

The M26.8.1 dashboard uses Material UI components for the app bar, sidebar, cards, chips, alerts, lists, and responsive layout.

The visual direction is inspired by the public Minimal UI / Material Kit React dashboard reference:

```text
https://github.com/minimal-ui-kit/material-kit-react
```

The full external template is not vendored into this repository. No unrelated demo pages or large assets are copied. The local implementation remains focused on AI Brain OS / MoE status, safety gates, runtime hints, and media output paths.

## Runtime Cards

Milestone 26.8.2 adds runtime cards backed by the read-only Gateway runtime dashboard endpoint.

Cards include:

- GPU name, VRAM used/free/total, and utilization
- llama-server reachability, URL, and active model when reported
- ComfyUI reachability and Docker bridge hint
- PC-2 worker reachability for Prompt Interpreter, Nightly Learning, Research Ingestion, and Feedback Worker
- latest visible media job ID, state, mode, job type, and job path
- image lifecycle summary with dry-run availability, real generation lock state, recommended mode, and next safe step

Missing Control API, ComfyUI, llama-server, GPU, media jobs, or PC-2 workers are warnings. They do not make the dashboard an action surface and they do not trigger recovery actions.

## System Resource Cards

Milestone 26.8.3 extends runtime cards with read-only system resource cards:

- PC-1 RAM from `/proc/meminfo`
- PC-1 CPU load from `/proc/loadavg`
- PC-1 uptime from `/proc/uptime`
- PC-1 root disk usage from `shutil.disk_usage("/")`
- PC-2 system placeholder when no safe HTTP system endpoint exists
- Docker observer placeholder when the Docker socket is not mounted

The Gateway does not require `psutil`. GPU status remains non-fatal; when `nvidia-smi` is not available inside the Gateway container, the dashboard reports that detail as a warning.

Milestone 26.8.4 adds `GET /system/status` to the PC-2 Prompt Interpreter Worker. When reachable, the Gateway runtime dashboard uses that fixed HTTP endpoint to populate the PC2 System card with real RAM, CPU load, disk, and uptime metrics. If the endpoint is unavailable, the card remains a warning instead of failing the dashboard.

Milestone 26.8.5 adds an optional host-generated Docker summary snapshot:

```bash
make docker-summary-snapshot
make docker-summary-status
```

The snapshot is written outside the repository at `/home/cuneyt/MoE/runtime/status/docker-summary.json`. Gateway reads only that fixed JSON file and never mounts `docker.sock`, calls Docker, runs shell commands, or controls containers. The Docker Summary card displays snapshot counts when available and remains warning-only when the file is missing or invalid.

## Run

Start the UI:

```bash
make dashboard-ui-up
```

## Memory Approval

Milestone 29.8 adds a read-only Memory Approval section backed by:

```text
GET /gateway/memory-approval/dashboard
```

The view shows runtime report summaries, candidate counts, duplicate groups, apply-log counts, and dry-run E2E status. It does not create approval files, run scripts, call Memory API, run `APPLY=1`, or expose approve/apply/store controls.

Check it:

```bash
make dashboard-ui-health
```

Open it:

```bash
make dashboard-ui-open
```

Stop only the UI:

```bash
make dashboard-ui-down
```

The UI listens on:

```text
http://127.0.0.1:8500
```

The theme keeps the same read-only behavior as the MVP:

- no service start/stop buttons
- no Docker controls
- no PC-1 or PC-2 suspend controls
- no real generation trigger
- no generated image serving

## Local Development

```bash
cd apps/dashboard-ui
npm install
npm run dev
```

Do not commit `node_modules`, `dist`, build output, logs, generated media, or runtime data.

## Configuration

Example-only environment values live in `.env.example`:

```text
DASHBOARD_UI_PORT=8500
VITE_GATEWAY_API_URL=http://127.0.0.1:8100
```

## Troubleshooting

Gateway unreachable:

```bash
curl -fsS http://127.0.0.1:8100/gateway/media/dashboard
curl -fsS http://127.0.0.1:8100/gateway/runtime/dashboard
```

Prompt Interpreter unreachable:

```bash
make pc2-prompt-interpreter-health
```

ComfyUI unreachable:

```bash
make comfyui-health
```

Latest images empty:

```bash
make image-latest
```

Runtime cards empty or warning-only:

```bash
make runtime-dashboard-status
make test-runtime-dashboard
```

Dashboard container not running:

```bash
make dashboard-ui-up
make dashboard-ui-health
```

Connection reset immediately after startup can be a readiness race while the Vite server finishes binding inside the container. `make dashboard-ui-health` retries the UI endpoint for up to 20 seconds; if it still fails, wait a few seconds and run it again:

```bash
make dashboard-ui-health
```

## Future M26.9

Dashboard guarded actions are planned later. They should remain explicit, allowlisted, observable, and gated. This MVP is read-only.
