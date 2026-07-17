.RECIPEPREFIX := >

.PHONY: help check-layout check-python-syntax check-media-layout check-image-models check-comfyui-layout check-comfyui-layout-create check-comfyui-runtime plan-image-model-downloads plan-flux-schnell-models download-flux-schnell-models-plan download-flux-schnell-models-apply check-flux-schnell-models link-comfyui-models-dry-run link-comfyui-models-apply install-comfyui-runtime comfyui-up comfyui-down comfyui-health comfyui-vram-status comfyui-flux-smoke-test comfyui-first-image-plan comfyui-first-image-apply image-readiness image-dry-run image-mode-prepare image-real-run image-latest image-safe-shutdown image-full-cycle dashboard-ui-up dashboard-ui-down dashboard-ui-health dashboard-ui-open control-api-test control-api-up control-api-down runtime-status runtime-dashboard-status runtime-mode-coding-plan runtime-mode-image-plan runtime-mode-video-plan runtime-mode-3d-suite-plan runtime-mode-media-off-plan check-models model-inventory model-registry-check status tree runtime-prepare docker-up docker-down docker-ps docker-logs docker-summary-snapshot docker-summary-status health gateway-health memory-dev memory-health nightly-worker-health nightly-worker-run-dry nightly-learning-test-env-help media-api-up media-api-down media-image-dry-run media-image-real-run media-latest-images gateway-media-plan gateway-media-dry-run gateway-media-real-plan media-dashboard-status media-output-cards-status media-dashboard-open feedback-summary-local feedback-sync-status feedback-sync-to-pc2 learning-loop-report-local improvement-plan-local improvement-patch-plan-local router-prompt-approval-local feedback-memory-candidates-local memory-store-plan-local memory-store-approved memory-store-real-apply-guardrail memory-store-audit-local memory-store-apply-log-status memory-candidate-approval-helper-local memory-candidate-list-local memory-approval-dry-run-e2e-local memory-approval-dry-run-e2e-status reference-board-store-smoke-test reference-board-export-regression reference-board-malformed-store-regression reference-board-store-validate reference-board-store-backup reference-board-store-repair reference-board-store-repair-regression reference-board-duplicate-item-repair-regression reference-board-stale-item-regression pc1-sleep-prepare pc1-suspend pc1-startup-coding pc1-startup-media-dry pc1-status pc2-local-sleep-prepare pc2-local-suspend pc2-local-startup-workers pc2-local-status cluster-sleep-prepare cluster-suspend cluster-startup-coding cluster-startup-media-dry cluster-status pc2-check-connectivity pc2-check-layout pc2-sync-code pc2-system-status pc2-nightly-up pc2-nightly-down pc2-nightly-health pc2-nightly-dry-run pc2-research-up pc2-research-down pc2-research-health pc2-research-dry-run pc2-feedback-up pc2-feedback-down pc2-feedback-health pc2-feedback-sample pc2-improvement-report pc2-prompt-interpreter-up pc2-prompt-interpreter-down pc2-prompt-interpreter-health pc2-prompt-interpreter-sample pergola-svg-skeleton drawing-engine-demo model-start model-stop model-status model-health model-switch test-gateway test-gateway-media test-media-dashboard test-runtime-dashboard test-dashboard-ui test-3d-output-cards-ui test-3d-reference-board-selection test-m35-phase-closure test-memory-approval-dashboard test-openai-compatible-gateway test-gateway-chat-proxy test-gateway-chat test-gateway-chat-memory test-gateway-chat-router test-gateway-memory-injection test-gateway-feedback test-feedback-worker-bridge test-feedback-sync test-learning-loop-report test-improvement-plan test-improvement-patch-plan test-router-prompt-approval test-feedback-memory-candidates test-memory-store-workflow test-memory-store-audit test-memory-store-apply-log test-memory-store-real-apply-guardrail test-memory-candidate-approval-helper test-memory-approval-dry-run-e2e test-3d-generator-skeleton test-3d-parameter-config test-3d-dry-run-review test-3d-generation-guards test-3d-metadata-sidecar-writer test-3d-metadata-sidecar-validator test-3d-primitive-builder test-3d-blender-adapter test-3d-first-generation-drill-plan test-3d-artifact-verifier test-3d-output-card-api test-continue-gateway test-code-agent-runtime test-code-patch-runtime test-nightly-learning test-research-ingestion test-feedback-worker test-prompt-interpreter-worker test-media-api test-media-image-bridge test-image-dry-run test-embed test-bge-m3 test-memory test-stack test

