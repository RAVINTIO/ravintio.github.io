#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-003: I-B Activate.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
ORCH="$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md"
REF="$ZERO_DIR/pipeline-reference.md"
TPL="$ZERO_DIR/templates/initiative.template.md"
STD="$ZERO_DIR/standards/roadmap-standards.md"

# The section from a heading to the next "---" rule.
section() { awk -v h="$1" '$0 == h {on=1; next} on && /^---$/ {exit} on {print}' "$2"; }
RM="$(cat "$STD")"
AC="$(awk '$0 == "### I-B Activate" {on=1; next} on && /^#/ {exit} on {print}' "$STD")"

echo "=== req-003 (a): preflight checks and refusal ==="
assert_contains 'remote named `origin`' "$AC" "req-003 (a): origin check"
assert_contains '`gh` access' "$AC" "req-003 (a): gh check"
assert_contains 'initiative/{id}-*' "$AC" "req-003 (a): no existing initiative branch check"
assert_contains 'one active initiative per working tree' "$AC" "req-003 (a): one-active-initiative refusal"
assert_contains 'name the initiative that is already active' "$AC" "req-003 (a): refusal names the active initiative"
assert_contains '`Blocked:`' "$AC" "req-003 (a): failure stops with Blocked"
assert_contains 'before any branch or file changes' "$AC" "req-003 (a): stops before changes"

echo ""
echo "=== req-003 (b): branch, state, push ==="
assert_contains 'initiative/{id}-{slug}' "$AC" "req-003 (b): cuts the initiative branch"
assert_contains 'from `main`' "$AC" "req-003 (b): cut from main"
assert_contains 'plan/current-initiative/initiative.md' "$AC" "req-003 (b): writes the active initiative"
assert_contains '`status: active`' "$AC" "req-003 (b): status active"
assert_contains 'plan/roadmap/{id}-{slug}/' "$AC" "req-003 (b): deletes the draft folder"
assert_contains 'one commit' "$AC" "req-003 (b): one commit"
assert_contains 'Push' "$AC" "req-003 (b): pushes"

echo ""
echo "=== req-003 (c): driver offer ==="
assert_contains 'ravintio-zero/scripts/initiative-run.mjs' "$AC" "req-003 (c): names the driver"
assert_contains 'background task' "$AC" "req-003 (c): background task"
assert_contains 'must not edit the working tree' "$AC" "req-003 (c): parent must not edit the tree"

print_summary
