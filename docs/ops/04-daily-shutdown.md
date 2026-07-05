# 04 Daily Shutdown

Shutdown is manual. Stop only what you intend to stop.

## PC-1 Shutdown

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-status
make model-stop
make docker-ps
make docker-down
```

Expected good signs:

- `make model-stop` stops the host llama-server started by the project script.
- `make docker-down` stops the Compose stack without deleting volumes.

## PC-2 Shutdown

Check first:

### Run on PC-2

```bash
docker ps
```

Stop worker/support services only if you intentionally want PC-2 down:

### Run on PC-2

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose --env-file .env.example -f infra/docker/docker-compose.yml down
docker ps
```

## Warnings

- Do not remove Docker volumes during daily shutdown.
- Do not use `docker system prune` unless you are advanced, backed up, and understand what will be deleted.
- Do not kill random processes.
- If a process is stuck, inspect it first and prefer project scripts such as `make model-stop`.
