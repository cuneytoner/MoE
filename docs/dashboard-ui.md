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

It reads Gateway's existing dashboard endpoint:

```text
GET /gateway/media/dashboard
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

## Run

Start the UI:

```bash
make dashboard-ui-up
```

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
