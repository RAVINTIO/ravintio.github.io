#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-008: roadmap delivery.
#
# After the last step, I-E Delivery archives plan/current-initiative/ and raises
# one initiative PR to main that asks for a merge commit. The agent never merges
# it and never commits to main.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
REF="$ZERO_DIR/pipeline-reference.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"

section() { awk -v h="$1" '$0 == h {on=1; next} on && /^##? / {exit} on {print}' "$2"; }

SEC="$(section '## Ship stages' "$STD")"
DEL="$(printf '%s\n' "$SEC" | awk '/^### I-E Delivery/ {on=1; next} on && /^### / {exit} on {print}')"

echo ""
echo "=== req-008 (a): archive the initiative folder, status delivered ==="
assert_contains 'I-E Delivery:' "$DEL" "req-008 (a): uses the I-E Delivery prefix"
assert_contains 'last step' "$DEL" "req-008 (a): runs after the last step"
assert_contains 'plan/current-initiative/' "$DEL" "req-008 (a): names the source folder"
assert_contains 'plan/_archive/{id}-{slug}-initiative-{date}/' "$DEL" "req-008 (a): names the archive path"
assert_contains '`status: delivered`' "$DEL" "req-008 (a): sets status delivered"
assert_contains 'initiative branch' "$DEL" "req-008 (a): commits on the initiative branch"

echo ""
echo "=== req-008 (b): one PR to main asking for a merge commit ==="
assert_contains 'gh pr create --base main' "$DEL" "req-008 (b): PR targets main"
assert_contains '--head initiative/{id}-{slug}' "$DEL" "req-008 (b): PR comes from the initiative branch"
assert_contains 'merge commit' "$DEL" "req-008 (b): body asks for a merge commit"
assert_contains 'not a squash' "$DEL" "req-008 (b): body says not a squash"
assert_contains 'version and tag' "$DEL" "req-008 (b): body lists each step with version and tag"

echo ""
echo "=== req-008 (c): never merge the initiative PR, never commit to main ==="
assert_contains 'never merges the initiative PR' "$DEL" "req-008 (c): never merges the initiative PR"
assert_contains 'never commits to `main`' "$DEL" "req-008 (c): never commits to main"
assert_contains 'merge-guard' "$SEC" "req-008 (c): section points at merge-guard for the merge carve-out"

echo ""
echo "=== req-008: pipeline reference records delivery ==="
SHIPREF="$(section '## Ship Phase' "$REF")"
assert_contains 'merge commit' "$SHIPREF" "req-008: pipeline reference asks for a merge commit"

print_summary