COMPOSE_FILE := infra/docker/docker-compose.yml
ENV_FILE := .env.example
DOCKER_COMPOSE := docker compose --env-file $(ENV_FILE) -f $(COMPOSE_FILE)

help:
> @echo "MoE / AI-Brain-OS"
> @echo ""
> @echo "Available commands:"
> @echo "  make check-layout   Validate repository layout"
> @echo "  make check-python-syntax Validate Python syntax without bytecode"
> @echo "  make check-media-layout Prepare/validate runtime media directories"
> @echo "  make check-image-models Inspect optional local image model candidates"
> @echo "  make check-comfyui-layout Inspect optional ComfyUI runtime layout"
> @echo "  make check-comfyui-layout-create Create optional ComfyUI runtime layout"
> @echo "  make check-comfyui-runtime Inspect optional ComfyUI runtime install"
> @echo "  make plan-image-model-downloads Print image model component plan without downloads"
> @echo "  make plan-flux-schnell-models Print Flux Schnell component plan without downloads"
> @echo "  make download-flux-schnell-models-plan Print Flux Schnell download plan"
> @echo "  make download-flux-schnell-models-apply Download Flux Schnell models to backup dir"
> @echo "  make check-flux-schnell-models Validate Flux Schnell model files"
> @echo "  make link-comfyui-models-dry-run Preview ComfyUI model symlinks"
> @echo "  make link-comfyui-models-apply Create ComfyUI model symlinks"
> @echo "  make install-comfyui-runtime Optional install ComfyUI runtime under ~/MoE/runtime"
> @echo "  make comfyui-up     Optional start local ComfyUI on 127.0.0.1:8188"
> @echo "  make comfyui-down   Optional stop local ComfyUI from runtime PID"
> @echo "  make comfyui-health Optional check local ComfyUI HTTP health"
> @echo "  make comfyui-vram-status Optional print GPU VRAM status"
> @echo "  make comfyui-flux-smoke-test Optional read-only Flux readiness check"
> @echo "  make comfyui-first-image-plan Print first Flux image plan"
> @echo "  make comfyui-first-image-apply Submit first Flux image workflow"
> @echo "  make image-readiness Guided image readiness check"
> @echo "  make image-dry-run Guided image dry-run flow"
> @echo "  make image-mode-prepare Guarded image mode prepare, requires APPLY=1"
> @echo "  make image-real-run Guarded real image run, requires APPLY=1"
> @echo "  make image-latest List guided image outputs"
> @echo "  make image-safe-shutdown Guarded return to safe/coding state"
> @echo "  make image-full-cycle Guided dry-run by default; real cycle requires confirmation"
> @echo "  make dashboard-ui-up Optional start read-only Dashboard UI"
> @echo "  make dashboard-ui-down Stop Dashboard UI only"
> @echo "  make dashboard-ui-health Check Dashboard UI and Gateway dashboard endpoint"
> @echo "  make dashboard-ui-open Open or print Dashboard UI URL"
> @echo "  make control-api-test Run local Control API tests"
> @echo "  make control-api-up Optional run Control API locally on port 8400"
> @echo "  make control-api-down Optional placeholder; stop Ctrl-C local process"
> @echo "  make runtime-status Read-only runtime status"
> @echo "  make runtime-dashboard-status Show read-only Gateway runtime dashboard"
> @echo "  make runtime-mode-coding-plan Print coding mode plan"
> @echo "  make runtime-mode-image-plan Print image mode plan"
> @echo "  make runtime-mode-video-plan Print video mode plan"
> @echo "  make runtime-mode-3d-suite-plan Print 3D suite mode plan"
> @echo "  make runtime-mode-media-off-plan Print media-off mode plan"
> @echo "  make check-models   Validate local model files and Docker mount config"
> @echo "  make model-inventory Scan active/archive model roots and write runtime report"
> @echo "  make model-registry-check Validate active required registry paths"
> @echo "  make status         Show git status"
> @echo "  make tree           Show repository tree"
> @echo "  make runtime-prepare Create runtime folders under /home/cuneyt/MoE/runtime"
> @echo "  make docker-up      Start Docker services"
> @echo "  make docker-down    Stop Docker services"
> @echo "  make docker-ps      Show Docker services"
> @echo "  make docker-logs    Tail Docker service logs"
> @echo "  make docker-summary-snapshot Write read-only Docker summary snapshot under runtime"
> @echo "  make docker-summary-status Print latest Docker summary snapshot"
> @echo "  make health         Check Docker service health"
> @echo "  make gateway-health Check Gateway API /gateway/health"
> @echo "  make memory-dev     Run Memory API locally on port 8101"
> @echo "  make memory-health  Check Memory API /health"
> @echo "  make nightly-worker-health Check Nightly Learning Worker /health"
> @echo "  make nightly-worker-run-dry Run Nightly Learning Worker dry-run endpoint"
> @echo "  make nightly-learning-test-env-help Show optional Nightly Learning test venv setup"
> @echo "  make media-api-up   Optional start Media Lab services with Docker media profile"
> @echo "  make media-api-down Optional stop Media Lab services with Docker media profile"
> @echo "  make media-image-dry-run Optional submit/process dry-run image job"
> @echo "  make media-image-real-run Optional gated real image job"
> @echo "  make media-latest-images List latest runtime media images"
> @echo "  make gateway-media-plan Plan a guarded Gateway media request"
> @echo "  make gateway-media-dry-run Create a Gateway media dry-run job"
> @echo "  make gateway-media-real-plan Demonstrate guarded real generation rejection"
> @echo "  make media-dashboard-status Show read-only Media Dashboard status"
> @echo "  make media-output-cards-status Show read-only Media Output Cards status"
> @echo "  make media-dashboard-open Print Media Dashboard endpoint/UI locations"
> @echo "  make pergola-svg-skeleton Generate draft pergola SVG skeleton under runtime"
> @echo "  make drawing-engine-demo Generate generic drawing engine demo SVG under runtime"
> @echo "  make feedback-summary-local Generate local Gateway feedback summary under runtime"
> @echo "  make feedback-sync-status Read-only PC1/PC2 Gateway feedback sync status"
> @echo "  make feedback-sync-to-pc2 Dry-run Gateway feedback sync to PC2; use APPLY=1 to sync"
> @echo "  make learning-loop-report-local Generate reviewed learning loop report under runtime"
> @echo "  make improvement-plan-local Generate human-approved improvement plan under runtime"
> @echo "  make improvement-patch-plan-local Generate reviewed improvement patch plan under runtime"
> @echo "  make router-prompt-approval-local Generate router/prompt approval packet under runtime"
> @echo "  make feedback-memory-candidates-local Generate feedback memory candidate review under runtime"
> @echo "  make memory-store-plan-local Generate human-approved memory store plan under runtime"
> @echo "  make memory-store-approved Dry-run approved memory storage; APPLY=1 writes to Memory API"
> @echo "  make memory-store-real-apply-guardrail Read-only guardrail review before real memory apply"
> @echo "  make memory-store-audit-local Generate memory store audit under runtime"
> @echo "  make memory-store-apply-log-status Show memory store apply log status"
> @echo "  make memory-candidate-approval-helper-local Generate human review helper report under runtime"
> @echo "  make memory-candidate-list-local List memory candidates for review"
> @echo "  make memory-approval-dry-run-e2e-local Run memory approval dry-run E2E flow"
> @echo "  make memory-approval-dry-run-e2e-status Show memory approval dry-run E2E status"
> @echo "  make reference-board-export-regression Run safe reference board export/download regression"
> @echo "  make reference-board-malformed-store-regression Run malformed reference board store regression"
> @echo "  make reference-board-store-validate Run read-only reference board store validation"
> @echo "  make reference-board-store-backup Back up one reference board JSON file; requires BOARD_ID"
> @echo "  make reference-board-store-repair Dry-run reference board schema repair; APPLY=1 requires backup"
> @echo "  make reference-board-store-repair-regression Run controlled reference board repair regression"
> @echo "  make reference-board-duplicate-item-repair-regression Run controlled duplicate item repair regression"
> @echo "  make reference-board-stale-item-regression Run controlled stale item marking regression"
> @echo "  make pc1-sleep-prepare Prepare PC-1 for sleep without suspending"
> @echo "  make pc1-suspend Guarded PC-1 suspend, requires APPLY=1"
> @echo "  make pc1-startup-coding Start PC-1 coding stack"
> @echo "  make pc1-startup-media-dry Start PC-1 dry-run media stack"
> @echo "  make pc1-status Show PC-1 runtime status"
> @echo "  make pc2-local-startup-workers Start PC-2 workers locally on PC-2"
> @echo "  make cluster-startup-coding Start PC-1 coding stack and PC-2 workers"
> @echo "  make cluster-status Show PC-1 and PC-2 runtime status"
> @echo "  make pc2-check-connectivity Optional read-only PC-2 network and SSH check"
> @echo "  make pc2-check-layout Optional read-only PC-2 runtime and Docker layout check"
> @echo "  make pc2-sync-code Optional sync source-only codebase to PC-2"
> @echo "  make pc2-system-status Optional read-only PC-2 system status over HTTP"
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
> @echo "  make pc2-prompt-interpreter-up Optional start PC-2 Prompt Interpreter Worker"
> @echo "  make pc2-prompt-interpreter-down Optional stop PC-2 Prompt Interpreter Worker"
> @echo "  make pc2-prompt-interpreter-health Optional check PC-2 Prompt Interpreter Worker health"
> @echo "  make pc2-prompt-interpreter-sample Optional post sample prompt interpretations"
> @echo "  make model-start    Start host llama.cpp OpenAI-compatible runtime"
> @echo "  make model-stop     Stop host llama.cpp runtime"
> @echo "  make model-status   Show host llama.cpp runtime status"
> @echo "  make model-health   Check host llama.cpp OpenAI-compatible endpoint"
> @echo "  make model-switch   Safely switch host llama.cpp runtime model"
> @echo "  make test-gateway   Run Gateway API contract tests"
> @echo "  make test-memory-approval-dashboard Run read-only memory approval dashboard checks"
> @echo "  make test-openai-compatible-gateway Run optional OpenAI-compatible Gateway smoke test"
> @echo "  make test-gateway-chat-proxy Run optional Gateway chat proxy smoke test"
> @echo "  make test-gateway-chat Run optional Gateway chat test"
> @echo "  make test-gateway-chat-memory Run optional memory-augmented Gateway chat test"
> @echo "  make test-gateway-chat-router Run optional Gateway chat advisory router test"
> @echo "  make test-gateway-memory-injection Run optional Gateway chat memory injection test"
> @echo "  make test-gateway-feedback Run optional Gateway feedback capture test"
> @echo "  make test-feedback-worker-bridge Run optional Feedback Worker bridge test"
> @echo "  make test-feedback-sync Run local feedback sync tooling tests"
> @echo "  make test-learning-loop-report Run local reviewed learning loop report tests"
> @echo "  make test-improvement-plan Run local human-approved improvement plan tests"
> @echo "  make test-improvement-patch-plan Run local reviewed improvement patch plan tests"
> @echo "  make test-router-prompt-approval Run local router/prompt approval packet tests"
> @echo "  make test-feedback-memory-candidates Run local feedback memory candidate review tests"
> @echo "  make test-memory-store-workflow Run local human-approved memory store workflow tests"
> @echo "  make test-memory-store-audit Run local memory store audit tests"
> @echo "  make test-memory-store-apply-log Run local memory store apply log tests"
> @echo "  make test-memory-store-real-apply-guardrail Run read-only real apply guardrail tests"
> @echo "  make test-memory-candidate-approval-helper Run local memory candidate approval helper tests"
> @echo "  make test-memory-approval-dry-run-e2e Run local memory approval dry-run E2E tests"
> @echo "  make test-continue-gateway Run optional Continue.dev Gateway chat smoke test"
> @echo "  make test-code-agent-runtime Run optional repo-aware code agent runtime test"
> @echo "  make test-code-patch-runtime Run optional safe patch/diff runtime test"
> @echo "  make test-nightly-learning Run local Nightly Learning Worker tests"
> @echo "  make test-research-ingestion Run local Research Ingestion Worker tests"
> @echo "  make test-feedback-worker Run local Feedback Worker tests"
> @echo "  make test-prompt-interpreter-worker Run local Prompt Interpreter Worker tests"
> @echo "  make test-media-api Run local Media API tests"
> @echo "  make test-media-image-bridge Run local Media image bridge tests"
> @echo "  make test-image-dry-run Run local image dry-run tests"
> @echo "  make test-embed     Run Embed Worker contract tests"
> @echo "  make test-memory    Run Memory API contract tests"
> @echo "  make test-stack     Run Docker-backed stack smoke tests"
> @echo "  make test           Run source-only default tests"

