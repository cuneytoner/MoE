# Guarded Blender Animation Implementation Review Template

## Review Metadata

- Date/time:
- Reviewer:
- Git commit:
- Command:

## Adapter Files

- Adapter path present?
- Request schema present?
- Example request present?
- Regression script present?

## Plan Behavior

- Plan-only CLI exits `0`?
- Operation plan type is `blender_animation_operation_plan`?
- Operation ids are deterministic and unique?
- Operation allowlist only?
- Forbidden operations absent?
- Operation ordering correct?

## Validation Reuse

- M36.2 canonical validation reused?
- M36.3 timeline rebuild reused?
- Hash mismatch rejected?
- Timeline mismatch rejected?

## Guard Behavior

- `REAL_ANIMATION_GENERATION=1` exact check verified?
- `--execute-animation` without env exits `2`?
- Env without `--execute-animation` remains plan-only?
- Execution outside Blender returns controlled unavailable report?

## Blender Boundary

- No module-level `bpy` import?
- No `mathutils` import?
- Public execution imports `bpy` only inside the guarded function?
- Fake `bpy` regression covers timeline, transforms, keyframes, and interpolation?

## Runtime Safety

- No preview render?
- No frame/video output?
- No `.blend` save?
- No metadata sidecar write?
- No Gateway, Dashboard, Docker, or reference-board changes?
- No generated animation/video/3D artifact in source?

## Test Results

- `make check-layout`:
- `make check-python-syntax`:
- `bash -n scripts/test-blender-animation-adapter.sh`:
- `make test-blender-animation-adapter`:
- Previous M36 regressions:
- M35 safety regressions:

## Git Safety

- `git diff --check`:
- Binary audit:
- `git status --short`:

## Issues Found

- Issues:
- Blockers:
- Follow-up milestone:
