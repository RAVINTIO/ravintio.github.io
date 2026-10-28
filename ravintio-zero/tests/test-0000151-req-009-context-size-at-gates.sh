#!/usr/bin/env bash
# Test: 0000151 req-009 context-size-at-gates
# At each phase gate in a gated run, the orchestrator states the context size
# and recommends /clear past about 150,000 tokens. The rule is advisory.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
PI=$(sed -n '/^## Phase Invocation/,/^## Exception Stops/p' "$ORCH")
DC=$(sed -n '/^### Design Confirmation/,/^## Phase Invocation/p' "$ORCH")

echo "=== (a) context size at gates ==="
assert_contains '150,000' "$PI" "names the 150,000 token threshold"
assert_contains '/clear' "$PI" "recommends /clear"
assert_contains 'At each phase gate in a gated run' "$PI" "applies at each gated phase gate"
assert_contains 'P0 design gate' "$PI" "names the P0 design gate"
assert_contains 'usage figure the host reports' "$PI" "host-reported usage first"
assert_contains 'labelled as an estimate' "$PI" "labelled estimate second"
assert_contains 'advisory' "$PI" "statement is advisory"
assert_contains 'never blocks, delays, or skips a gate' "$PI" "never blocks a gate"
assert_contains 'autonomous run or an initiative step does not report context size' "$PI" "autonomous run and initiative step do not report"
assert_contains 'Resume Detection' "$PI" "names the resume route"
assert_contains 'Context size at gates' "$DC" "design gate points to the rule"

print_summary
