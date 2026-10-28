#!/usr/bin/env bash
# Tests for feature 0000025, req-002: the ship phase's archive commit stages
# everything explicitly, so it never silently depends on git's
# rename-detection heuristic and never leaves untracked artifacts behind.
# The rule now lives in ravintio-ship/SKILL.md's archive step.
#
# ravintio-ship/SKILL.md is a prose skill file, not executable code, so
# these are content-assertion tests against the SKILL.md text.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SHIP_SKILL="$ZERO_DIR/skills/ravintio-ship/SKILL.md"

# Isolate the archive step (from its heading to the next "### " heading).
ARCHIVE_STEP=$(sed -n '/^### Step 4: Archive/,/^### Step 5/p' "$SHIP_SKILL")

echo ""
echo "=== req-002: the archive step stages everything explicitly ==="

assert_equals "yes" "$([ -n "$ARCHIVE_STEP" ] && echo yes || echo no)" \
  "req-002: ravintio-ship documents an archive step"
assert_contains 'git add` everything: the archive, the deletions, and the link updates' \
  "$ARCHIVE_STEP" "req-002: git add covers the archive, the deletions, and the link updates"

echo ""
echo "=== req-002: untracked artifacts are never left behind ==="

assert_contains "Untracked artifacts must not be left behind" "$ARCHIVE_STEP" \
  "req-002: untracked artifacts are staged with the archive commit"
assert_contains "git status --porcelain" "$ARCHIVE_STEP" \
  "req-002: a git status --porcelain check runs before committing"

echo ""
echo "=== req-002: archive mechanics are copy-then-delete ==="

assert_contains 'Copy all of `plan/current/` to the archive path, then delete' "$ARCHIVE_STEP" \
  "req-002: the archive copies plan/current/ before deleting its contents"
assert_contains "Never use an atomic move" "$ARCHIVE_STEP" \
  "req-002: an atomic move is forbidden"

print_summary
