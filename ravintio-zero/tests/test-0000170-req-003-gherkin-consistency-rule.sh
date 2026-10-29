#!/usr/bin/env bash
# 0000170 req-003: gherkin-consistency-rule (ADR-003)
# consistency-check.mjs flags a criterion with a missing or misordered Given, When, or Then.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

CHECK="$ZERO_DIR/scripts/consistency-check.mjs"
TMP="$(mktemp -d -t ravintio_0000170_req003_XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# Build a fixture plan/current with one requirement file. $1 = name, $2 = Acceptance Criteria body.
make_fixture() {
  local d="$TMP/$1/plan/current"
  mkdir -p "$d/requirements"
  printf '# Design\n## Scope\n- In: things\n' > "$d/design.md"
  printf '| Activity | Step | Story | Requirement |\n|---|---|---|---|\n| A | s | US-001 | REQ-001 |\n' > "$d/story-map.md"
  printf '# Requirement: REQ-001 - Demo\n**Source:** US-001\n## Acceptance Criteria\n%s\n## Dependencies\n- None.\n' "$2" > "$d/requirements/req-001-demo.md"
  echo "$d"
}

echo ""
echo "=== 0000170 req-003 gherkin-consistency-rule ==="

D=$(make_fixture missing $'- [ ] AC-1: No when\n  - Given a thing\n  - Then it works')
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-1: missing When exits 1"
assert_contains "req-001-demo.md" "$OUT" "req-003 AC-1: finding names the file"
assert_contains "AC-1" "$OUT" "req-003 AC-1: finding names the criterion"

D=$(make_fixture order $'- [ ] AC-2: Backwards\n  - Given a thing\n  - Then it works\n  - When it runs')
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-2: Then before When exits 1"
assert_contains "req-001-demo.md" "$OUT" "req-003 AC-2: finding names the file"
assert_contains "AC-2" "$OUT" "req-003 AC-2: finding names the criterion"

D=$(make_fixture noid $'- [ ] unnamed\n  - Given a thing\n  - When it runs')
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "1" "$RC" "req-003 AC-2: criterion without AC id exits 1"
assert_contains "line 4" "$OUT" "req-003 AC-2: finding names the line number"

D=$(make_fixture clean $'- [ ] AC-1: One\n  - Given a thing\n  - And another\n  - When it runs\n  - Then it works\n  - But not twice\n- [ ] AC-2: Two\n  - Given x\n  - When y\n  - Then z\n- [ ] AC-3: Three\n  - Given x\n  - When y\n  - Then z')
OUT=$(node "$CHECK" "$D" 2>&1); RC=$?
assert_equals "0" "$RC" "req-003 AC-3: valid Gherkin criteria exit 0"
if grep -qi 'gherkin' "$CHECK"; then echo "  PASS: req-003 AC-3: script header names the Gherkin check"; PASS=$((PASS+1))
else echo "  FAIL: req-003 AC-3: script header lacks Gherkin"; FAIL=$((FAIL+1)); fi

print_summary