check-layout:
> @./scripts/check-layout.sh

check-python-syntax:
> @./scripts/check-python-syntax.sh

check-media-layout:
> @./scripts/check-media-layout.sh

check-image-models:
> @./scripts/check-image-models.sh

check-comfyui-layout:
> @./scripts/check-comfyui-layout.sh

check-comfyui-layout-create:
> @CREATE=1 ./scripts/check-comfyui-layout.sh

check-comfyui-runtime:
> @./scripts/check-comfyui-runtime.sh

plan-image-model-downloads:
> @./scripts/plan-image-model-downloads.sh

plan-flux-schnell-models:
> @./scripts/plan-flux-schnell-models.sh

download-flux-schnell-models-plan:
> @./scripts/download-flux-schnell-models.sh

download-flux-schnell-models-apply:
> @APPLY=1 ./scripts/download-flux-schnell-models.sh

check-flux-schnell-models:
> @./scripts/check-flux-schnell-models.sh

link-comfyui-models-dry-run:
> @./scripts/link-comfyui-models.sh

link-comfyui-models-apply:
> @APPLY=1 ./scripts/link-comfyui-models.sh

install-comfyui-runtime:
> @./scripts/install-comfyui-runtime.sh

comfyui-up:
> @./scripts/comfyui-up.sh

