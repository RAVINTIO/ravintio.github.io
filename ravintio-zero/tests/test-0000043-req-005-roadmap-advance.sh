#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-005: roadmap advance.
#
# The ship skill has a "Initiative steps" section for I-D Advance. It applies
# when plan/current-initiative/initiative.md has status active. A normal run keeps
# the tag-before-PR order and the no-merge rule.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
REF="$ZERO_DIR/pipeline-reference.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"

# The section from a heading to the next heading of the same or higher level.
section() { awk -v h="$1" '$0 == h {on=1; next} on && /^##? / {exit} on {print}' "$2"; }

ALL="$(cat "$SHIP")"
SEC="$(section '## Ship stages' "$STD")"
ADV="$(printf '%s\n' "$SEC" | awk '/^### I-D Advance/ {on=1; next} on && /^### / {exit} on {print}')"

echo ""
echo "=== req-005 (a): initiative-step PR command and initiative.md update ==="
assert_contains 'plan/current-initiative/initiative.md' "$SEC" "req-005 (a): section names the initiative file"
assert_contains '`status: active`' "$SEC" "req-005 (a): section applies on status active"
assert_contains 'I-D Advance:' "$SEC" "req-005 (a): section uses the I-D Advance prefix"
assert_contains '--base initiative/{id}-{slug}' "$ADV" "req-005 (a): PR targets the initiative branch"
assert_contains '`merged`' "$ADV" "req-005 (a): same PR sets the step to merged"
assert_contains 'Version' "$ADV" "req-005 (a): same PR fills Version"
assert_contains '`position`' "$ADV" "req-005 (a): same PR moves position"
assert_contains 'same PR' "$ADV" "req-005 (a): initiative update rides in the same PR"

echo ""
echo "=== req-005 (b): green CI, squash merge, fetch, tag, push tag ==="
assert_contains 'gh pr checks' "$ADV" "req-005 (b): waits with gh pr checks"
assert_contains 'gh pr merge --squash' "$ADV" "req-005 (b): squash merges"
assert_contains 'Blocked:' "$ADV" "req-005 (b): red or pending CI is a Blocked stop"
assert_contains 'pending' "$ADV" "req-005 (b): pending CI is named"
assert_contains '--json mergeCommit -q .mergeCommit.oid' "$ADV" "req-005 (b): reads the PR merge commit"
assert_contains 'git fetch' "$ADV" "req-005 (b): fetches after the merge"
assert_contains 'git tag v{version}' "$ADV" "req-005 (b): tags the squash commit"
assert_contains 'git push origin v{version}' "$ADV" "req-005 (b): pushes the tag"
order="$(printf '%s\n' "$ADV" | grep -nE 'gh pr checks|gh pr merge --squash|git fetch|git tag v|git push origin v' | cut -d: -f1 | tr '\n' ' ')"
sorted="$(printf '%s\n' $order | sort -n | tr '\n' ' ')"
assert_equals "$sorted" "$order" "req-005 (b): checks, merge, fetch, tag, push appear in order"

echo ""
echo "=== req-005 (c): normal run creates no tag and keeps no merge ==="
assert_contains 'Create no tag.' "$ALL" "req-005 (c): Step 7 creates no tag (0000169 req-006)"
assert_contains 'tags the squash commit' "$ALL" "req-005 (c): Step 7 leaves initiative tagging to I-D Advance"
assert_contains 'Merging into `main` stays human-only in every run mode' "$ALL" "req-005 (c): Hard Limit 5 keeps main human-only"
assert_contains 'Outside an initiative' "$SEC" "req-005 (c): section says a normal run is unchanged"
s7="$(grep -n '^### Step 7' "$SHIP" | cut -d: -f1)"
s8="$(grep -n '^### Step 9' "$SHIP" | cut -d: -f1)"
rs="$(grep -n '^## Initiative steps' "$SHIP" | cut -d: -f1)"
assert_equals "yes" "$([ -n "$s7" ] && [ -n "$s8" ] && [ "$s7" -lt "$s8" ] && echo yes || echo no)" "req-005 (c): Step 7 precedes Step 9 PR"
assert_equals "yes" "$([ -n "$rs" ] && [ -n "$s8" ] && [ "$rs" -gt "$s8" ] && echo yes || echo no)" "req-005 (c): initiative section sits after the normal steps"

