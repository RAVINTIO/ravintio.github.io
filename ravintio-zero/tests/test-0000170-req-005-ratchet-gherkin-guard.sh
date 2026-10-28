#!/usr/bin/env bash
# 0000170 req-005: ratchet-gherkin-guard (ADR-004)
# ratchet-check.mjs blocks removal of a Gherkin step line while a loop is active.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

RATCHET="$ZERO_DIR/hooks/enforcement/ratchet-check.mjs"
TMP="$(mktemp -d -t ravintio_0000170_req005_XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

PROJ="$TMP/proj"; mkdir -p "$PROJ/plan/current"
printf -- '---\nstatus: "active"\n---\n# Loop State: demo\n' > "$PROJ/plan/current/loop-state-demo.md"
REQ="$PROJ/plan/current/req-doc.md"
BASE=$'# Requirement: REQ-001 - Demo\n## Acceptance Criteria\n- [ ] AC-1: Demo\n  - Given an active loop\n  - When a step goes\n  - Then the hook blocks\n## Dependencies\n- None'
printf '%s\n' "$BASE" > "$REQ"

# Sends a Write of $1 to the hook. Sets CODE and ERR.
run_ratchet() {
  local payload
  payload=$(node -e 'process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:process.argv[1],content:process.argv[2]}}))' "$REQ" "$1")
  ( cd "$PROJ" && printf '%s' "$payload" | node "$RATCHET" >/dev/null 2> "$TMP/err" ); CODE=$?
  ERR="$(cat "$TMP/err")"
}

echo ""
echo "=== 0000170 req-005 ratchet-gherkin-guard ==="

run_ratchet $'# Requirement: REQ-001 - Demo\n## Acceptance Criteria\n- [ ] AC-1: Demo\n  - Given an active loop\n  - Then the hook blocks\n## Dependencies\n- None'
assert_equals "2" "$CODE" "req-005 AC-1: removing the When line exits 2"
assert_contains "When a step goes" "$ERR" "req-005 AC-1: stderr names the removed When line"
case "$ERR" in *"Given an active loop"*) echo "  FAIL: req-005 AC-1: stderr prints a kept line"; FAIL=$((FAIL+1));; *) echo "  PASS: req-005 AC-1: stderr prints no kept line"; PASS=$((PASS+1));; esac

run_ratchet $'# Requirement: REQ-001 - Demo\n## Acceptance Criteria\n- [ ] AC-1: Demo\n  - Given an active loop\n  - When a step goes\n  - Then the hook blocks\n  - And it says why\n## Dependencies\n- None'
assert_equals "0" "$CODE" "req-005 AC-2: adding an And line exits 0"

# AC-3: the 0000016 fixtures hold Gherkin lines and both suites pass.
for suite in "$ZERO_DIR/tests/test-0000016-pipeline-governance.sh" "$ZERO_DIR/tests/regression/test-0000016-pipeline-governance.sh"; do
  n=$(basename "$(dirname "$suite")")
  for kw in Given When Then; do
    if [ "$(grep -cE "^  - $kw " "$suite")" -ge 2 ]; then echo "  PASS: req-005 AC-3: $n suite fixture holds $kw"; PASS=$((PASS+1))
    else echo "  FAIL: req-005 AC-3: $n suite fixture lacks $kw"; FAIL=$((FAIL+1)); fi
  done
  bash "$suite" >/dev/null 2>&1
  assert_equals "0" "$?" "req-005 AC-3: $n suite exits 0"
done

print_summary