comfyui-down:
> @./scripts/comfyui-down.sh

comfyui-health:
> @./scripts/comfyui-health.sh

comfyui-vram-status:
> @./scripts/comfyui-vram-status.sh

comfyui-flux-smoke-test:
> @./scripts/comfyui-flux-smoke-test.sh

comfyui-first-image-plan:
> @./scripts/comfyui-first-image.sh

comfyui-first-image-apply:
> @APPLY=1 ./scripts/comfyui-first-image.sh

image-readiness:
> @./scripts/image/image-readiness.sh

image-dry-run:
> @./scripts/image/image-dry-run.sh

image-controlled-variant-plan:
> @./scripts/image/controlled-variant-plan.sh

image-mode-prepare:
> @./scripts/image/image-mode-prepare.sh

image-real-run:
> @./scripts/image/image-real-run.sh

image-latest:
> @./scripts/image/image-latest.sh

image-safe-shutdown:
> @./scripts/image/image-safe-shutdown.sh

image-full-cycle:
> @./scripts/image/image-full-cycle.sh

dashboard-ui-up:
> @./scripts/dashboard-ui-up.sh

dashboard-ui-down:
> @./scripts/dashboard-ui-down.sh

dashboard-ui-health:
> @./scripts/dashboard-ui-health.sh

