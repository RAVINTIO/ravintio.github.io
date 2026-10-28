#!/usr/bin/env bash
# Feature 0000031 req-003: five phases, 16 skills, five phase names in pipeline-reference.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$ZERO_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

echo "=== (a) exactly 15 skill folders ==="
COUNT=$(ls -d "$ZERO_DIR/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
assert_equals "16" "$COUNT" "16 skill folders"
for s in ravintio-orchestrator ravintio-plan ravintio-implement ravintio-validate-and-accept ravintio-ship ravintio-test-writer ravintio-implementer ravintio-refactor ravintio-loop-runner ravintio-optimise-agent ravintio-migrator ravintio-refresh-setup ravintio-file-backlog ravintio-postmortem ravintio-retrospective ravintio-initiative; do
  assert_equals "yes" "$([ -f "$ZERO_DIR/skills/$s/SKILL.md" ] && echo yes || echo no)" "skill $s present"
done

echo "=== (b) pipeline-reference names exactly the five phases ==="
REF="$ZERO_DIR/pipeline-reference.md"
REF_TEXT="$(cat "$REF")"
for p in discovery plan implement validate-and-accept ship; do
  assert_contains "\`$p\`" "$REF_TEXT" "pipeline-reference names phase $p"
done
for old in spec adr codegen security docs; do
  assert_equals "0" "$(grep -c "\`$old\`" "$REF" || true)" "old phase name $old gone from pipeline-reference"
done

# Case (e) checked the phase names in the validate-telemetry-schema job.
# 0000037 req-001 removed that job, so the case is gone.

echo "=== (f) NFR: skills text at or below 1720 lines ==="
TOTAL=$(find "$ZERO_DIR/skills" -name "SKILL.md" -exec cat {} + | wc -l | tr -d ' ')
assert_equals "yes" "$([ "$TOTAL" -le 1720 ] && echo yes || echo no)" "skill text $TOTAL <= 1720"

print_summary
