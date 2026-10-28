#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-003: run-mode
# resume.
#
# On resume, a missing or unknown plan/.run-mode makes the orchestrator ask the
# run-mode question. It names what it found, writes the answer, and logs it. A
# valid value restores without a question, and a gated run shows its pending
# gate again. The fresh-start stale check is unchanged. pipeline-reference.md
# lets no mode skip a clean acceptance gate. As the last run-mode requirement,
# this suite also checks that no live file uses a retired run-mode value.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO_ROOT="$(cd "$ZERO_DIR/.." && pwd)"
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
REF="$ZERO_DIR/pipeline-reference.md"
REF_CONTENT="$(cat "$REF")"

# The numbered Resume Detection item whose bold label is $1.
ORCH_RESUME_REF="$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-resume-detection.md"
item() { grep -hE "^[0-9]+\. \*\*$1\.\*\*" "$ORCH" "$ORCH_RESUME_REF"; }
has() { printf '%s\n' "$2" | grep -qiF -- "$1" && echo yes || echo no; }

RESTORE="$(item 'Run-mode restore')"
OPEN="$(item 'Open')"

echo ""
echo "=== req-003 (a): a missing or unknown run mode asks again ==="

assert_contains 'If `plan/.run-mode` is missing or holds any value other than `gated` or `autonomous`, ask the run-mode question' "$RESTORE" \
  "req-003 (a): a missing or unknown value makes the orchestrator ask the run-mode question"
assert_contains '`plan/.run-mode` is missing' "$RESTORE" \
  "req-003 (a): the question says when the file is missing"
assert_contains '`plan/.run-mode` holds `{value}`, which is not a valid run mode' "$RESTORE" \
  "req-003 (a): the question names the value it found"
assert_contains 'Write the answer to `plan/.run-mode`' "$RESTORE" \
  "req-003 (a): the orchestrator writes the answer"
assert_contains 'Run mode: {gated | autonomous}' "$RESTORE" \
  "req-003 (a): the orchestrator logs the answer in the build log"
assert_equals "no" "$(has 'defaults to' "$RESTORE")" \
  "req-003 (a): a missing or unknown value no longer falls back silently"

echo ""
echo "=== req-003 (a): the fresh-start stale check is unchanged ==="

assert_contains '3. **Stale run-mode** (fresh starts only): if `plan/.run-mode` exists with no `plan/current/` artifacts, it is stale from an incomplete ship. Warn, delete it, continue.' \
  "$(cat "$ORCH" "$ORCH_RESUME_REF")" "req-003 (a): the stale run-mode check keeps its wording"

echo ""
echo "=== req-003 (b): a valid run mode restores without asking ==="

assert_contains 'If it holds `gated` or `autonomous`, restore that mode without asking.' "$RESTORE" \
  "req-003 (b): a valid value restores without a question"
assert_contains 'Read `plan/.run-mode` and the build log first' "$RESTORE" \
  "req-003 (b): the orchestrator reads the run mode and the build log first"
assert_contains 'with that phase'"'"'s prefix' "$OPEN" \
  "req-003 (b): the resume opens with the last phase's prefix"
assert_contains 'In `gated`, if the last phase ended at a gate with no `Gate accepted` line, show that gate again.' "$RESTORE" \
  "req-003 (b): a gated run shows its pending gate again"

echo ""
echo "=== req-003 (c): pipeline-reference lets no mode skip a clean acceptance gate ==="

assert_equals "no" "$(has 'skip a stop' "$REF_CONTENT")" \
  "req-003 (c): the skip-a-stop rule is gone"
assert_equals "no" "$(has 'nothing to check' "$REF_CONTENT")" \
  "req-003 (c): the nothing-to-check condition is gone"
assert_contains 'How should the agent run P1 to P4?' "$REF_CONTENT" \
  "req-003 (c): pipeline-reference shows the current run-mode question"
assert_contains 'The phase skills are the single source for gate behaviour.' "$REF_CONTENT" \
  "req-003 (c): pipeline-reference defers gate behaviour to the skills"

echo ""
echo "=== req-001 (b) backstop: no live file uses a retired run-mode value ==="

# Generic uses that are not run modes, plus history and this feature's tests.
hits="$(cd "$REPO_ROOT" && grep -rniwE 'continuous|interactive' \
    ravintio-zero README.md docs ravintio-overrides 2>/dev/null \
  | grep -v '^ravintio-zero/migrations/_done/' \
  | grep -v '^ravintio-zero/standards/reference/frontend-stack-evaluation.md:' \
  | grep -v '^ravintio-zero/tests/test-0000042-' \
  | grep -v 'test-0000023-req-001-continuous-run-p1-p3' || true)"
[ -n "$hits" ] && printf '        %s\n' "$hits"
assert_equals "" "$hits" "req-001 (b): no live file uses continuous or interactive as a run mode"

print_summary