dashboard-ui-open:
> @./scripts/dashboard-ui-open.sh

control-api-test:
> @./scripts/test-control-api.sh

control-api-up:
> @cd apps/control-api && uvicorn app.main:app --host 127.0.0.1 --port 8400

control-api-down:
> @echo "Control API local dev server is stopped with Ctrl-C in the terminal running make control-api-up."

runtime-status:
> @./scripts/runtime-status.sh

runtime-mode-coding-plan:
> @./scripts/runtime-mode-coding.sh

runtime-mode-image-plan:
> @./scripts/runtime-mode-image.sh

runtime-mode-video-plan:
> @./scripts/runtime-mode-video.sh

runtime-mode-3d-suite-plan:
> @./scripts/runtime-mode-3d-suite.sh

runtime-mode-media-off-plan:
> @./scripts/runtime-mode-media-off.sh

check-models:
> @./scripts/check-models.sh

model-inventory:
> @./scripts/model-inventory.sh

model-registry-check:
> @./scripts/model-registry-check.sh

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

docker-summary-snapshot:
> @./scripts/docker-summary-snapshot.sh

docker-summary-status:
> @./scripts/docker-summary-status.sh

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

media-api-up:
> @$(DOCKER_COMPOSE) --profile media up -d --build media-api media-worker

