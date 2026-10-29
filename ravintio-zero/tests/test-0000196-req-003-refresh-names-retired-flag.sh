#!/usr/bin/env bash
# Tests for feature 0000196-setup-argument-checks, req-003: the refresh skill
# names a retired flag that a record or marker holds, and leaves it out of the
# command it proposes. ravintio-refresh-setup is a Markdown skill followed by
# an agent, so coverage is structural, as in
# test-0000032-req-004-refresh-setup-reads-record-first.sh.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL="$ZERO_DIR/skills/ravintio-refresh-setup/SKILL.md"

assert_equals "yes" "$([ -f "$SKILL" ] && echo yes || echo no)" \
  "req-003: ravintio-refresh-setup/SKILL.md exists"

STEP3=$(sed -n '/^## Step 3/,/^## Step 4/p' "$SKILL")

echo ""
echo "=== req-003 AC-1: a record that holds a retired flag is reported ==="

assert_contains "retired flag" "$STEP3" \
  "req-003 AC-1: Step 3 defines a retired flag"
for flag in --structured-telemetry-mcp --context-mode-mcp --include-full-skill-library --backend-url; do
  assert_contains "$flag" "$STEP3" "req-003 AC-1: Step 3 lists the retired flag $flag"
done
assert_contains "plan/state/{tool}.md" "$(printf '%s\n' "$STEP3" | grep -i 'retired' | head -3)" \
  "req-003 AC-1: a retired flag rule covers the record"
assert_contains "setup rejects" "$STEP3" \
  "req-003 AC-1: the report says that setup rejects the flag"

echo ""
echo "=== req-003 AC-2: a marker that holds a retired flag is reported ==="

assert_contains ".ravintio-setup-flags" "$(printf '%s\n' "$STEP3" | grep -i 'retired' | head -4)" \
  "req-003 AC-2: a retired flag rule covers the marker"

echo ""
echo "=== req-003 AC-3: the proposed command omits the retired flag ==="

assert_contains "omit" "$STEP3" \
  "req-003 AC-3: Step 3 omits a retired flag from the proposed command"
assert_equals "0" "$(grep -c -- 'setup.sh claude-code .*--backend-url' "$SKILL" || true)" \
  "req-003 AC-3: the skill never builds a command with a retired flag"

print_summary
