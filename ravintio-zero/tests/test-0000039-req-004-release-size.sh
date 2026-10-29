#!/usr/bin/env bash
# REGRESSION-CANDIDATE: fails when the orchestrator loses the releaseSize budgets or a skill or template restates the fixed 3-story rule.
# Tests for feature 0000039-setup-hardening-release-sizing, req-004: discovery
# sizes each release from an optional releaseSize field in product.yml
# (ADR-004). No skill or template states the fixed 3-story rule.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ORCH="$(orch_combined "$ROOT/skills/ravintio-orchestrator")"
S=$(cat "$ORCH")
DECOMP=$(printf '%s\n' "$S" | sed -n '/^### Decomposition/,/^# Orchestrator reference:/p')
START=$(printf '%s\n' "$S" | sed -n '/^### Discovery Start Actions/,/^### Discovery Gate Checklist/p')

echo "=== req-004: the orchestrator defines releaseSize and its budgets ==="
assert_contains '`releaseSize`' "$DECOMP" \
  "req-004: Decomposition defines releaseSize"
assert_contains 'product.yml' "$DECOMP" \
  "req-004: Decomposition places releaseSize in product.yml"
for row in '| `small` | 4 |' '| `medium` (default) | 8 |' '| `large` | 14 |'; do
  assert_contains "$row" "$DECOMP" "req-004: budget row $row"
done
assert_contains 'If `releaseSize` is absent, use `medium`' "$DECOMP" \
  "req-004: an absent releaseSize defaults to medium"

echo "=== req-004: the orchestrator defines the size classes ==="
for row in '| S | 1 to 2 | 1 |' '| M | 3 to 6 | 2 |' '| L | 7 or more | 4 |'; do
  assert_contains "$row" "$DECOMP" "req-004: size class row $row"
done
assert_contains "recommend a split" "$DECOMP" \
  "req-004: discovery recommends a split above the budget"
assert_contains "human confirms" "$DECOMP" \
  "req-004: the human confirms the recommended fill"

echo "=== req-004: an unknown value gets a note and the medium budget ==="
assert_contains "unknown value" "$DECOMP" \
  "req-004: Decomposition covers an unknown releaseSize value"
assert_contains 'note it in `discovery.md`' "$DECOMP" \
  "req-004: discovery notes the unknown value"
assert_contains 'ask the human to fix the field' "$DECOMP" \
  "req-004: discovery asks the human to fix the field"

echo "=== req-004: discovery start actions read releaseSize ==="
STEP10=$(printf '%s\n' "$START" | grep -E '^10\. \*\*Backlog pickup\*\*')
assert_contains '`releaseSize`' "$STEP10" \
  "req-004: backlog pickup reads releaseSize"

echo "=== req-004: the wave guidance stays ==="
assert_contains "group them into waves" "$DECOMP" \
  "req-004: Decomposition keeps the wave guidance"

echo "=== req-004: no skill or template states the fixed 3-story rule ==="
HITS=$(grep -rniE 'more than (3|three) (user )?stories' \
  "$ROOT/skills" "$ROOT/templates" || true)
assert_equals "" "$HITS" \
  "req-004: no file under skills/ or templates/ states the 3-story rule"
for f in feature-brief.template.md feature-brief-guide.md; do
  T=$(cat "$ROOT/templates/$f")
  assert_contains 'releaseSize' "$T" "req-004: $f points to releaseSize"
done
assert_contains 'more than 3 acceptance criteria' \
  "$(cat "$ROOT/templates/feature-brief.template.md")" \
  "req-004: the acceptance-criteria split rule stays in the brief template"

echo "=== req-004: the product.yml template documents releaseSize ==="
PT=$(cat "$ROOT/templates/product.template.yml")
assert_contains 'releaseSize' "$PT" \
  "req-004: product.template.yml documents releaseSize"

print_summary