media-api-down:
> @$(DOCKER_COMPOSE) --profile media stop media-api media-worker

media-image-dry-run:
> @./scripts/media-image-dry-run.sh

media-image-real-run:
> @./scripts/media-image-real-run.sh

media-latest-images:
> @./scripts/media-latest-images.sh

gateway-media-plan:
> @./scripts/gateway-media-plan.sh

gateway-media-dry-run:
> @./scripts/gateway-media-dry-run.sh

gateway-media-real-plan:
> @./scripts/gateway-media-real-plan.sh

media-dashboard-status:
> @./scripts/media-dashboard-status.sh

media-output-cards-status:
> @./scripts/media-output-cards-status.sh

reference-board-store-smoke-test:
> @./scripts/reference-board-store-smoke-test.sh

reference-board-export-regression:
> @./scripts/reference-board-export-regression.sh

reference-board-malformed-store-regression:
> @./scripts/reference-board-malformed-store-regression.sh

reference-board-store-validate:
> @./scripts/reference-board-store-validate.sh

reference-board-store-backup:
> @./scripts/reference-board-store-backup.sh

reference-board-store-repair:
> @./scripts/reference-board-store-repair.sh

reference-board-store-repair-regression:
> @./scripts/reference-board-store-repair-regression.sh

reference-board-duplicate-item-repair-regression:
> @./scripts/reference-board-duplicate-item-repair-regression.sh

reference-board-stale-item-regression:
> @./scripts/reference-board-stale-item-regression.sh

media-dashboard-open:
> @./scripts/media-dashboard-open.sh

pergola-svg-skeleton:
> @python3 tools/pergola-drawings/generate_pergola_svg.py

drawing-engine-demo:
> @python3 tools/drawing-engine/generate_demo_svg.py

feedback-summary-local:
> @./scripts/feedback-summary-local.sh

feedback-sync-status:
> @./scripts/feedback-sync-status.sh

