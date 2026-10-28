#!/usr/bin/env bash
# Tests for feature 0000151-hardening-efficiency-and-ci, req-002: ship
# clears the sentinels in a commit before it pushes.
#
# The ship order is Step 7 tag, Step 8 clear sentinels, Step 9 PR, Step 10
# final gate. The I-D Advance stage names the clear step by its new number.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"

# Lines from a heading to the next heading of the same or higher level.
section() {
  awk -v h="$1" '
    $0 == h { on = 1; lvl = index(h, " "); next }
    on && /^#+ / { if (index($0, " ") <= lvl) exit }
    on { print }' "$2"
}
has() { printf '%s\n' "$2" | grep -qF -- "$1" && echo yes || echo no; }
line() { grep -n -F -- "$1" "$2" | head -1 | cut -d: -f1; }

echo ""
echo "=== req-002 (a): step order and text ==="

l7="$(line '### Step 7: Release tag' "$SHIP")"
l8="$(line '### Step 8: Clear sentinels' "$SHIP")"
l9="$(line '### Step 9: PR' "$SHIP")"
l10="$(line '### Step 10: Final gate' "$SHIP")"
ordered=no
[ -n "$l7" ] && [ -n "$l8" ] && [ -n "$l9" ] && [ -n "$l10" ] \
  && [ "$l7" -lt "$l8" ] && [ "$l8" -lt "$l9" ] && [ "$l9" -lt "$l10" ] && ordered=yes
assert_equals "yes" "$ordered" "req-002 (a): headings rise Step 7, 8, 9, 10"
assert_equals "10" "$(grep -c '^### Step ' "$SHIP")" \
  "req-002 (a): ten step headings, none renumbered below Step 7"

S7="$(section '### Step 7: Release tag' "$SHIP")"
S8="$(section '### Step 8: Clear sentinels' "$SHIP")"
S9="$(section '### Step 9: PR' "$SHIP")"
S10="$(section '### Step 10: Final gate' "$SHIP")"

assert_equals "yes" "$(has 'option [1]' "$S9")" "req-002 (a): Step 9 covers option [1]"
assert_equals "no" "$(has 'git push origin v{version}' "$(printf '%s\n' "$S9" | sed -n '/option \[1\], push/,/^```$/p')")" "req-002 (a): Step 9 option [1] pushes no tag (0000169 req-006)"
assert_equals "yes" "$(has 'Create no tag.' "$S7")" "req-002 (a): Step 7 creates no tag (0000169 req-006)"
assert_equals "yes" "$(has 'plan/.orchestrator-active' "$S8")" "req-002 (a): Step 8 names the active sentinel"
assert_equals "yes" "$(has 'plan/.orchestrator-ack' "$S8")" "req-002 (a): Step 8 names the ack sentinel"
assert_equals "yes" "$(has 'plan/.run-mode' "$S8")" "req-002 (a): Step 8 names the run-mode sentinel"
assert_equals "yes" "$(has 'git ls-files' "$S8")" "req-002 (a): Step 8 checks git ls-files"
assert_equals "yes" "$(has 'Step 8 deletes' "$S10")" "req-002 (a): Step 10 cites Step 8 for the deletion"
assert_equals "yes" "$(has 'Read `plan/.run-mode` before Step 8' "$(cat "$SHIP")")" "req-002 (a): hard limit reads the mode before Step 8"

RD="$(section '### I-D Advance' "$STD")"
r_clear="$(printf '%s\n' "$RD" | grep -n 'Step 8' | head -1 | cut -d: -f1)"
r_pr="$(printf '%s\n' "$RD" | grep -n 'gh pr create' | head -1 | cut -d: -f1)"
rd_ok=no
[ -n "$r_clear" ] && [ -n "$r_pr" ] && [ "$r_clear" -lt "$r_pr" ] && rd_ok=yes
assert_equals "yes" "$rd_ok" "req-002 (a): I-D Advance names Step 8 before gh pr create"
assert_equals "no" "$(has 'Step 9' "$RD")" "req-002 (a): I-D Advance no longer cites Step 9"

echo ""
echo "=== req-002 (b): scripted Step 8 run ==="

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git init -q --bare "$TMP/remote.git"
git init -q -b feat/x "$TMP/repo"
cd "$TMP/repo" || exit 1
git config user.email t@example.com
git config user.name t
git remote add origin "$TMP/remote.git"
mkdir plan
echo f > plan/.orchestrator-active
echo a > plan/.orchestrator-ack
echo gated > plan/.run-mode
git add -A && git commit -q -m seed
before="$(git rev-list --count HEAD)"
mode="$(cat plan/.run-mode)"
rm -f plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode
git add -A plan && git commit -q -m "clear sentinels"
tracked="$(git ls-files plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode)"
git push -q origin feat/x
after="$(git rev-list --count HEAD)"
remote_files="$(git --git-dir="$TMP/remote.git" ls-tree -r --name-only feat/x)"
assert_equals "" "$tracked" "req-002 (b): no sentinel stays tracked"
assert_equals "1" "$((after - before))" "req-002 (b): one commit lands before the push"
assert_equals "" "$remote_files" "req-002 (b): the pushed branch holds no sentinel"
assert_equals "gated" "$mode" "req-002 (b): the run mode was read before the deletion"
cd "$SCRIPT_DIR" || exit 1

print_summary
