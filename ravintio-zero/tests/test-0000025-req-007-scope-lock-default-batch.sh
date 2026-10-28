#!/usr/bin/env bash
# Scope Lock Challenge: drafted inline by the orchestrator, batch presented,
# confirmed only by the human's explicit per-item accept, edit, or reject.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ORCH="$(orch_combined "$(cd "$SCRIPT_DIR/.." && pwd)/skills/ravintio-orchestrator")"
S=$(cat "$ORCH")

SL=$(printf '%s' "$S" | sed -n '/### Scope Lock Challenge/,/### /p')
assert_contains "Happy path" "$SL" "scope lock covers the happy path"
assert_contains "first" "$SL" "scope lock covers the first-run path"
assert_contains "Error path" "$SL" "scope lock covers the error path"
assert_contains "ross-session" "$SL" "scope lock covers cross-session continuity"
assert_contains "Draft inline" "$SL" "answers are drafted inline, no subagent"
assert_contains "Do not dispatch a subagent" "$SL" "subagent dispatch is barred"
assert_contains "accept, edit, or reject" "$SL" "per-item accept, edit, or reject"
assert_contains "ilence is never approval" "$SL" "silence is never approval"
assert_contains "build log" "$SL" "answers recorded in the build log"

print_summary
