#!/usr/bin/env bash
# Tests for feature 0000032-relocate-setup-config-to-plan-state, req-004
# (refresh-setup-reads-record-first).
#
# ravintio-refresh-setup is a Markdown skill followed by an agent, not
# executable code, so coverage is structural: grep-based assertions over
# SKILL.md, matching the established pattern in
# test-0000020-req-001-010-refresh-setup-skill.sh.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL="$ZERO_DIR/skills/ravintio-refresh-setup/SKILL.md"

assert_equals "yes" "$([ -f "$SKILL" ] && echo yes || echo no)" \
  "req-004: ravintio-refresh-setup/SKILL.md exists"

STEP2=$(sed -n '/^## Step 2/,/^## Step 3/p' "$SKILL")
STEP3=$(sed -n '/^## Step 3/,/^## Step 4/p' "$SKILL")
STEP4=$(sed -n '/^## Step 4/,/^## Step 5/p' "$SKILL")

echo ""
echo "=== req-004: Step 3 reads the record first, at high confidence ==="

assert_contains 'plan/state/{tool}.md' "$STEP3" \
  "req-004: Step 3 names plan/state/{tool}.md as the first source checked"
assert_contains "high" "$STEP3" \
  "req-004: a valid record is reported at high confidence"
assert_contains "is not consulted" "$STEP3" \
  "req-004: the marker is not consulted when the record is valid"

echo ""
echo "=== req-004: record validation rules ==="

assert_contains '```json' "$STEP3" \
  "req-004: validation requires a fenced json block"
assert_contains "tool" "$STEP3" \
  "req-004: validation requires the tool field"
assert_contains "flags" "$STEP3" \
  "req-004: validation requires the flags field"
assert_contains 'all three fields: `tool`, `flags`, `writtenAt`' "$STEP3" \
  "req-004: validation requires exactly the tool, flags and writtenAt fields"
assert_contains "writtenAt" "$STEP3" \
  "req-004: validation requires the writtenAt field"
assert_contains "matches the target" "$STEP3" \
  "req-004: validation requires the tool field to match the target tool"

echo ""
echo "=== req-004: fallback order and no-stop behaviour ==="

assert_contains "marker" "$STEP3" \
  "req-004: fallback names the marker file"
assert_contains "hook" "$STEP3" \
  "req-004: fallback names hook inference"
assert_contains "does not stop the run" "$STEP3" \
  "req-004: a missing or malformed record does not stop the skill run"

echo ""
echo "=== req-004: Step 4 names the source per flag ==="

assert_contains "the record" "$STEP4" \
  "req-004: Step 4 names the record as a possible source"
assert_contains "marker" "$STEP4" \
  "req-004: Step 4 names the marker file as a possible source"
assert_contains "inferred" "$STEP4" \
  "req-004: Step 4 names hook inference as a possible source"

echo ""
echo "=== req-004: Step 2's interrupted-run detection is unchanged ==="

assert_contains 'attemptStatus: "pending"' "$STEP2" \
  "req-004: Step 2 still reads attemptStatus from the marker"

echo ""
echo "=== req-004: the record's values are validated, not just its shape ==="

# 0000196 REQ-003: Step 3 names a retired flag to report and omit it, but the
# allowed set stays --strict-orchestrator alone.
if echo "$STEP3" | grep -- "allowed set" | grep -q -- "--structured-telemetry-mcp"; then
  NAMES_REMOVED_FLAG="yes"
else
  NAMES_REMOVED_FLAG="no"
fi
assert_equals "no" "$NAMES_REMOVED_FLAG" \
  "req-004: the allowed set no longer holds the removed flag --structured-telemetry-mcp"
assert_contains "--strict-orchestrator" "$STEP3" \
  "req-004: Step 3 names the allowed flag --strict-orchestrator"
assert_contains "allowed set" "$STEP3" \
  "req-004: Step 3 constrains flags to an allowed set"
assert_contains "shell metacharacter" "$STEP3" \
  "req-004: Step 3 states why unvalidated values are refused"

print_summary
