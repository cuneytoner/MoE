.RECIPEPREFIX := >

.PHONY: help check-layout check-python-syntax check-models status tree runtime-prepare docker-up docker-down docker-ps docker-logs health gateway-health memory-dev memory-health nightly-worker-health nightly-worker-run-dry nightly-learning-test-env-help pc2-check-connectivity pc2-check-layout pc2-sync-code pc2-nightly-up pc2-nightly-down pc2-nightly-health pc2-nightly-dry-run pc2-research-up pc2-research-down pc2-research-health pc2-research-dry-run pc2-feedback-up pc2-feedback-down pc2-feedback-health pc2-feedback-sample pc2-improvement-report model-start model-stop model-status model-health model-switch test-gateway test-gateway-chat test-gateway-chat-memory test-gateway-chat-router test-continue-gateway test-code-agent-runtime test-code-patch-runtime test-nightly-learning test-research-ingestion test-feedback-worker test-embed test-bge-m3 test-memory test-stack test

COMPOSE_FILE := infra/docker/docker-compose.yml
ENV_FILE := .env.example
DOCKER_COMPOSE := docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE)

help:
> @echo "MoE / AI-Brain-OS"
> @echo ""
> @echo "Available commands:"
> @echo "  make check-layout   Validate repository layout"
> @echo "  make check-python-syntax Validate Python syntax without bytecode"
> @echo "  make check-models   Validate local model files and Docker mount config"
> @echo "  make status         Show git status"
> @echo "  make tree           Show repository tree"
> @echo "  make runtime-prepare Create runtime folders under /home/cuneyt/MoE/runtime"
> @echo "  make docker-up      Start Docker services"
> @echo "  make docker-down    Stop Docker services"
> @echo "  make docker-ps      Show Docker services"
> @echo "  make docker-logs    Tail Docker service logs"
> @echo "  make health         Check Docker service health"
> @echo "  make gateway-health Check Gateway API /gateway/health"
> @echo "  make memory-dev     Run Memory API locally on port 8101"
> @echo "  make memory-health  Check Memory API /health"
> @echo "  make nightly-worker-health Check Nightly Learning Worker /health"
> @echo "  make nightly-worker-run-dry Run Nightly Learning Worker dry-run endpoint"
> @echo "  make nightly-learning-test-env-help Show optional Nightly Learning test venv setup"
> @echo "  make pc2-check-connectivity Optional read-only PC-2 network and SSH check"
> @echo "  make pc2-check-layout Optional read-only PC-2 runtime and Docker layout check"
> @echo "  make pc2-sync-code Optional sync source-only codebase to PC-2"
> @echo "  make pc2-nightly-up Optional start PC-2 Nightly Learning Worker"
> @echo "  make pc2-nightly-down Optional stop PC-2 Nightly Learning Worker"
> @echo "  make pc2-nightly-health Optional check PC-2 Nightly Learning Worker health"
> @echo "  make pc2-nightly-dry-run Optional run PC-2 Nightly Learning Worker dry run"
> @echo "  make pc2-research-up Optional start PC-2 Research Ingestion Worker"
> @echo "  make pc2-research-down Optional stop PC-2 Research Ingestion Worker"
> @echo "  make pc2-research-health Optional check PC-2 Research Ingestion Worker health"
> @echo "  make pc2-research-dry-run Optional run PC-2 Research Ingestion Worker dry run"
> @echo "  make pc2-feedback-up Optional start PC-2 Feedback Worker"
> @echo "  make pc2-feedback-down Optional stop PC-2 Feedback Worker"
> @echo "  make pc2-feedback-health Optional check PC-2 Feedback Worker health"
> @echo "  make pc2-feedback-sample Optional post sample PC-2 Feedback Worker event/report"
> @echo "  make pc2-improvement-report Optional generate PC-2 prompt/routing improvement report"
> @echo "  make model-start    Start host llama.cpp OpenAI-compatible runtime"
> @echo "  make model-stop     Stop host llama.cpp runtime"
> @echo "  make model-status   Show host llama.cpp runtime status"
> @echo "  make model-health   Check host llama.cpp OpenAI-compatible endpoint"
> @echo "  make model-switch   Safely switch host llama.cpp runtime model"
> @echo "  make test-gateway   Run Gateway API contract tests"
> @echo "  make test-gateway-chat Run optional Gateway chat test"
> @echo "  make test-gateway-chat-memory Run optional memory-augmented Gateway chat test"
> @echo "  make test-gateway-chat-router Run optional router-aware Gateway chat test"
> @echo "  make test-continue-gateway Run optional Continue.dev Gateway chat smoke test"
> @echo "  make test-code-agent-runtime Run optional repo-aware code agent runtime test"
> @echo "  make test-code-patch-runtime Run optional safe patch/diff runtime test"
> @echo "  make test-nightly-learning Run local Nightly Learning Worker tests"
> @echo "  make test-research-ingestion Run local Research Ingestion Worker tests"
> @echo "  make test-feedback-worker Run local Feedback Worker tests"
> @echo "  make test-embed     Run Embed Worker contract tests"
> @echo "  make test-memory    Run Memory API contract tests"
> @echo "  make test-stack     Run Docker-backed stack smoke tests"
> @echo "  make test           Run source-only default tests"

