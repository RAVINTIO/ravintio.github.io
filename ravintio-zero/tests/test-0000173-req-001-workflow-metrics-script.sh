#!/usr/bin/env bash
# Feature 0000173 req-001: workflow-metrics.mjs derives four metrics from marker lines.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPT="$ZERO_DIR/scripts/workflow-metrics.mjs"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

assert_equals "yes" "$([ -f "$SCRIPT" ] && echo yes || echo no)" "workflow-metrics.mjs exists"
[ -f "$SCRIPT" ] || { print_summary; exit 1; }

# run_metrics <folder> [extra args]: sets OUT (stdout), ERR (stderr), CODE.
run_metrics() {
  local folder="$1"; shift
  OUT=$(node "$SCRIPT" "$@" "$folder" 2>"$TMP_ROOT/err")
  CODE=$?
  ERR=$(cat "$TMP_ROOT/err")
}

echo "=== AC-1: counts each marker ==="
F="$TMP_ROOT/counts"; mkdir -p "$F"
cat > "$F/build-log.md" <<'LOG'
# Build log

Rework: REQ-002: test failed twice (2026-10-25T10:00:00Z)
- Rework: REQ-002: wrong output (2026-10-25T10:05:00Z)
1. Rework: REQ-001: typo (2026-10-25T10:06:00Z)
Blocked: missing credential (2026-10-25T10:10:00Z)
* Requirement change: additive: new flag (2026-10-25T10:20:00Z)
  Gate revised: P1 (2026-10-25T10:30:00Z, scope cut)
Gate revised: P2 (2026-10-25T10:40:00Z, added AC)
LOG
cat > "$F/loop-state-implement.md" <<'LS'
---
status: done
---
Rework: REQ-002: loop-state rework (2026-10-25T11:00:00Z)
LS
run_metrics "$F"
assert_equals "0" "$CODE" "AC-1: exits 0"
assert_contains "## Workflow governance" "$OUT" "AC-1: prints the section heading"
assert_contains "| Rework loops per requirement (highest) | 3 (REQ-002) | 2 | breach |" "$OUT" "AC-1: rework row names REQ-002 with 3 (loop-state counted)"
assert_contains '| `Blocked:` stops | 1 | 1 | ok |' "$OUT" "AC-1: blocked count is 1"
assert_contains "| Mid-pipeline design changes | 1 | 1 | ok |" "$OUT" "AC-1: design change count is 1"
assert_contains "| Human corrections at gates | 2 | 2 | ok |" "$OUT" "AC-1: gate correction count is 2"
assert_contains "Breaches: 1. The gate reports and does not block. Counts come from marker lines only." "$OUT" "AC-1: closing line"

echo "=== AC-1: no rework markers ==="
F="$TMP_ROOT/none"; mkdir -p "$F"
printf '# Build log\nNothing here.\n' > "$F/build-log.md"
run_metrics "$F"
assert_equals "0" "$CODE" "AC-1: build log alone exits 0"
assert_contains "| Rework loops per requirement (highest) | 0 | 2 | ok |" "$OUT" "AC-1: rework value is 0 with no markers"
assert_contains "Breaches: 0." "$OUT" "AC-1: zero breaches"

echo "=== AC-2: ignores prose and fenced code ==="
F="$TMP_ROOT/prose"; mkdir -p "$F"
cat > "$F/build-log.md" <<'LOG'
The agent hit Blocked: a missing file and moved on.
Notes: Rework: REQ-001: not at line start
```
Blocked: inside a backtick fence
Rework: REQ-005: inside fence
```
~~~
Blocked: inside a tilde fence
~~~
Blocked: real stop (2026-10-25T10:10:00Z)
LOG
run_metrics "$F"
assert_contains '| `Blocked:` stops | 1 | 1 | ok |' "$OUT" "AC-2: only the line-start marker counts"
assert_contains "| Rework loops per requirement (highest) | 0 | 2 | ok |" "$OUT" "AC-2: fenced and mid-line rework ignored"

echo "=== AC-2: output never echoes marker text ==="
F="$TMP_ROOT/echo"; mkdir -p "$F"
printf 'Blocked: SECRET-REASON-TEXT (2026-10-25T10:10:00Z)\n' > "$F/build-log.md"
run_metrics "$F"
case "$OUT" in *SECRET-REASON-TEXT*) E=leaked ;; *) E=clean ;; esac
assert_equals "clean" "$E" "AC-2: marker text is not printed"

echo "=== AC-3: fails cleanly without a build log ==="
F="$TMP_ROOT/nolog"; mkdir -p "$F"
run_metrics "$F"
assert_equals "1" "$CODE" "AC-3: exits 1"
assert_contains "$F/build-log.md" "$ERR" "AC-3: stderr names the missing path"
assert_equals "" "$OUT" "AC-3: stdout is empty"

echo "=== usage error ==="
OUT=$(node "$SCRIPT" 2>&1); CODE=$?
assert_equals "2" "$CODE" "usage: no folder exits 2"

echo "=== writes no file ==="
F="$TMP_ROOT/nowrite"; mkdir -p "$F"
printf 'Blocked: x\n' > "$F/build-log.md"
BEFORE=$(ls -A "$F" | tr '\n' ' ')
run_metrics "$F"
assert_equals "$BEFORE" "$(ls -A "$F" | tr '\n' ' ')" "run folder holds the same files after the run"

echo "=== performance: 1,000-line build log ==="
F="$TMP_ROOT/perf"; mkdir -p "$F"
i=0
: > "$F/build-log.md"
while [ "$i" -lt 250 ]; do
  printf 'Prose line %s\nRework: REQ-001: r (2026-10-25T10:00:00Z)\nBlocked: b\n- Gate revised: P1 (2026-10-25T10:00:00Z, x)\n' "$i" >> "$F/build-log.md"
  i=$((i + 1))
done
T0=$(node -e 'console.log(Date.now())')
run_metrics "$F"
T1=$(node -e 'console.log(Date.now())')
ELAPSED=$((T1 - T0))
# The two node -e calls add start-up time, so allow 1,000 ms for the whole span.
assert_equals "yes" "$([ "$ELAPSED" -lt 1000 ] && echo yes || echo no)" "performance: 1,000-line log finishes under 1 second (${ELAPSED} ms)"
assert_contains "250 (REQ-001)" "$OUT" "performance: count is correct at scale"

print_summary
