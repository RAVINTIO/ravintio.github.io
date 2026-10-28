#!/usr/bin/env bash
# Feature 0000173 req-002: thresholds live in a pack standard and the gate reports without blocking.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$ZERO_DIR/scripts/workflow-metrics.mjs"
STANDARD="$ZERO_DIR/standards/workflow-governance-standards.md"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

assert_equals "yes" "$([ -f "$STANDARD" ] && echo yes || echo no)" "standard exists"
assert_equals "yes" "$([ -f "$SCRIPT" ] && echo yes || echo no)" "workflow-metrics.mjs exists"
[ -f "$SCRIPT" ] && [ -f "$STANDARD" ] || { print_summary; exit 1; }

run_metrics() {
  local folder="$1"; shift
  OUT=$(node "$SCRIPT" "$@" "$folder" 2>"$TMP_ROOT/err")
  CODE=$?
  ERR=$(cat "$TMP_ROOT/err")
}

F="$TMP_ROOT/run"; mkdir -p "$F"
cat > "$F/build-log.md" <<'LOG'
Blocked: one (2026-10-25T10:00:00Z)
Blocked: two (2026-10-25T10:01:00Z)
Blocked: three (2026-10-25T10:02:00Z)
LOG

write_standard() {
  # write_standard <path> <rework> <blocked> <design> <gate>; an empty value omits the row.
  local p="$1"
  {
    echo "# Test standard"
    echo ""
    echo "## Thresholds"
    echo ""
    echo "| Metric | Key | Threshold |"
    echo "|--------|-----|-----------|"
    [ -n "$2" ] && echo "| Rework | rework-per-requirement | $2 |"
    [ -n "$3" ] && echo "| Blocked | blocked-stops | $3 |"
    [ -n "$4" ] && echo "| Design | design-changes | $4 |"
    [ -n "$5" ] && echo "| Gate | gate-corrections | $5 |"
    true
  } > "$p"
}

echo "=== standard content ==="
S=$(cat "$STANDARD")
assert_contains "## Thresholds" "$S" "standard has a Thresholds heading"
assert_contains "| Metric | Key | Threshold |" "$S" "standard has the table header"
assert_contains "| rework-per-requirement | 2 |" "$S" "default rework threshold is 2"
assert_contains "| blocked-stops | 1 |" "$S" "default blocked threshold is 1"
assert_contains "| design-changes | 1 |" "$S" "default design-change threshold is 1"
assert_contains "| gate-corrections | 2 |" "$S" "default gate-correction threshold is 2"
assert_contains "Rework: REQ-{nnn}:" "$S" "standard defines the Rework marker"
assert_contains "Blocked: {exception}" "$S" "standard defines the Blocked marker"
assert_contains "Requirement change: {cosmetic | additive | contradictory}:" "$S" "standard defines the Requirement change marker"
assert_contains "Gate revised: P{N}" "$S" "standard defines the Gate revised marker"
assert_contains "greater than" "$S" "standard states the breach rule"
assert_contains "never blocks" "$S" "standard states the gate never blocks"
assert_contains "Workflow governance: not measured" "$S" "standard states the failure line for ship"

echo "=== AC-1: reports a breach without blocking (default standard) ==="
run_metrics "$F"
assert_equals "0" "$CODE" "AC-1: exits 0 on a breach"
assert_contains '| `Blocked:` stops | 3 | 1 | breach |' "$OUT" "AC-1: blocked row reads breach"
assert_contains "Breaches: 1." "$OUT" "AC-1: breach count line"

echo "=== AC-2: reads thresholds from the standard ==="
write_standard "$TMP_ROOT/std5.md" 2 5 1 2
run_metrics "$F" --standard "$TMP_ROOT/std5.md"
assert_equals "0" "$CODE" "AC-2: exits 0"
assert_contains '| `Blocked:` stops | 3 | 5 | ok |' "$OUT" "AC-2: blocked row reads ok at threshold 5"
write_standard "$TMP_ROOT/std3.md" 2 3 1 2
run_metrics "$F" --standard "$TMP_ROOT/std3.md"
assert_contains '| `Blocked:` stops | 3 | 3 | ok |' "$OUT" "AC-2: a value equal to the threshold is ok"

echo "=== AC-3: rejects a bad thresholds table ==="
write_standard "$TMP_ROOT/nogate.md" 2 1 1 ""
run_metrics "$F" --standard "$TMP_ROOT/nogate.md"
assert_equals "1" "$CODE" "AC-3: missing key exits 1"
assert_contains "gate-corrections" "$ERR" "AC-3: stderr names gate-corrections"
write_standard "$TMP_ROOT/bad.md" 2 many 1 2
run_metrics "$F" --standard "$TMP_ROOT/bad.md"
assert_equals "1" "$CODE" "AC-3: non-whole-number exits 1"
assert_contains "blocked-stops" "$ERR" "AC-3: stderr names blocked-stops"
run_metrics "$F" --standard "$TMP_ROOT/absent.md"
assert_equals "1" "$CODE" "AC-3: unreadable standard exits 1"

print_summary
