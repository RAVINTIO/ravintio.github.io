#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-011: exception
# stop records and redaction.
#
# Every exception stop appends a Blocked: line to the build log, and the human's
# answer adds a Resolved: line. Resume refuses to pass an unresolved stop.
# Acceptance evidence holds results and file:line cites only, and ship scans
# the PR body for credentials. A possible credential is a fifth exception stop.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
VAL="$ZERO_DIR/skills/ravintio-validate-and-accept/SKILL.md"
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
REF="$ZERO_DIR/pipeline-reference.md"
FLOW="$ZERO_DIR/workflows/feature-pipeline.md"

# Lines from a heading to the next heading of the same or higher level.
section() {
  awk -v h="$1" '
    $0 == h { on = 1; lvl = index(h, " "); next }
    on && /^#+ / { if (index($0, " ") <= lvl) exit }
    on { print }' "$2"
}

STOPS="$(section '## Exception Stops' "$ORCH")"
RESUME="$(section '## Resume Detection' "$ORCH")"$'\n'"$(cat "$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-resume-detection.md")"
GATE="$(section '## Acceptance gate' "$VAL")"
PR_STEP="$(section '### Step 9: PR' "$SHIP")"
CRED_MSG='Blocked: possible credential in {path}. Remove it or confirm it is not a secret.'

echo ""
echo "=== req-011 (a): exception stops leave a build-log record ==="

assert_contains 'Append `Blocked: {exception} ({ISO-8601 timestamp})` to the build log' "$STOPS" \
  "req-011 (a): each stop appends a Blocked: line to the build log"
assert_contains 'append `Resolved: {exception} ({ISO-8601 timestamp}, {decision})`' "$STOPS" \
  "req-011 (a): the human's answer appends a Resolved: line"
assert_contains 'with no later `Resolved:` line' "$RESUME" \
  "req-011 (a): resume checks for an unresolved Blocked: line"
assert_contains 'Do not move on in either mode.' "$RESUME" \
  "req-011 (a): resume does not pass an unresolved stop"

echo ""
echo "=== req-011 (b): evidence carries no raw output, and ship scans the PR body ==="

assert_contains 'never raw command output, environment values, or file contents' "$GATE" \
  "req-011 (b): acceptance evidence forbids raw output"
assert_contains '`file:line` cites' "$GATE" \
  "req-011 (b): acceptance evidence uses file:line cites"
assert_contains 'scan the PR body for credential patterns' "$PR_STEP" \
  "req-011 (b): ship scans the PR body before gh pr create"
assert_contains "P4 Ship: $CRED_MSG" "$PR_STEP" \
  "req-011 (b): a match in the PR body is a credential stop"

echo ""
echo "=== req-011 (c): a possible credential is a fifth exception stop ==="

assert_contains "$CRED_MSG" "$STOPS" \
  "req-011 (c): the Exception Stops table has a credential row"
assert_contains 'before the commit and before any push' "$STOPS" \
  "req-011 (c): the credential stop fires before the commit and any push"
assert_equals "6" "$(printf '%s\n' "$STOPS" | grep -cE '^\| .* \| `(\{prefix\}|P[0-4] [A-Za-z]+:) ?Blocked: ')" \
  "req-011 (c): the table has six exception rows (the sixth is the 0000151 dependency stop)"
for f in "$REF" "$FLOW"; do
  assert_contains 'possible credential' "$(cat "$f")" \
    "req-011 (c): $(basename "$f") lists the credential stop"
done

print_summary
