#!/usr/bin/env bash
# Tests for feature 0000240-stream-step-session-activity, req-001 and req-004: driver.
#
# The driver starts claude with stream-json output, writes stdout to the step log only,
# and prints no step content. A stub claude records its arguments and prints a marker.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

DRIVER="$SCRIPT_DIR/../scripts/initiative-run.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin" "$WORK/r/plan/current-initiative" "$WORK/r/plan/current"
cat > "$WORK/bin/claude" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_LOG"
printf '{"type":"assistant","message":{"content":[{"type":"text","text":"SECRET-MARKER-7731"}]}}\n'
RM=plan/current-initiative/initiative.md
mkdir -p plan/_archive
mv plan/current-initiative "plan/_archive/0000050-demo-initiative-2026-10-23"
STUB
chmod +x "$WORK/bin/claude"
cat > "$WORK/r/plan/current-initiative/initiative.md" <<'EOF2'
---
title: "Initiative: demo"
summary: "One step."
status: active
---
# Initiative: demo

goal: demo
branch: initiative/0000050-demo
status: active
position: 1

| Step | Feature id | Backlog entries | Bump | Version | Status |
|------|------------|-----------------|------|---------|--------|
| 1 | 0000051-a | 0000011 | minor | | pending |
EOF2
: > "$WORK/r/plan/current/build-log.md"

OUT="$(cd "$WORK/r" && PATH="$WORK/bin:$PATH" STUB_LOG="$WORK/r/stub.log" node "$DRIVER" --root "$WORK/r" 2>&1)"
CODE=$?

echo ""
echo "=== req-001: stream-json arguments ==="
assert_exit_zero "$CODE" "req-001 AC-1: driver exits 0"
ARGS="$(cat "$WORK/r/stub.log")"
assert_contains "--output-format stream-json --verbose" "$ARGS" "req-001 AC-1: claude gets the stream-json flags"
assert_contains "Run initiative step 1" "$ARGS" "req-001 AC-1: claude gets the step prompt"

LOG="$WORK/r/plan/.initiative-logs/step-1.log"
assert_contains "SECRET-MARKER-7731" "$(cat "$LOG" 2>/dev/null)" "req-001 AC-2: the log holds the stream line"
MODE="$(stat -c %a "$LOG" 2>/dev/null || stat -f %Lp "$LOG" 2>/dev/null)"
assert_equals "600" "$MODE" "req-001 AC-2: the log has mode 600"

echo ""
echo "=== req-004: the driver prints no step content ==="
assert_not_contains "SECRET-MARKER-7731" "$OUT" "req-004 AC-1: driver output holds no step content"

print_summary
