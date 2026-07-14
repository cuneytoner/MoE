# Reference Board Malformed Store Regression Review Template

Use this template after running `make reference-board-malformed-store-regression`.

## Review

- Date/time:
- Gateway API URL:
- Board id:
- Runtime dir:
- Malformed file path:
- Gateway rebuilt before test?
- List endpoint status:
- List endpoint avoided HTTP 500?
- List endpoint avoided traceback?
- Read endpoint returned controlled JSON error?
- Export JSON endpoint returned controlled JSON error?
- Download Markdown endpoint returned controlled JSON error?
- Error responses avoided host paths?
- Temporary malformed file removed?
- No runtime export files created?
- Git safety result:
- Issues found:
- Questions/blockers:

## Commands Used

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose -f infra/docker/docker-compose.yml up -d --build gateway-api
make reference-board-malformed-store-regression
git status --short
```
