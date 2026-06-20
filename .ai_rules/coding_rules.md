# Local AI Architecture - Coding Guardrails

## 1. Python & Bash Best Practices
- **Python**: Use explicit type hinting, robust `try-except` blocks, and native logging wrappers. Never hardcode hardware parameters or IP vectors.
- **Bash**: Every script must initiate with `set -e` (fail fast) unless explicit error absorption is architecturally required.

## 2. Dynamic Architecture Enforcement
- All communication scripts targeting remote nodes must evaluate connection boundaries utilizing parameters parsed directly from the centralized configuration manifest (`.env`).
- Never introduce dependencies requiring high VRAM overhead on secondary execution tiers (e.g., PC-2 worker node).
