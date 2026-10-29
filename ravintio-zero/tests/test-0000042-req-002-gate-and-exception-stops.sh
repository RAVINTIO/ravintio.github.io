#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-002: gate and
# exception stops.
#
# A gated run stops at the P1, P2, P3, and P4 gates. An autonomous run stops at
# none of them. P3 puts its acceptance evidence in the PR description, and P4
# raises the PR and ends with "P4 Ship: Complete: PR #{n} ready for your
# review". Both modes stop on four exceptions with a Blocked: message that names
# the action needed. Work is committed and pushed, and the run resumes in the
# same mode. The agent never merges a PR or commits to main.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
VAL="$ZERO_DIR/skills/ravintio-validate-and-accept/SKILL.md"
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"

ORCH_CONTENT="$(cat "$ORCH")"
VAL_CONTENT="$(cat "$VAL")"
SHIP_CONTENT="$(cat "$SHIP")"

# Lines from a heading to the next heading of the same or higher level.
section() {
  awk -v h="$1" '
    $0 == h { on = 1; lvl = index(h, " "); next }
    on && /^#+ / { if (index($0, " ") <= lvl) exit }
    on { print }' "$2"
}
has() { printf '%s\n' "$2" | grep -qF -- "$1" && echo yes || echo no; }

TABLE="$(section '## Phase Invocation (P1 to P4)' "$ORCH")"
STOPS="$(section '## Exception Stops' "$ORCH")"
GATE="$(section '## Acceptance gate' "$VAL")"
SECURITY="$(section '## Security review' "$VAL")"
CI="$(section '## CI process' "$VAL")"
PR_STEP="$(section '### Step 9: PR' "$SHIP")"
FINAL="$(section '### Step 10: Final gate' "$SHIP")"
SHIP_LIMITS="$(section '## Hard Limits' "$SHIP")"

COMPLETE='P4 Ship: Complete: PR #{n} ready for your review'

echo ""
echo "=== req-002 (a): gated stops at each of the P1 to P4 gates ==="

for row in '| P1 Plan |' '| P2 Implement |' '| P3 Validate and Accept |' '| P4 Ship |'; do
  line="$(printf '%s\n' "$TABLE" | grep -F -- "$row")"
  assert_contains "Gated: STOP" "$line" "req-002 (a): orchestrator row $row stops in gated"
done
assert_contains 'In `gated`, this gate stops for the human.' "$GATE" \
  "req-002 (a): validate-and-accept stops at the acceptance gate in gated"
assert_contains 'In `gated`, ask the human' "$PR_STEP" \
  "req-002 (a): ship asks before the PR in gated"
assert_contains 'In `gated`, this gate stops.' "$FINAL" \
  "req-002 (a): ship stops at the final gate in gated"

echo ""
echo "=== req-002 (b): autonomous stops at none of the gates ==="

for row in '| P1 Plan |' '| P2 Implement |' '| P3 Validate and Accept |' '| P4 Ship |'; do
  line="$(printf '%s\n' "$TABLE" | grep -F -- "$row")"
  assert_contains "Autonomous: no stop." "$line" "req-002 (b): orchestrator row $row does not stop in autonomous"
done
assert_contains 'In `autonomous`, do not stop.' "$GATE" \
  "req-002 (b): validate-and-accept does not stop in autonomous"
assert_contains 'PR description' "$GATE" \
  "req-002 (b): validate-and-accept sends acceptance evidence to the PR description"
assert_contains '## Acceptance evidence' "$PR_STEP" \
  "req-002 (b): ship puts the acceptance evidence in the PR body"
assert_contains 'In `autonomous`, take option [1] without asking.' "$PR_STEP" \
  "req-002 (b): ship raises the PR without asking in autonomous"
assert_contains "$COMPLETE" "$FINAL" \
  "req-002 (b): ship ends with the PR-ready message in autonomous"
assert_equals "no" "$(has 'ALWAYS stops' "$VAL_CONTENT")" \
  "req-002 (b): validate-and-accept no longer says the gate always stops"
assert_equals "no" "$(has 'The final gate always stops.' "$SHIP_CONTENT")" \
  "req-002 (b): ship no longer says the final gate always stops"
assert_equals "no" "$(has "without the human's awareness" "$SHIP_CONTENT")" \
  "req-002 (b): ship no longer bars a PR without the human's awareness"
assert_contains 'Merging into `main` stays human-only in every run mode, and the agent never commits to `main`.' "$SHIP_LIMITS" \
  "req-002 (b): ship never merges and never commits to main"
assert_equals "no" "$(has 'SHIP:' "$SHIP_CONTENT")" \
  "req-002 (b): ship uses the P4 Ship: prefix"

echo ""
echo "=== req-002 (c): both modes stop on four exceptions with Blocked: ==="

assert_contains 'Both run modes stop on these exceptions.' "$STOPS" \
  "req-002 (c): the orchestrator lists the exception stops for both modes"
assert_contains 'still fails after 5 attempts' "$STOPS" "req-002 (c): stop on 5 failed attempts"
assert_contains 'schema change' "$STOPS" "req-002 (c): stop on a schema change"
assert_contains 'unmitigated critical or high' "$STOPS" "req-002 (c): stop on an unmitigated critical or high finding"
assert_contains '`gh pr create` fails' "$STOPS" "req-002 (c): stop on a failed push or gh pr create"
assert_equals "4" "$(printf '%s\n' "$STOPS" | grep -cE '^\| .* \| `P[0-4] [A-Za-z]+: Blocked: ')" \
  "req-002 (c): each of the four exceptions has a Blocked: message"
assert_contains 'Commit all work and push it before the stop' "$STOPS" \
  "req-002 (c): work is committed and pushed before the stop"
assert_contains 'the run resumes in the same mode' "$STOPS" \
  "req-002 (c): the run resumes in the same mode"
assert_equals "no" "$(has 'never blocks the pipeline' "$ORCH_CONTENT")" \
  "req-002 (c): a failed push is no longer passed over"

assert_contains 'P3 Validate: Blocked: {check} still fails after 5 attempts' "$CI" \
  "req-002 (c): validate-and-accept escalates 5 failed cycles with Blocked:"
assert_contains 'P3 Validate: Blocked:' "$SECURITY" \
  "req-002 (c): validate-and-accept stops on an unmitigated critical or high finding"
assert_contains 'P4 Ship: Blocked:' "$PR_STEP" \
  "req-002 (c): ship stops on a failed push or gh pr create"

print_summary
