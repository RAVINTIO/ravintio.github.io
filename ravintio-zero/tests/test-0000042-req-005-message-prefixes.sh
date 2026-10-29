#!/usr/bin/env bash
# Tests for feature 0000042-autonomous-mode-and-prefixes, req-005: message
# prefixes.
#
# Every message starts with one of five number-plus-name prefixes, then
# "{Status}: {one-liner}". The orchestrator prefix table and the pipeline
# reference "Phase Indicators" section agree on the prefixes and the form.
# The letter prefixes D:, PL:, IM:, VA:, and SH: are retired.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO_ROOT="$ZERO_DIR/.."
ORCH="$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md"
REF="$ZERO_DIR/pipeline-reference.md"

# The section from a heading to the next "---" rule.
section() { awk -v h="$1" '$0 == h {on=1; next} on && /^---$/ {exit} on {print}' "$2"; }
lacks_re() { printf '%s\n' "$2" | grep -qE -- "$1" && echo no || echo yes; }

ORCH_SEC="$(section '## Phases and Response Prefixes' "$ORCH")"
REF_SEC="$(section '## Phase Indicators' "$REF")"

PREFIXES=('P0 Discovery:' 'P1 Plan:' 'P2 Implement:' 'P3 Validate:' 'P4 Ship:')
STATUSES=(Starting Resuming Complete Blocked Skipped)
LETTERS='(^|[^A-Za-z0-9_])(D|PL|IM|VA|SH):'

for label in orchestrator pipeline-reference; do
  if [ "$label" = orchestrator ]; then SEC="$ORCH_SEC"; else SEC="$REF_SEC"; fi

  echo ""
  echo "=== req-005 (a): $label lists the five prefixes ==="
  for p in "${PREFIXES[@]}"; do
    assert_contains "\`$p\`" "$SEC" "req-005 (a): $label lists \`$p\`"
  done

  echo ""
  echo "=== req-005 (a): $label uses {prefix} {Status}: {one-liner} ==="
  assert_contains '`{prefix} {Status}: {one-liner}`' "$SEC" \
    "req-005 (a): $label states the one status form"
  for s in "${STATUSES[@]}"; do
    assert_equals "yes" "$(printf '%s\n' "$SEC" | grep -qE "\`P[0-4] [A-Za-z]+: $s: " && echo yes || echo no)" \
      "req-005 (a): $label shows $s in the colon form"
  done
  assert_equals "yes" "$(lacks_re '(Starting|Resuming|Complete|Blocked|Skipped), ' "$(printf '%s\n' "$SEC" | grep -oE '`[^`]*`')")" \
    "req-005 (a): $label has no comma after a status"
  assert_equals "yes" "$(lacks_re "$LETTERS" "$SEC")" \
    "req-005 (a): $label uses no retired letter prefix"
done

echo ""
echo "=== req-005: P3 messages say Validate, skills keep Validate and Accept ==="
assert_contains "| P3 | Validate and Accept |" "$ORCH_SEC" \
  "req-005: orchestrator table keeps the full name Validate and Accept"

echo ""
echo "=== req-005: no retired letter prefix in user-facing docs ==="
for f in "$REPO_ROOT/README.md" "$REPO_ROOT/docs/architecture-overview.md" \
         "$ZERO_DIR/getting-started.md" "$ORCH" "$REF"; do
  rel="${f#"$REPO_ROOT/"}"
  hits="$(grep -nE -- "$LETTERS" "$f" || true)"
  assert_equals "" "$hits" "req-005: $rel uses no retired letter prefix"
done

echo ""
echo "=== req-005: escalation messages keep the phase prefix first ==="
LOOP="$ZERO_DIR/skills/ravintio-loop-runner/SKILL.md"
FLOW="$ZERO_DIR/workflows/feature-pipeline.md"
assert_equals "" "$(grep -nE '\(D, PL, IM, VA, or SH\)' "$LOOP" || true)" \
  "req-005: loop-runner names no retired letter prefix"
assert_contains '{phase-prefix} Blocked ({loop-id}):' "$(cat "$LOOP")" \
  "req-005: loop-runner escalation puts Blocked after the phase prefix"
assert_equals "" "$(grep -n 'Each stop starts with `Blocked:`' "$FLOW" || true)" \
  "req-005: feature-pipeline puts the phase prefix before Blocked"

print_summary
