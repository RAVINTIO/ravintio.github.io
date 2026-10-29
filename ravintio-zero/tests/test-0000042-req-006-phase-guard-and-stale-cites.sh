#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-006: phase guard
# and stale cites.
#
# A grep guard fails when skills, docs, templates, hooks, or standards cite a
# phase number outside P0 to P4, say "Phase 0", or use a retired letter prefix.
# History paths are out of scope: plan/_archive/, plan/changelog/,
# plan/current/, plan/backlog/, and ravintio-zero/migrations/_done/.
# The push-and-PR override is renamed from custom-004-p9-... to
# custom-004-ship-..., and no live file names the old file.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Paths the guard reads, relative to a repo root.
SCOPE=(
  ravintio-zero/skills ravintio-zero/templates ravintio-zero/hooks
  ravintio-zero/standards ravintio-zero/workflows ravintio-zero/migrations
  ravintio-zero/schemas ravintio-zero/skills-inbox
  ravintio-zero/getting-started.md ravintio-zero/pipeline-reference.md
  ravintio-zero/project-operations.md
  docs ravintio-overrides plan README.md
)
# History paths the guard skips.
EXCLUDE=(
  plan/_archive plan/changelog plan/current plan/backlog
  ravintio-zero/migrations/_done
)
# P5 to P9, "Phase <n>", or a retired letter prefix (D:, PL:, IM:, VA:, SH:).
PATTERN='\bP[5-9]\b|\bPhase [0-9]\b|(^|[^A-Za-z0-9_])(D|PL|IM|VA|SH):'

# Print each offending file and line under root $1. Exit non-zero on a hit.
phase_guard() {
  local root="$1" paths=() prune=() p
  for p in "${SCOPE[@]}"; do [ -e "$root/$p" ] && paths+=("$p"); done
  for p in "${EXCLUDE[@]}"; do
    [ "${#prune[@]}" -gt 0 ] && prune+=(-o)
    prune+=(-path "$p")
  done
  local hits
  hits="$(cd "$root" && find "${paths[@]}" \( "${prune[@]}" \) -prune -o -type f -print0 \
    | xargs -0 grep -nHE -- "$PATTERN" 2>/dev/null)"
  if [ -n "$hits" ]; then
    printf '%s\n' "$hits"
    return 1
  fi
  return 0
}

echo ""
echo "=== req-006 (a): the live tree has no stale phase cite ==="

OUT="$(phase_guard "$REPO_ROOT")"; RC=$?
[ -n "$OUT" ] && printf '        %s\n' "$OUT"
assert_equals "0" "$RC" "req-006 (a): guard exits 0 on skills, docs, templates, hooks, and standards"

echo ""
echo "=== req-006 (b): planted stale cites fail, history is ignored ==="

WS="$(mktemp -d)"
trap 'rm -rf "$WS"' EXIT
mkdir -p "$WS/ravintio-zero/skills/ravintio-fake" "$WS/plan/_archive/0000001-x" \
  "$WS/plan/changelog" "$WS/plan/current" "$WS/plan/backlog/0000001-x" \
  "$WS/ravintio-zero/migrations/_done" "$WS/docs"
SKILL="$WS/ravintio-zero/skills/ravintio-fake/SKILL.md"
printf '# Fake\n\nThe P2 Implement phase follows P1 Plan.\n' > "$SKILL"
printf 'Archived at P7. PL: Complete, done.\n' > "$WS/plan/_archive/0000001-x/build-log.md"
printf 'P9 push. Phase 0 assess.\n' > "$WS/plan/changelog/0000001-x.md"
printf '### P5: Ship\nSH: Starting\n' > "$WS/plan/current/build-log.md"
printf '**Source phase:** P6\n' > "$WS/plan/backlog/0000001-x/entry.md"
printf 'Applies at P8. VA: Blocked\n' > "$WS/ravintio-zero/migrations/_done/0001-x.md"

OUT="$(phase_guard "$WS")"; RC=$?
assert_equals "0" "$RC" "req-006 (b): guard ignores old numbers in every history path"

printf 'Run P6 before shipping.\n' >> "$SKILL"
OUT="$(phase_guard "$WS")"; RC=$?
assert_equals "1" "$RC" "req-006 (b): a planted P6 in a skill fails the guard"
assert_contains "skills/ravintio-fake/SKILL.md:4:" "$OUT" \
  "req-006 (b): the guard names the file and line of the planted P6"

printf '# Fake\n\nPL: Starting: write the plan\n' > "$SKILL"
OUT="$(phase_guard "$WS")"; RC=$?
assert_equals "1" "$RC" "req-006 (b): a planted PL: prefix in a skill fails the guard"
assert_contains "skills/ravintio-fake/SKILL.md:3:" "$OUT" \
  "req-006 (b): the guard names the file and line of the planted PL:"

printf '# Fake\n\nComplete Phase 0 first.\n' > "$SKILL"
OUT="$(phase_guard "$WS")"; RC=$?
assert_equals "1" "$RC" "req-006 (b): a planted Phase 0 in a skill fails the guard"

printf 'Latency stays under the P95 target.\n' > "$SKILL"
OUT="$(phase_guard "$WS")"; RC=$?
assert_equals "0" "$RC" "req-006 (b): a P95 latency figure is not a phase cite"

echo ""
echo "=== req-006 (c): custom-004 override renamed ==="

INSTR="$REPO_ROOT/ravintio-overrides/instructions"
assert_equals "no" "$([ -e "$INSTR/custom-004-p9-push-and-raise-pr.md" ] && echo yes || echo no)" \
  "req-006 (c): custom-004-p9-push-and-raise-pr.md no longer exists"
assert_equals "yes" "$([ -f "$INSTR/custom-004-ship-push-and-raise-pr.md" ] && echo yes || echo no)" \
  "req-006 (c): custom-004-ship-push-and-raise-pr.md exists"
if [ -f "$INSTR/custom-004-ship-push-and-raise-pr.md" ]; then
  assert_equals "no" "$(grep -Eq '\bP[5-9]\b' "$INSTR/custom-004-ship-push-and-raise-pr.md" && echo yes || echo no)" \
    "req-006 (c): the renamed override cites no phase above P4"
fi

OLD_REFS="$(cd "$REPO_ROOT" && git grep -n 'custom-004-p9' -- . \
  ':!plan/_archive' ':!plan/changelog' ':!plan/current' ':!plan/backlog' \
  ':!ravintio-zero/migrations/_done' \
  ':!ravintio-zero/tests/test-0000042-req-006-phase-guard-and-stale-cites.sh' 2>/dev/null)"
assert_equals "" "$OLD_REFS" "req-006 (c): no live file names custom-004-p9"

print_summary
