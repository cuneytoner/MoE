.RECIPEPREFIX := >

.PHONY: help check-layout check-python-syntax status tree runtime-prepare docker-up docker-down docker-ps docker-logs health memory-dev memory-health test-embed test-memory test-stack test

COMPOSE_FILE := infra/docker/docker-compose.yml
ENV_FILE := .env.example
DOCKER_COMPOSE := docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE)

help:
> @echo "MoE / AI-Brain-OS"
> @echo ""
> @echo "Available commands:"
> @echo "  make check-layout   Validate repository layout"
> @echo "  make check-python-syntax Validate Python syntax without bytecode"
> @echo "  make status         Show git status"
> @echo "  make tree           Show repository tree"
> @echo "  make runtime-prepare Create runtime folders under /home/cuneyt/MoE/runtime"
> @echo "  make docker-up      Start Docker services"
> @echo "  make docker-down    Stop Docker services"
> @echo "  make docker-ps      Show Docker services"
> @echo "  make docker-logs    Tail Docker service logs"
> @echo "  make health         Check Docker service health"
> @echo "  make memory-dev     Run Memory API locally on port 8101"
> @echo "  make memory-health  Check Memory API /health"
> @echo "  make test-embed     Run Embed Worker contract tests"
> @echo "  make test-memory    Run Memory API contract tests"
> @echo "  make test-stack     Run stack smoke tests"
> @echo "  make test           Run layout and stack tests"

check-layout:
> @./scripts/check-layout.sh

check-python-syntax:
> @./scripts/check-python-syntax.sh

status:
> @git status --short

tree:
> @tree -a -I '.git' -L 3

runtime-prepare:
> @./scripts/runtime-prepare.sh

docker-up:
> @$(DOCKER_COMPOSE) up -d

docker-down:
> @$(DOCKER_COMPOSE) down

docker-ps:
> @$(DOCKER_COMPOSE) ps

docker-logs:
> @$(DOCKER_COMPOSE) logs -f

health:
> @./scripts/health.sh

memory-dev:
> @cd apps/memory-api && uvicorn app.main:app --host 0.0.0.0 --port 8101

memory-health:
> @curl -fsS http://127.0.0.1:8101/health

test-memory:
> @./scripts/test-memory-api.sh

test-embed:
> @./scripts/test-embed-worker.sh

test-stack:
> @./scripts/test-stack.sh

test: check-layout check-python-syntax test-stack
