#!/usr/bin/env bash
# Tests for feature 0000032-relocate-setup-config-to-plan-state, req-005:
# layout-docs-updated.
#
# Covers ADR-001 (setup-config record lives in plan/state/): the layout docs
# describe plan/state/ as the record's home and no longer name
# ravintio-overrides/setup-config/ anywhere.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO_ROOT="$ZERO_DIR/.."

PLAN_README="$REPO_ROOT/plan/README.md"
FEATURE_STRUCTURE="$REPO_ROOT/plan/feature-structure.md"
PIPELINE_REFERENCE="$ZERO_DIR/pipeline-reference.md"
PROJECT_OPERATIONS="$ZERO_DIR/project-operations.md"

echo ""
echo "=== req-005: plan/README.md folder table ==="

assert_contains "state/" "$(grep '^| [`]state/[`]' "$PLAN_README")" \
  "req-005: plan/README.md folder table has a state/ row"

echo ""
echo "=== req-005: plan/feature-structure.md layout diagram ==="

LAYOUT_BLOCK="$(sed -n '/^plan\//,/^[`][`][`]/p' "$FEATURE_STRUCTURE")"

assert_contains "state/" "$(echo "$LAYOUT_BLOCK" | grep -- '-- state/')" \
  "req-005: plan/feature-structure.md layout block lists plan/state/"

echo ""
echo "=== req-005: pipeline-reference.md names the new record path ==="

assert_contains "plan/state/{tool}.md" "$(cat "$PIPELINE_REFERENCE")" \
  "req-005: pipeline-reference.md contains plan/state/{tool}.md"

RERUN_SECTION="$(awk '/^### Re-run setup after update/{flag=1} flag && /^### /&&!/^### Re-run setup after update/{if(NR>1)exit} flag{print}' "$PIPELINE_REFERENCE")"

if echo "$RERUN_SECTION" | grep -q 'never touches `ravintio-overrides/`'; then
  RERUN_HAS_UNQUALIFIED="yes"
else
  RERUN_HAS_UNQUALIFIED="no"
fi
assert_equals "no" "$RERUN_HAS_UNQUALIFIED" \
  "req-005: re-run paragraph no longer contains the unqualified phrase 'never touches ravintio-overrides/'"

echo ""
echo "=== req-005: no doc names the old ravintio-overrides/setup-config location ==="

OLD_PATH_HITS="$(grep -l 'ravintio-overrides/setup-config' \
  "$PLAN_README" "$FEATURE_STRUCTURE" "$PIPELINE_REFERENCE" "$PROJECT_OPERATIONS" 2>/dev/null || true)"

assert_equals "" "$OLD_PATH_HITS" \
  "req-005: grep for ravintio-overrides/setup-config across the four docs returns nothing"

print_summary