check-layout:
> @./scripts/check-layout.sh

check-python-syntax:
> @./scripts/check-python-syntax.sh

check-models:
> @./scripts/check-models.sh

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

gateway-health:
> @curl -fsS http://127.0.0.1:8100/gateway/health

memory-dev:
> @cd apps/memory-api && uvicorn app.main:app --host 0.0.0.0 --port 8101

memory-health:
> @curl -fsS http://127.0.0.1:8101/health

nightly-worker-health:
> @curl -fsS http://127.0.0.1:8200/health

nightly-worker-run-dry:
> @curl -fsS -H "Content-Type: application/json" -X POST -d '{"mode":"dry_run","include_git_status":true,"include_gateway_summary":true,"include_memory_summary":true,"store_lessons":false}' http://127.0.0.1:8200/nightly/run

nightly-learning-test-env-help:
> @echo "Recommended source-only setup using a repo-external venv:"
> @echo "  mkdir -p ~/MoE/runtime/venvs"
> @echo "  python3 -m venv ~/MoE/runtime/venvs/nightly-learning"
> @echo "  source ~/MoE/runtime/venvs/nightly-learning/bin/activate"
> @echo "  pip install -r apps/nightly-learning-worker/requirements.txt"
> @echo "  make test-nightly-learning"
> @echo ""
> @echo "Do not create a virtualenv inside the codebase."

pc2-check-connectivity:
> @./scripts/check-pc2-connectivity.sh

pc2-check-layout:
> @./scripts/check-pc2-layout.sh

pc2-sync-code:
> @./scripts/pc2-sync-code.sh

pc2-nightly-up:
> @./scripts/pc2-nightly-worker-up.sh

pc2-nightly-down:
> @./scripts/pc2-nightly-worker-down.sh

pc2-nightly-health:
> @./scripts/pc2-nightly-worker-health.sh

pc2-nightly-dry-run:
> @./scripts/pc2-nightly-worker-dry-run.sh

pc2-research-up:
> @./scripts/pc2-research-worker-up.sh

pc2-research-down:
> @./scripts/pc2-research-worker-down.sh

pc2-research-health:
> @./scripts/pc2-research-worker-health.sh

pc2-research-dry-run:
> @./scripts/pc2-research-worker-dry-run.sh

pc2-feedback-up:
> @./scripts/pc2-feedback-worker-up.sh

pc2-feedback-down:
> @./scripts/pc2-feedback-worker-down.sh

pc2-feedback-health:
> @./scripts/pc2-feedback-worker-health.sh

pc2-feedback-sample:
> @./scripts/pc2-feedback-worker-sample.sh

pc2-improvement-report:
> @./scripts/pc2-improvement-report.sh

model-start:
> @./scripts/model-runtime-start.sh $(MODEL)

model-stop:
> @./scripts/model-runtime-stop.sh

model-status:
> @./scripts/model-runtime-status.sh

model-health:
> @./scripts/model-runtime-health.sh

model-switch:
> @./scripts/model-runtime-switch.sh $(MODEL)

test-gateway:
> @./scripts/test-gateway-api.sh

test-gateway-chat:
> @RUN_GATEWAY_CHAT_TEST=1 ./scripts/test-gateway-api.sh

test-gateway-chat-memory:
> @RUN_GATEWAY_CHAT_MEMORY_TEST=1 ./scripts/test-gateway-api.sh

test-gateway-chat-router:
> @RUN_GATEWAY_CHAT_ROUTER_TEST=1 ./scripts/test-gateway-api.sh

test-continue-gateway:
> @./scripts/test-continue-gateway.sh

test-code-agent-runtime:
> @./scripts/test-code-agent-runtime.sh

test-code-patch-runtime:
> @./scripts/test-code-patch-runtime.sh

test-nightly-learning:
> @./scripts/test-nightly-learning-worker.sh

test-research-ingestion:
> @./scripts/test-research-ingestion-worker.sh

test-feedback-worker:
> @./scripts/test-feedback-worker.sh

test-memory:
> @./scripts/test-memory-api.sh

test-embed:
> @./scripts/test-embed-worker.sh

test-bge-m3:
> @./scripts/test-bge-m3-runtime.sh

test-stack:
> @./scripts/test-stack.sh

test: check-layout check-python-syntax
