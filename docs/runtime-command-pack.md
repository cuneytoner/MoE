# Runtime Command Pack

Milestone 26.5.1 adds fixed, user-run command scripts for PC-1, PC-2, and combined startup/sleep flows.

The scripts are operational helpers only. They do not delete runtime data, delete model files, delete generated media, run `docker system prune`, remove images, enable real generation by default, or start the ComfyUI external bridge by default.

## Safety Rules

- Suspend scripts require `APPLY=1`.
- Startup and prepare scripts support `DRY_RUN=1` where useful.
- Commands are fixed in source; arbitrary caller-supplied commands are not accepted.
- Runtime data stays under `/home/cuneyt/MoE/runtime`.
- Models stay under `/home/cuneyt/MoE_Models_Backup`.
- Real media generation remains disabled unless manually enabled later.

## PC-1 Scripts

```bash
make pc1-sleep-prepare
APPLY=1 make pc1-suspend
make pc1-startup-coding
make pc1-startup-media-dry
make pc1-status
```

`pc1-sleep-prepare` disables media real generation, stops ComfyUI if it is running, reports `llama-server`, optionally stops it with `STOP_LLM=1`, prints Docker status, and prints GPU status.

`pc1-startup-coding` starts the safe base Docker stack, keeps media real generation disabled, switches to `qwen-coder-14b-fast`, and runs health checks.

`pc1-startup-media-dry` starts the safe base Docker stack, keeps real generation disabled, does not start ComfyUI, and runs Gateway media dry-run checks.

`pc1-status` is read-only.

## PC-2 Local Scripts

These are designed to run on PC-2:

```bash
make pc2-local-sleep-prepare
APPLY=1 make pc2-local-suspend
make pc2-local-startup-workers
make pc2-local-status
```

PC-2 scripts locate `/home/cuneyt/MoE/codebase` first, then fall back to `/home/cuneyt/MoE`.

`pc2-local-startup-workers` starts Nightly Learning, Research Ingestion, Feedback, and Prompt Interpreter workers through the PC-2 worker compose file. The Nightly Learning compose profile is named `learning` in this repo. Each worker start is best-effort so one failed worker does not hide the rest of the status.

## Cluster Scripts

Run these from PC-1:

```bash
make cluster-sleep-prepare
APPLY=1 make cluster-suspend
make cluster-startup-coding
make cluster-startup-media-dry
make cluster-status
```

Cluster scripts use passwordless SSH to:

```text
cuneyt@192.168.50.2
```

If the remote PC-2 runtime script is missing, status and sleep-prepare scripts fall back to `docker ps`. Cluster suspend falls back to `sudo systemctl suspend` on PC-2, then suspends PC-1.

## Sleep Flow

Recommended safe sleep flow:

```bash
make cluster-status
make cluster-sleep-prepare
APPLY=1 make cluster-suspend
```

For PC-1 only:

```bash
make pc1-sleep-prepare
APPLY=1 make pc1-suspend
```

For PC-2 locally:

```bash
make pc2-local-sleep-prepare
APPLY=1 make pc2-local-suspend
```

Suspend may require local sudo/systemd policy depending on the machine.

## Wake / Startup Flow

After wake, use one of:

```bash
make cluster-startup-coding
make cluster-startup-media-dry
```

Coding mode starts the coding model and dashboard checks. Media dry-run mode keeps real generation disabled and does not start ComfyUI by default.

## Real Generation

Real generation is intentionally not automatic.

Manual real generation still requires:

1. Explicit image mode planning.
2. `COMFYUI_ALLOW_EXTERNAL=1 COMFYUI_HOST=0.0.0.0 make comfyui-up`.
3. `MEDIA_REAL_GENERATION_ENABLED=true` on Media API and Media Worker.
4. `GATEWAY_MEDIA_REAL_ALLOWED=true` on Gateway.
5. `confirm_real_generation=true` in the request.

The command pack does not perform those steps by default.

## Troubleshooting

PC-2 unreachable:

```bash
make pc2-check-connectivity
```

ComfyUI down:

```bash
make comfyui-health
```

`llama-server` already running:

```bash
make model-status
make model-health
```

Docker containers stale:

```bash
make docker-ps
make health
```

Suspend requires sudo:

```bash
APPLY=1 make pc1-suspend
APPLY=1 make pc2-local-suspend
APPLY=1 make cluster-suspend
```

If systemd policy asks for a password, approve it locally at the terminal.