feedback-sync-to-pc2:
> @./scripts/feedback-sync-to-pc2.sh

learning-loop-report-local:
> @./scripts/learning-loop-report-local.sh

improvement-plan-local:
> @./scripts/improvement-plan-local.sh

improvement-patch-plan-local:
> @./scripts/improvement-patch-plan-local.sh

router-prompt-approval-local:
> @./scripts/router-prompt-approval-local.sh

feedback-memory-candidates-local:
> @./scripts/feedback-memory-candidates-local.sh

memory-store-plan-local:
> @./scripts/memory-store-plan-local.sh

memory-store-approved:
> @./scripts/memory-store-approved.sh

memory-store-real-apply-guardrail:
> @./scripts/memory-store-real-apply-guardrail.sh

memory-store-audit-local:
> @./scripts/memory-store-audit-local.sh

memory-store-apply-log-status:
> @./scripts/memory-store-apply-log-status.sh

memory-candidate-approval-helper-local:
> @./scripts/memory-candidate-approval-helper-local.sh

memory-candidate-list-local:
> @./scripts/memory-candidate-list-local.sh

memory-approval-dry-run-e2e-local:
> @./scripts/memory-approval-dry-run-e2e-local.sh

memory-approval-dry-run-e2e-status:
> @./scripts/memory-approval-dry-run-e2e-status.sh

runtime-dashboard-status:
> @./scripts/runtime-dashboard-status.sh

pc1-sleep-prepare:
> @./scripts/runtime/pc1-sleep-prepare.sh

pc1-suspend:
> @./scripts/runtime/pc1-suspend.sh

pc1-startup-coding:
> @./scripts/runtime/pc1-startup-coding.sh

pc1-startup-media-dry:
> @./scripts/runtime/pc1-startup-media-dry.sh

pc1-status:
> @./scripts/runtime/pc1-status.sh

pc2-local-sleep-prepare:
> @./scripts/runtime/pc2-sleep-prepare.sh

pc2-local-suspend:
> @./scripts/runtime/pc2-suspend.sh

pc2-local-startup-workers:
> @./scripts/runtime/pc2-startup-workers.sh

pc2-local-status:
> @./scripts/runtime/pc2-status.sh

cluster-sleep-prepare:
> @./scripts/runtime/cluster-sleep-prepare.sh

cluster-suspend:
> @./scripts/runtime/cluster-suspend.sh

cluster-startup-coding:
> @./scripts/runtime/cluster-startup-coding.sh

cluster-startup-media-dry:
> @./scripts/runtime/cluster-startup-media-dry.sh

cluster-status:
> @./scripts/runtime/cluster-status.sh

pc2-check-connectivity:
> @./scripts/check-pc2-connectivity.sh

pc2-check-layout:
> @./scripts/check-pc2-layout.sh

pc2-sync-code:
> @./scripts/pc2-sync-code.sh

pc2-system-status:
> @./scripts/pc2-system-status.sh

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

pc2-prompt-interpreter-up:
> @./scripts/pc2-prompt-interpreter-up.sh

pc2-prompt-interpreter-down:
> @./scripts/pc2-prompt-interpreter-down.sh

pc2-prompt-interpreter-health:
> @./scripts/pc2-prompt-interpreter-health.sh

pc2-prompt-interpreter-sample:
> @./scripts/pc2-prompt-interpreter-sample.sh

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

test-gateway-media:
> @./scripts/test-gateway-media.sh

test-media-dashboard:
> @./scripts/test-media-dashboard.sh

test-runtime-dashboard:
> @./scripts/test-runtime-dashboard.sh

test-dashboard-ui:
> @./scripts/test-dashboard-ui.sh

test-3d-output-cards-ui:
> @./scripts/test-3d-output-cards-ui.sh

test-3d-reference-board-selection:
> @./scripts/test-3d-reference-board-selection.sh

test-m35-phase-closure:
> @./scripts/test-m35-phase-closure.sh

