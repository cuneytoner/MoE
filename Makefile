.RECIPEPREFIX := >

.PHONY: help check-layout status tree runtime-prepare docker-up docker-down docker-ps docker-logs health

COMPOSE_FILE := infra/docker/docker-compose.yml
ENV_FILE := .env.example
DOCKER_COMPOSE := docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE)

help:
> @echo "MoE / AI-Brain-OS"
> @echo ""
> @echo "Available commands:"
> @echo "  make check-layout   Validate repository layout"
> @echo "  make status         Show git status"
> @echo "  make tree           Show repository tree"
> @echo "  make runtime-prepare Create runtime folders under /home/cuneyt/MoE/runtime"
> @echo "  make docker-up      Start Docker services"
> @echo "  make docker-down    Stop Docker services"
> @echo "  make docker-ps      Show Docker services"
> @echo "  make docker-logs    Tail Docker service logs"
> @echo "  make health         Check Docker service health"

check-layout:
> @./scripts/check-layout.sh

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
