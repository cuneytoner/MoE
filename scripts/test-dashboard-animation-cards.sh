#!/usr/bin/env bash
set -euo pipefail

COMPONENT="apps/dashboard-ui/src/components/AnimationOutputCards.tsx"
APP="apps/dashboard-ui/src/App.tsx"
API="apps/dashboard-ui/src/api.ts"
TYPES="apps/dashboard-ui/src/types.ts"
SIDEBAR="apps/dashboard-ui/src/components/Sidebar.tsx"
MILESTONES="docs/milestones.md"
CODEX_PROMPTS="docs/codex-prompts.md"
README="README.md"
ARCHITECTURE="docs/architecture.md"
DOC="docs/ops/307-dashboard-animation-cards-ui.md"
TEMPLATE="docs/ops/308-dashboard-animation-cards-ui-review-template.md"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

for path in \
  "$COMPONENT" \
  "$APP" \
  "$API" \
  "$TYPES" \
  "$SIDEBAR" \
  "$DOC" \
  "$TEMPLATE"; do
  [ -f "$path" ] || fail "missing expected file: $path"
done

grep -q 'id="animation-output-cards"' "$COMPONENT"
grep -q 'Animation Output Cards' "$COMPONENT"
grep -q 'Read-only view of validated animation metadata and verified sampled PNG previews.' "$COMPONENT"
grep -q 'type Props = {' "$COMPONENT"
grep -q 'cardsResponse: AnimationOutputCardsResponse | null;' "$COMPONENT"
grep -q 'error: string;' "$COMPONENT"
grep -q 'loading: boolean;' "$COMPONENT"
grep -q 'const MAX_VISIBLE_CARDS = 12;' "$COMPONENT"
grep -q 'const VISIBLE_CHIP_LIMIT = 6;' "$COMPONENT"

grep -q 'export type AnimationOutputCard' "$TYPES"
grep -q 'export type AnimationOutputCardsResponse' "$TYPES"
grep -q 'type: "animation";' "$TYPES"
grep -q 'metadata_dir_available: boolean;' "$TYPES"
grep -q 'reports_dir_available: boolean;' "$TYPES"
grep -q 'preview_report_count: number;' "$TYPES"
grep -q 'verified_preview_count: number;' "$TYPES"
grep -q 'animation_execution_attempted: boolean;' "$TYPES"
grep -q 'preview_render_attempted: boolean;' "$TYPES"

grep -q 'fetchAnimationOutputCards' "$API"
grep -q '/gateway/media/animation/cards' "$API"
if grep -n '/gateway/media/animation/cards' "$API" | grep -E 'POST|PATCH|DELETE|PUT' >/dev/null; then
  fail "animation card API client must remain GET-only"
fi

grep -q 'fetchAnimationOutputCards' "$APP"
grep -q 'AnimationOutputCardsResponse | null' "$APP"
grep -q 'animationOutputCardsError' "$APP"
grep -q 'setAnimationOutputCards(null)' "$APP"
grep -q '<AnimationOutputCards' "$APP"
grep -q 'cardsResponse={animationOutputCards}' "$APP"
grep -q 'error={animationOutputCardsError}' "$APP"
grep -q 'activeBoardId={activeReferenceBoardId}' "$APP"
grep -q 'addingCardId={addingAnimationBoardCardId}' "$APP"
grep -q 'onAddToBoard=' "$APP"
grep -q 'handleAddAnimationCardToBoard(card)' "$APP"
grep -q 'href: "#animation-output-cards"' "$SIDEBAR"
grep -q 'label: "Animation"' "$SIDEBAR"

grep -q 'Animation output cards unavailable:' "$COMPONENT"
grep -q 'Loading animation output cards.' "$COMPONENT"
grep -q 'Animation metadata directory is not available yet.' "$COMPONENT"
grep -q 'Animation preview reports are not available yet. Metadata cards remain read-only and usable.' "$COMPONENT"
grep -q 'No validated animation output metadata reported yet.' "$COMPONENT"
grep -q 'invalid animation metadata sidecar(s) were skipped.' "$COMPONENT"
grep -q 'warnings.slice(0, 5)' "$COMPONENT"
grep -q 'Showing {visibleCards.length} of {cards.length} cards' "$COMPONENT"

grep -q 'metadata available' "$COMPONENT"
grep -q 'reports available' "$COMPONENT"
grep -q 'preview reports' "$COMPONENT"
grep -q 'verified previews' "$COMPONENT"
grep -q 'visual reference only' "$COMPONENT"
grep -q 'not structurally certified' "$COMPONENT"
grep -q 'operator review required' "$COMPONENT"
grep -q 'metadata verified' "$COMPONENT"
grep -q 'metadata warning' "$COMPONENT"
grep -q 'preview verified' "$COMPONENT"
grep -q 'no verified preview' "$COMPONENT"

