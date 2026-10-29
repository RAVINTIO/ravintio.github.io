#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-001: the
# run-mode question.
#
# The orchestrator ends P0 with one run-mode question, word for word. It offers
# only [1] Gated and [2] Autonomous, writes `gated` or `autonomous` to
# plan/.run-mode, and logs the choice in the build log. The retired values
# `continuous` and `interactive` appear in none of the req-001 files in reach.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
ORCH_CONTENT="$(cat "$ORCH")"

QUESTION='How should the agent run P1 to P4?

  [1] Gated: the agent stops for you at the end of each phase
  [2] Autonomous: the agent runs to a raised PR and stops only for escalations'

# The fenced block that follows the run-mode question lead-in.
QBLOCK="$(awk '/^Before asking for confirmation, ask the run-mode question/ {on=1; next}
  on && /^```/ {n++; if (n == 2) exit; next} on && n == 1 {print}' "$ORCH")"

echo ""
echo "=== req-001 (a): the orchestrator asks the run-mode question verbatim ==="

assert_equals "$QUESTION" "$QBLOCK" \
  "req-001 (a): the run-mode question block matches the design text exactly"
assert_equals "2" "$(printf '%s\n' "$QBLOCK" | grep -cE '^ *\[[0-9]+\]')" \
  "req-001 (a): the question offers exactly two options"

echo ""
echo "=== req-001 (a): the answer is written and logged ==="

assert_contains 'write `plan/.run-mode` (`gated` or `autonomous`)' "$ORCH_CONTENT" \
  "req-001 (a): the orchestrator writes gated or autonomous to plan/.run-mode"
assert_contains 'No other value is valid.' "$ORCH_CONTENT" \
  "req-001 (a): the orchestrator rejects any other value"
assert_contains 'Run mode: {gated | autonomous}' "$ORCH_CONTENT" \
  "req-001 (a): the orchestrator logs the choice in the build log"

echo ""
echo "=== req-001 (b): retired run-mode values are gone from the files in reach ==="

IN_REACH=(
  "skills/ravintio-orchestrator/SKILL.md"
  "getting-started.md"
  "workflows/feature-pipeline.md"
  "tests/test-0000023-req-001-continuous-run-p1-p3.sh"
  "tests/test-0000023-req-002-marker-commit-lifecycle.sh"
)
for rel in "${IN_REACH[@]}"; do
  # The 0000023 file name keeps its old id (plan assumption A-004), so a
  # self-reference to it is not a run-mode value.
  hits="$(grep -niE 'continuous|interactive' "$ZERO_DIR/$rel" \
    | grep -v 'test-0000023-req-001-continuous-run-p1-p3' || true)"
  assert_equals "" "$hits" "req-001 (b): $rel names no retired run mode"
done

echo ""
echo "=== req-001 (b): the 0000023 suite asserts the new values ==="

T23="$(cat "$ZERO_DIR/tests/test-0000023-req-001-continuous-run-p1-p3.sh")"
assert_contains 'gated' "$T23" "req-001 (b): test-0000023-req-001 asserts gated"
assert_contains 'autonomous' "$T23" "req-001 (b): test-0000023-req-001 asserts autonomous"

print_summary
