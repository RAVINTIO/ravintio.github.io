#!/usr/bin/env bash
# Tests for feature 0000025, req-003: subagent parallelism expansion.
#
# Confirms:
#   1. agent-dispatch-standards.md's MUST-parallelise table has rows for
#      (a) independent new-test-file authoring closing a coverage gap and
#      (b) independent living-doc edits with no shared content.
#   2. The validate-and-accept phase skill keeps its own parallelism
#      guidance (batching and hard sequencing) per the phase-skill
#      parallelism convention.
#   3. None of the pre-existing MUST/Cannot-parallelise rows were removed.
#
# Checks the canonical tracked skill source (ravintio-zero/skills/),
# not the gitignored .claude/skills/ runtime sync copy.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

STANDARDS="$ZERO_DIR/standards/agent-dispatch-standards.md"
VALIDATE_SKILL="$ZERO_DIR/skills/ravintio-validate-and-accept/SKILL.md"

grep_has() { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }

echo ""
echo "=== req-003: agent-dispatch-standards.md gains new-test-file pattern ==="

assert_equals "yes" "$(grep_has 'Independent new test files closing a coverage gap' "$STANDARDS")" \
  "req-003: MUST-parallelise table names independent new-test-file authoring"
assert_equals "yes" "$(grep_has 'non-cross-referencing sections' "$STANDARDS")" \
  "req-003: new-test-file row cites the independent, non-cross-referencing pattern"

echo ""
echo "=== req-003: agent-dispatch-standards.md gains living-doc-edit pattern ==="

assert_equals "yes" "$(grep_has 'Independent living-doc edits' "$STANDARDS")" \
  "req-003: MUST-parallelise table names independent living-doc edits"
assert_equals "yes" "$(grep_has 'no shared content' "$STANDARDS")" \
  "req-003: living-doc row cites the no-shared-content pattern"

echo ""
echo "=== req-003: agent-dispatch-standards.md retains existing MUST/Cannot rows ==="

assert_equals "yes" "$(grep_has 'Multiple independent codebase searches' "$STANDARDS")" \
  "req-003: pre-existing MUST-parallelise row (codebase searches) still present"
assert_equals "yes" "$(grep_has 'Independent requirement files (no cross-references)' "$STANDARDS")" \
  "req-003: pre-existing MUST-parallelise row (requirement files) still present"
assert_equals "yes" "$(grep_has 'Phase N work before Phase N-1 artifacts exist' "$STANDARDS")" \
  "req-003: pre-existing Cannot-parallelise row (phase sequencing) still present"
assert_equals "yes" "$(grep_has 'ADR writing before requirements are complete' "$STANDARDS")" \
  "req-003: pre-existing Cannot-parallelise row (ADR sequencing) still present"

echo ""
echo "=== req-003: validate-and-accept keeps its own parallelism guidance ==="

assert_equals "yes" "$(grep_has '## Parallelism' "$VALIDATE_SKILL")" \
  "req-003: validate-and-accept has a Parallelism section"
assert_equals "yes" "$(grep_has 'Batch 1 (parallel): lint + typecheck' "$VALIDATE_SKILL")" \
  "req-003: lint and typecheck run as a parallel batch"
assert_equals "yes" "$(grep_has 'library audit + semantic check' "$VALIDATE_SKILL")" \
  "req-003: library audit and semantic check run as a parallel batch"

echo ""
echo "=== req-003: hard sequencing unchanged ==="

assert_equals "yes" "$(grep_has 'Never run tests before typecheck passes' "$VALIDATE_SKILL")" \
  "req-003: tests never run before typecheck passes"
assert_equals "yes" "$(grep_has 'cycle N+1 before N' "$VALIDATE_SKILL")" \
  "req-003: self-correct cycle ordering is sequential"
assert_equals "yes" "$(grep_has 'File out-of-scope discoveries to .plan/backlog/. per .ravintio-zero/standards/agent-dispatch-standards.md.' "$VALIDATE_SKILL")" \
  "req-003: out-of-scope discoveries route to the backlog per the dispatch standards"

print_summary
