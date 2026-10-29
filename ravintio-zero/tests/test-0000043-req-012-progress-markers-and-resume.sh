#!/usr/bin/env bash
# Tests for feature 0000043-autonomous-roadmaps, req-012: progress markers and
# interrupted-unit resume.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
STD="$ZERO_DIR/standards/agent-dispatch-standards.md"
ORCH="$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md"
IMPL="$ZERO_DIR/skills/ravintio-implement/SKILL.md"
VAL="$ZERO_DIR/skills/ravintio-validate-and-accept/SKILL.md"
TPL="$ZERO_DIR/templates/build-log.template.md"
DRIVER="$ZERO_DIR/scripts/initiative-run.mjs"
PM="$(awk '$0 == "## Progress Markers and Interrupted Units" {on=1; next} on && /^---$/ {exit} on {print}' "$STD")"
RES="$(awk '$0 == "## Resume Detection" {on=1; next} on && /^---$/ {exit} on {print}' "$ORCH")"$'\n'"$(cat "$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-resume-detection.md")"

echo "=== req-012 (a): each dispatched unit writes progress markers ==="
assert_contains '- In progress: {unit} ({ISO-8601 timestamp})' "$PM" "req-012 (a): standard defines the In progress: line"
assert_contains 'commit it before the unit starts' "$PM" "req-012 (a): the In progress: line is committed before the unit starts"
assert_contains '- Done: {unit} ({ISO-8601 timestamp})' "$PM" "req-012 (a): standard defines the Done: line"
assert_contains 'same commit as the unit' "$PM" "req-012 (a): the Done: line lands with the unit's work"
assert_contains 'REQ-001 test-writer' "$PM" "req-012 (a): standard gives a unit name example"
assert_contains 'Progress Markers and Interrupted Units' "$(cat "$IMPL")" "req-012 (a): implement skill points to the standard"
assert_contains 'Progress Markers and Interrupted Units' "$(cat "$VAL")" "req-012 (a): validate skill points to the standard"
assert_contains 'In progress:' "$(cat "$TPL")" "req-012 (a): build-log template documents the In progress: line"

echo ""
echo "=== req-012 (b): resume reruns an interrupted unit ==="
assert_contains 'no later matching `Done:` line' "$PM" "req-012 (b): an unmatched In progress: line marks an interrupted unit"
assert_contains 'git stash push --include-untracked -m "interrupted {unit}"' "$PM" "req-012 (b): uncommitted changes go to a named stash"
assert_contains 'Rerun the unit from its start' "$PM" "req-012 (b): the unit reruns from its start"
assert_contains '- Resumed after interruption: {unit}' "$PM" "req-012 (b): resume logs the interruption"
assert_contains 'Never commit uncommitted files' "$PM" "req-012 (b): left-over files are never committed unchecked"
assert_contains 'Interrupted unit' "$RES" "req-012 (b): Resume Detection has an interrupted-unit step"
assert_contains 'Progress Markers and Interrupted Units' "$RES" "req-012 (b): Resume Detection points to the standard"
IDX_U="$(printf '%s\n' "$RES" | grep -n 'Interrupted unit' | head -1 | cut -d: -f1)"
IDX_O="$(printf '%s\n' "$RES" | grep -n '\*\*Open\.\*\*' | head -1 | cut -d: -f1)"
assert_equals "yes" "$([ -n "$IDX_U" ] && [ -n "$IDX_O" ] && [ "$IDX_U" -lt "$IDX_O" ] && echo yes || echo no)" \
  "req-012 (b): the interrupted-unit step comes before Open"

echo ""
echo "=== req-012 (c): progress markers don't stop the initiative driver ==="
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/r/plan/current-initiative" "$WORK/r/plan/current"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Stub claude: logs an unmatched In progress: line, then delivers.
printf -- '- In progress: REQ-001 test-writer (2026-10-24T10:00:00Z)\n' >> plan/current/build-log.md
mkdir -p plan/_archive
mv plan/current-initiative plan/_archive/0000050-demo-roadmap-2026-10-24
STUB
chmod +x "$WORK/bin/claude"
cat > "$WORK/r/plan/current-initiative/initiative.md" <<'EOF'
---
title: "Initiative: demo"
status: active
---
branch: initiative/0000050-demo
status: active
position: 1
EOF
: > "$WORK/r/plan/current/build-log.md"
OUT="$(cd "$WORK/r" && PATH="$WORK/bin:$PATH" node "$DRIVER" --root "$WORK/r" 2>&1)"
CODE=$?
assert_equals "0" "$CODE" "req-012 (c): an In progress: line is not a Blocked: line to the driver"
assert_contains 'I-E Delivery: Complete' "$OUT" "req-012 (c): the driver reaches delivery"

print_summary