echo ""
echo "=== req-005 (d): CI wait polls, then watches ==="
assert_contains 'at least one check is listed' "$ADV" "req-005 (d): polls until a check is listed"
assert_contains '2 minutes' "$ADV" "req-005 (d): poll limit is 2 minutes"
assert_contains 'no CI ran on PR #{n}' "$ADV" "req-005 (d): no-CI stop line"
assert_contains "pull requests to \`initiative/**\`" "$SEC" "req-005 (d): CI must trigger on PRs to initiative/**"
assert_contains 'gh pr checks {n} --watch --fail-fast' "$ADV" "req-005 (d): watches with fail-fast"
assert_contains 'longest Bash timeout' "$ADV" "req-005 (d): Claude session uses the longest Bash timeout"
assert_contains 'background task' "$ADV" "req-005 (d): background task for CI over 10 minutes"
assert_contains 'Blocked: CI failed on PR #{n}' "$ADV" "req-005 (d): Blocked only on a failed check"
assert_equals "0" "$(printf '%s\n' "$ADV" | grep -c 'CI is {red|pending}')" "req-005 (d): pending is no longer a stop"

echo ""
echo "=== req-005 (e): Step 8 runs and is pushed before the PR ==="
assert_contains 'Step 8' "$SEC" "req-005 (e): section names Step 8"
assert_contains '.run-mode' "$SEC" "req-005 (e): section names the sentinels"
assert_contains 'before the PR is raised' "$SEC" "req-005 (e): Step 8 precedes the PR"
assert_contains 'stale feature id' "$SEC" "req-005 (e): states the stale id risk"
step9="$(printf '%s\n' "$ADV" | grep -n 'Step 8' | head -1 | cut -d: -f1)"
pr="$(printf '%s\n' "$ADV" | grep -n 'gh pr create' | head -1 | cut -d: -f1)"
assert_equals "yes" "$([ -n "$step9" ] && [ -n "$pr" ] && [ "$step9" -lt "$pr" ] && echo yes || echo no)" "req-005 (e): Step 8 appears before gh pr create in I-D Advance"

echo ""
echo "=== req-005 (f): hand-off after the tag push ==="
assert_contains 'git pull --ff-only origin initiative/{id}-{slug}' "$ADV" "req-005 (f): fast-forwards the initiative branch"
assert_contains 'git branch -D' "$ADV" "req-005 (f): deletes the local feature branch"
assert_contains 'gh pr merge --squash --delete-branch {n}' "$ADV" "req-005 (f): the merge deletes the remote feature branch"
assert_contains 'If the local feature branch still exists' "$ADV" "req-005 (f): local delete tolerates a branch gh already removed"
assert_contains 'I-D Advance: Complete:' "$ADV" "req-005 (f): ends with a Complete line"
assert_contains 'step {next} of {n} next' "$ADV" "req-005 (f): Complete line names the next step"
assert_contains 'one past the last step number' "$SEC" "req-005 (f): defines position after the last step"
assert_contains 'driver then prints `I-E Delivery: Pending:`' "$ADV" "req-005 (f): last step ends and the driver reports delivery pending"
push_ln="$(printf '%s\n' "$ADV" | grep -n 'git push origin v' | head -1 | cut -d: -f1)"
pull_ln="$(printf '%s\n' "$ADV" | grep -n 'git pull --ff-only' | head -1 | cut -d: -f1)"
assert_equals "yes" "$([ -n "$push_ln" ] && [ -n "$pull_ln" ] && [ "$push_ln" -lt "$pull_ln" ] && echo yes || echo no)" "req-005 (f): pull follows the tag push"

echo ""
echo "=== req-005: pipeline reference records both tag orders ==="
SHIPREF="$(section '## Ship Phase' "$REF")"
assert_contains 'initiative' "$SHIPREF" "req-005: pipeline reference Ship Phase mentions initiative steps"
assert_contains 'squash' "$SHIPREF" "req-005: pipeline reference notes the squash-then-tag order"

print_summary
