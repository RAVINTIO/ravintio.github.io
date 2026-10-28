#!/usr/bin/env bash
# Tests for feature 0000037-self-host-on-planifest-zero, req-005: override
# phase names.
#
# The push-and-PR override must name the ship phase, not a phase number from
# the old nine-phase pipeline. Its rules must stay as they are. The override
# lives in this repo only, so the suite skips when the file is absent.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO_ROOT="$ZERO_DIR/.."
OVERRIDE="$REPO_ROOT/ravintio-overrides/instructions/custom-004-ship-push-and-raise-pr.md"
SHIP_SKILL="$ZERO_DIR/skills/ravintio-ship/SKILL.md"

if [ ! -f "$OVERRIDE" ]; then
  echo "SKIP: req-005: override file not found at $OVERRIDE"
  exit 0
fi

BODY="$(cat "$OVERRIDE")"

echo ""
echo "=== req-005 (a): the override names the ship phase ==="

assert_contains "the ship phase" "$BODY" \
  "req-005 (a): the override names the ship phase"

echo ""
echo "=== req-005 (b): no old phase numbers remain ==="

assert_equals "no" "$(grep -q 'P9' "$OVERRIDE" && echo yes || echo no)" \
  "req-005 (b): the override body contains no P9"
assert_equals "no" "$(grep -Eq '\bP[0-9]\b' "$OVERRIDE" && echo yes || echo no)" \
  "req-005 (b): the override body contains no phase number"

echo ""
echo "=== req-005 (c): the rules stay as they are ==="

assert_contains "gh pr create" "$BODY" \
  "req-005 (c): the override still runs gh pr create"
assert_contains "option [1]" "$BODY" \
  "req-005 (c): the override still takes option [1]"
assert_contains "Never merge the pull request" "$BODY" \
  "req-005 (c): the override still says never to merge"
assert_contains "CI tags the merge commit" "$BODY" \
  "req-005 (c): the override says CI tags the release (0000169 req-006)"
assert_contains "report the exact error and stop" "$BODY" \
  "req-005 (c): the override still stops on a failed push"

echo ""
echo "=== req-005 (d): option [1] still matches the ship skill ==="

assert_contains "[1] Agent pushes + creates PR" "$(cat "$SHIP_SKILL")" \
  "req-005 (d): ship skill option [1] is still the push and PR choice"

print_summary
