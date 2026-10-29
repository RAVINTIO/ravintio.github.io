#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-010: merge carve-out governance.
#
# The orchestrator rule, ship Hard Limit 5, two override instructions, and the
# initiative standard agree on one narrow carve-out. CLAUDE.md is regenerated from
# the overrides by setup, so this test checks the overrides.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
OVR="$ZERO_DIR/../ravintio-overrides/instructions"
STD="$ZERO_DIR/standards/roadmap-standards.md"
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"

ORULE="$(grep -F '**Merge is human-only.**' "$ORCH")"
SRULE="$(grep -E '^5\. ' "$SHIP")"
C1="$(cat "$OVR/custom-001-local-git-only.md" 2>/dev/null)"
C4="$(cat "$OVR/custom-004-ship-push-and-raise-pr.md" 2>/dev/null)"
SECT="$(awk '$0 == "## Merge carve-out" {on=1; next} on && /^#/ {exit} on {print}' "$STD")"

assert_not_contains() {
  case "$2" in *"$1"*) assert_equals "absent" "present" "$3" ;; *) assert_equals "absent" "absent" "$3" ;; esac
}

PLACES="orchestrator ship custom-001 custom-004 standard"
text_of() {
  case "$1" in
    orchestrator) printf '%s' "$ORULE" ;;
    ship) printf '%s' "$SRULE" ;;
    custom-001) printf '%s' "$C1" ;;
    custom-004) printf '%s' "$C4" ;;
    standard) printf '%s' "$SECT" ;;
  esac
}

echo "=== req-010 (a): carve-out conditions in every place ==="
for p in $PLACES; do
  T="$(text_of "$p")"
  assert_contains 'initiative/*' "$T" "req-010 (a): $p names initiative/*"
  assert_contains '--squash' "$T" "req-010 (a): $p names --squash"
  if [ "$p" = custom-004 ]; then CLEAN='validation finished clean'; else CLEAN='clean P3'; fi
  assert_contains "$CLEAN" "$T" "req-010 (a): $p requires a clean validate phase"
  case "$p" in custom-004) GC='CI is green' ;; *) GC='green CI' ;; esac
  assert_contains "$GC" "$T" "req-010 (a): $p requires green CI"
done
assert_contains 'own feature branch' "$SECT" "req-010 (a): standard limits the merge to the agent's own feature branch"

echo ""
echo "=== req-010 (b): main stays human-only ==="
for p in $PLACES; do
  assert_contains 'human-only' "$(text_of "$p")" "req-010 (b): $p keeps merging into main human-only"
  assert_contains '`main`' "$(text_of "$p")" "req-010 (b): $p names main"
done
assert_contains 'initiative PR' "$SECT" "req-010 (b): standard keeps the initiative PR human-only"
assert_contains 'never commits to `main`' "$SECT" "req-010 (b): standard says the agent never commits to main"

echo ""
echo "=== req-010 (c): merge-guard named, unconditional text gone ==="
for p in $PLACES; do
  assert_contains 'merge-guard' "$(text_of "$p")" "req-010 (c): $p names merge-guard"
done
assert_not_contains 'never merge a pull request' "$ORULE" "req-010 (c): orchestrator rule has no unconditional never-merge"
assert_not_contains 'Never merge the pull request, and' "$C4" "req-010 (c): custom-004 has no unconditional never-merge"
assert_not_contains 'Merging pull requests. The human' "$C1" "req-010 (c): custom-001 has no unconditional merge ban"
for p in orchestrator ship custom-001 custom-004; do
  assert_contains 'standards/roadmap-standards.md' "$(text_of "$p")" "req-010: $p points to the standard"
done

print_summary
