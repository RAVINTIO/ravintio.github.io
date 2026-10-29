#!/usr/bin/env bash
# Test: 0000151 req-007 dispatch-model-tiers
# The dispatch standard names the Agent tool model values, every Agent call
# passes model, and the TDD dispatches use each skill's recommended_model.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd "$ZERO_DIR/.." && pwd)"

STD="$ZERO_DIR/standards/agent-dispatch-standards.md"
IMPL="$ZERO_DIR/skills/ravintio-implement/SKILL.md"

echo "=== (a) standard wording ==="
assert_equals "0" "$(grep -c 'claude-sonnet-4-6\|claude-haiku-4-5' "$STD")" "no stale model IDs in the standard"
assert_equals "yes" "$(grep -q '| Claude Code | `sonnet`' "$STD" && grep -q '`haiku`' "$STD" && echo yes || echo no)" "tier table names sonnet and haiku"
assert_equals "yes" "$(grep -q 'model: "haiku"' "$STD" && echo yes || echo no)" "examples pass model: \"haiku\""
assert_equals "yes" "$(grep -q 'without `model` inherits the parent' "$STD" && echo yes || echo no)" "no-model inherits the parent"
assert_equals "yes" "$(grep -q 'Every Agent call passes `model` explicitly' "$STD" && echo yes || echo no)" "every call passes model"

echo "=== (a) ravintio-implement wording ==="
LOOP=$(sed -n '/^## TDD inner loop/,/^## Rules/p' "$IMPL")
assert_contains 'recommended_model' "$LOOP" "TDD loop names recommended_model"
assert_contains 'fails twice' "$LOOP" "haiku unit failing twice is covered"
assert_contains 'retry' "$LOOP" "retry on sonnet is covered"
assert_contains 'five-attempt escalation is unchanged' "$LOOP" "five-attempt escalation unchanged"

echo "=== (b) model frontmatter and installed copies ==="
for s in test-writer implementer refactor; do
  assert_equals "yes" "$(sed -n '1,8p' "$ZERO_DIR/skills/ravintio-$s/SKILL.md" | grep -q '^model: haiku$' && echo yes || echo no)" "ravintio-$s sets model: haiku"
done
# Ship archives plan/current/, so read the build log from either place.
BL=$(cat "$ROOT_DIR"/plan/current/build-log.md "$ROOT_DIR"/plan/_archive/0000151-*/build-log.md 2>/dev/null | grep -c 'skill-level `model`')
assert_equals "yes" "$([ "$BL" -ge 1 ] && echo yes || echo no)" "build log records the skill-level model check"
DIFFS=0
for f in "$ROOT_DIR"/.claude/skills/*/references/agent-dispatch-standards.md; do
  [ -e "$f" ] || continue
  cmp -s "$f" "$STD" || DIFFS=$((DIFFS + 1))
done
assert_equals "0" "$DIFFS" "installed copies match the source"

print_summary
