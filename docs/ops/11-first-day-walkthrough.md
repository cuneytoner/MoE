# 11 First Day Walkthrough

This guide is for a beginner operator on the first day with the system. Follow it in order. Do not skip ahead unless a step says it is optional.

## Who This Guide Is For

Use this if:

- You are on PC-1 and want to know whether the system is alive.
- You have PC-2 on the direct wired link at `192.168.50.2`.
- You do not yet know which service runs where.

PC-1 is `192.168.50.1`. PC-2 is `192.168.50.2`.

## Before Touching Anything

Read [13-service-location-reference.md](13-service-location-reference.md) if you are unsure where a command should run.

Expected good sign before you begin: you can open a terminal on PC-1, and if PC-2 is used, you can open a terminal on PC-2 or SSH into it.

## Step 1: Verify PC-2 Network

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
```

Expected good sign: the output shows replies from `192.168.50.2` and packet loss is `0%`.

If this fails, read [07-troubleshooting.md#pc-1-cannot-ping-pc-2](07-troubleshooting.md#pc-1-cannot-ping-pc-2).

## Step 2: Verify PC-2 Services

### Run on PC-1 to check PC-2

```bash
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: Memory API and Embed Worker return JSON, and Qdrant returns a ready response.

If this fails, read [07-troubleshooting.md#pc-2-memory-unreachable-from-pc-1](07-troubleshooting.md#pc-2-memory-unreachable-from-pc-1).

## Step 3: Verify PC-1 Repo

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
pwd
git status --short
```

Expected good sign: `pwd` prints `/home/cuneyt/DiskD/Projects/MoE/codebase`, and `git status --short` is empty or only shows changes you recognize.

If this fails, read [09-git-workflow.md](09-git-workflow.md).

## Step 4: Verify PC-1 Docker Services

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker ps
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
```

Expected good sign: `docker ps` shows `moe-gateway-api`, and Gateway health returns JSON.

If this fails, read [07-troubleshooting.md#gateway-unavailable](07-troubleshooting.md#gateway-unavailable).

## Step 5: Verify llama-server

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-status
curl -fsS http://127.0.0.1:8000/v1/models | jq .
```

Expected good sign: `/v1/models` returns JSON with a model list.

If this fails, read [07-troubleshooting.md#llama-server-unavailable](07-troubleshooting.md#llama-server-unavailable).

## Step 6: Verify Gateway

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good sign: Gateway health returns JSON and Gateway `/v1/models` returns a model list.

If this fails, read [07-troubleshooting.md#gateway-unavailable](07-troubleshooting.md#gateway-unavailable).

## Step 7: Verify Continue.dev

Continue runs on PC-1. Confirm the config uses:

```yaml
apiBase: http://localhost:8100/v1
model: gateway-auto
```

Expected good sign: Continue is configured to call Gateway on PC-1, not llama-server directly.

If this fails, read [07-troubleshooting.md#continue-returns-only-ok-or-no-answer](07-troubleshooting.md#continue-returns-only-ok-or-no-answer).

## Step 8: Run One Gateway Chat Test

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gateway-auto","messages":[{"role":"user","content":"Reply with one short sentence."}]}' | jq .
```

Expected good sign: JSON includes `choices[0].message.content`.

If this fails, read [07-troubleshooting.md#continue-returns-only-ok-or-no-answer](07-troubleshooting.md#continue-returns-only-ok-or-no-answer).

## Step 9: If Something Fails, Where To Go

| Failed area | Read |
| --- | --- |
| PC-2 network | [07 Troubleshooting](07-troubleshooting.md#pc-1-cannot-ping-pc-2) |
| PC-2 Memory API | [07 Troubleshooting](07-troubleshooting.md#pc-2-memory-unreachable-from-pc-1) |
| PC-1 Gateway | [07 Troubleshooting](07-troubleshooting.md#gateway-unavailable) |
| llama-server | [07 Troubleshooting](07-troubleshooting.md#llama-server-unavailable) |
| Continue | [07 Troubleshooting](07-troubleshooting.md#continue-returns-only-ok-or-no-answer) |
| Unsure where service lives | [13 Service Location Reference](13-service-location-reference.md) |