grep -q 'Timeline' "$COMPONENT"
grep -q 'FPS' "$COMPONENT"
grep -q 'Frames' "$COMPONENT"
grep -q 'total frames' "$COMPONENT"
grep -q 'seconds' "$COMPONENT"
grep -q 'Summary' "$COMPONENT"
grep -q 'Tracks' "$COMPONENT"
grep -q 'Keyframes' "$COMPONENT"
grep -q 'Segments' "$COMPONENT"
grep -q 'Operations' "$COMPONENT"
grep -q 'target types' "$COMPONENT"
grep -q 'target ids' "$COMPONENT"
grep -q 'properties' "$COMPONENT"
grep -q 'interpolations' "$COMPONENT"
grep -q 'none reported' "$COMPONENT"
grep -q '+${remainingCount} more' "$COMPONENT"

grep -q 'Verified sampled PNG preview' "$COMPONENT"
grep -q 'No verified sampled-frame preview' "$COMPONENT"
grep -q 'first frame:' "$COMPONENT"
grep -q 'Runtime paths' "$COMPONENT"
grep -q 'declared only' "$COMPONENT"
grep -q 'not reported' "$COMPONENT"
grep -q 'Verification' "$COMPONENT"
grep -q 'Metadata valid' "$COMPONENT"
grep -q 'Provenance not checked' "$COMPONENT"
grep -q 'Preview report valid' "$COMPONENT"
grep -q 'Runtime preview verified' "$COMPONENT"
grep -q 'Unsafe animation card API flags detected. Do not treat these cards as read-only.' "$COMPONENT"
grep -q 'formatCreatedAt' "$COMPONENT"
grep -q 'invalid date' "$COMPONENT"
grep -q 'overflowWrap: "anywhere"' "$COMPONENT"

if grep -q '<img' "$COMPONENT"; then
  fail "animation cards must not load sampled PNG frames as image elements"
fi
if grep -R 'FileResponse\|base64\|file://' apps/dashboard-ui/src/components/AnimationOutputCards.tsx apps/dashboard-ui/src/api.ts >/dev/null; then
  fail "animation cards introduced binary serving or file URL behavior"
fi
if grep -R 'relative_runtime_paths.*fetch\|declared_video_preview.*fetch\|first_frame_relative_path.*fetch' "$COMPONENT" "$API" >/dev/null; then
  fail "animation cards must not build URLs from runtime paths"
fi
if grep -R 'execute-animation\|render-preview\|REAL_ANIMATION_GENERATION\|subprocess\|shell_execution: true' apps/dashboard-ui/src >/dev/null; then
  fail "dashboard animation cards introduced execution language"
fi

grep -q 'M36.15 Dashboard Animation Cards UI DONE' "$MILESTONES"
grep -q 'M36.16 Animation Reference Board Selection DONE' "$MILESTONES"
grep -q 'M36.17 M36 Phase Closure PLANNED' "$MILESTONES"
grep -q 'Latest completed: M36.16 Animation Reference Board Selection.' "$MILESTONES"
grep -q 'Next planned: M36.17 M36 Phase Closure.' "$MILESTONES"
grep -q 'M36.15 Dashboard Animation Cards UI DONE' "$CODEX_PROMPTS"
grep -q 'M36.16 Animation Reference Board Selection DONE' "$CODEX_PROMPTS"
grep -q 'M36.17 M36 Phase Closure PLANNED' "$CODEX_PROMPTS"
grep -q 'Completed through Milestone 36.16: Animation Reference Board Selection' "$README"
grep -q 'M36.15 adds read-only Dashboard animation cards' "$ARCHITECTURE"

if grep -q 'M37.0 .* DONE\|M38.0 .* DONE' "$MILESTONES" "$CODEX_PROMPTS"; then
  fail "future M37/M38 milestones must not be marked done"
fi

if find . -type d \( -name node_modules -o -name dist -o -name build -o -name .cache -o -name __pycache__ \) -print -quit | grep -q .; then
  fail "source-only audit found generated/cache directory in repo"
fi
if find . -type f \( -name '*.mp4' -o -name '*.webm' -o -name '*.mov' -o -name '*.gif' -o -name 'frame-*.png' \) -print -quit | grep -q .; then
  fail "animation binary artifact found in source tree"
fi

echo "PASS: dashboard animation cards UI source checks"
