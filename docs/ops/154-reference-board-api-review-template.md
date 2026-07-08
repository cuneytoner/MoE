# Reference Board API Review Template

Use this template when reviewing the reference board API.

## Review

- Date/time:
- Gateway URL:
- List endpoint OK?:
- Create endpoint OK?:
- Read endpoint OK?:
- Duplicate create returns conflict?:
- Unsafe board_id rejected?:
- Runtime JSON created?:
- Source assets untouched?:
- No generation triggered?:
- No arbitrary path accepted?:
- No shell execution?:
- Git safety result:
- Issues found:

## Notes

- Create should write only board JSON under `/home/cuneyt/MoE/runtime/reference-boards`.
- Create should not accept board items yet.
- Board items and dashboard selection remain future work.
