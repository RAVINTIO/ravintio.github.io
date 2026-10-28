#!/usr/bin/env bash
# Tests for feature 0000203-blameless-postmortems, req-002: the orchestrator
# trigger, the build report line, and the living docs.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO="$ZERO_DIR/.."
ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
CATALOGUE="$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-skills-catalogue.md"
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"

STOPS=$(awk '/^## Exception Stops/{f=1;next} /^## /{f=0} f' "$ORCH")
STEP5=$(awk '/^### Step 5: Build assessment/{f=1;next} /^### /{f=0} f' "$SHIP")

echo ""
echo "=== req-002 AC-1: the orchestrator runs the skill after a Resolved line ==="
assert_contains "ravintio-postmortem" "$STOPS" "req-002 AC-1: Exception Stops names the skill"
assert_contains "before ship" "$STOPS" "req-002 AC-1: the skill runs before ship"
assert_contains "| ravintio-postmortem |" "$(cat "$CATALOGUE")" "req-002 AC-1: the catalogue has a row"

echo ""
echo "=== req-002 AC-2: the build report lists postmortems ==="
assert_contains "plan/postmortems/" "$STEP5" "req-002 AC-2: the build assessment reads plan/postmortems/"
assert_contains "postmortem" "$STEP5" "req-002 AC-2: the report lists the run's postmortems"

echo ""
echo "=== req-002 AC-3: the docs name the skill ==="
for f in "$ZERO_DIR/component.yml" "$ZERO_DIR/pipeline-reference.md" "$REPO/docs/architecture-overview.md"; do
  T=$(cat "$f")
  assert_contains "ravintio-postmortem" "$T" "req-002 AC-3: $(basename "$f") names the skill"
done
assert_contains "The 16 skills" "$(cat "$ZERO_DIR/component.yml")" "req-002 AC-3: component.yml counts 16 skills"
assert_contains "sixteen" "$(cat "$REPO/docs/architecture-overview.md")" "req-002 AC-3: the overview counts sixteen skills"

print_summary