test-memory-approval-dashboard:
> @./scripts/test-memory-approval-dashboard.sh

test-3d-generator-skeleton:
> @./scripts/test-3d-generator-skeleton.sh

test-3d-parameter-config:
> @./scripts/test-3d-parameter-config.sh

test-3d-dry-run-review:
> @./scripts/test-3d-dry-run-review.sh

test-3d-generation-guards:
> @./scripts/test-3d-generation-guards.sh

test-3d-metadata-sidecar-writer:
> @./scripts/test-3d-metadata-sidecar-writer.sh

test-3d-metadata-sidecar-validator:
> @./scripts/test-3d-metadata-sidecar-validator.sh

test-3d-primitive-builder:
> @./scripts/test-3d-primitive-builder.sh

test-3d-blender-adapter:
> @./scripts/test-3d-blender-adapter.sh

test-3d-first-generation-drill-plan:
> @./scripts/test-3d-first-generation-drill-plan.sh

test-3d-artifact-verifier:
> @./scripts/test-3d-artifact-verifier.sh

test-3d-output-card-api:
> @./scripts/test-3d-output-card-api.sh

test-openai-compatible-gateway:
> @./scripts/test-openai-compatible-gateway.sh

test-gateway-chat-proxy:
> @./scripts/test-gateway-chat-proxy.sh

test-gateway-chat:
> @RUN_GATEWAY_CHAT_TEST=1 ./scripts/test-gateway-api.sh

test-gateway-chat-memory:
> @RUN_GATEWAY_CHAT_MEMORY_TEST=1 ./scripts/test-gateway-api.sh

test-gateway-chat-router:
> @./scripts/test-gateway-chat-router.sh

test-gateway-memory-injection:
> @./scripts/test-gateway-memory-injection.sh

test-gateway-feedback:
> @./scripts/test-gateway-feedback.sh

test-feedback-worker-bridge:
> @./scripts/test-feedback-worker-bridge.sh

test-feedback-sync:
> @./scripts/test-feedback-sync.sh

test-learning-loop-report:
> @./scripts/test-learning-loop-report.sh

test-improvement-plan:
> @./scripts/test-improvement-plan.sh

test-improvement-patch-plan:
> @./scripts/test-improvement-patch-plan.sh

test-router-prompt-approval:
> @./scripts/test-router-prompt-approval.sh

test-feedback-memory-candidates:
> @./scripts/test-feedback-memory-candidates.sh

test-memory-store-workflow:
> @./scripts/test-memory-store-workflow.sh

test-memory-store-audit:
> @./scripts/test-memory-store-audit.sh

test-memory-store-apply-log:
> @./scripts/test-memory-store-apply-log.sh

test-memory-store-real-apply-guardrail:
> @./scripts/test-memory-store-real-apply-guardrail.sh

test-memory-candidate-approval-helper:
> @./scripts/test-memory-candidate-approval-helper.sh

test-memory-approval-dry-run-e2e:
> @./scripts/test-memory-approval-dry-run-e2e.sh

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

test-prompt-interpreter-worker:
> @./scripts/test-prompt-interpreter-worker.sh

test-media-api:
> @./scripts/test-media-api.sh

test-media-image-bridge:
> @./scripts/test-media-image-bridge.sh

test-image-dry-run:
> @./scripts/test-image-dry-run.sh

test-memory:
> @./scripts/test-memory-api.sh

test-embed:
> @./scripts/test-embed-worker.sh

test-bge-m3:
> @./scripts/test-bge-m3-runtime.sh

test-stack:
> @./scripts/test-stack.sh

test: check-layout check-python-syntax

.PHONY: memory-store-manual-preflight
memory-store-manual-preflight:
> ./scripts/memory-store-manual-preflight.sh

.PHONY: test-memory-store-manual-preflight
test-memory-store-manual-preflight:
> ./scripts/test-memory-store-manual-preflight.sh
