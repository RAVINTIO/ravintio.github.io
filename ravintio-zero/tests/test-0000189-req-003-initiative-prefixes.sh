#!/usr/bin/env bash
# Tests for feature 0000189-name-the-roadmap-initiative, req-003: initiative prefixes.
#
# AC-1: the orchestrator skill and roadmap-standards.md list I-A to I-E and no R- prefix.
# AC-2: the driver stops on a non-active initiative with a line starting "I-C Run: Blocked:".

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
DRIVER="$ZERO_DIR/scripts/initiative-run.mjs"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo ""
echo "=== req-003 AC-1: stage tables ==="
for f in "$ZERO_DIR/skills/ravintio-orchestrator/SKILL.md" "$ZERO_DIR/standards/roadmap-standards.md"; do
  n="$(basename "$(dirname "$f")")/$(basename "$f")"
  t="$(cat "$f")"
  # 0000244 moved the prefix block from the orchestrator skill to the roadmap standards. The skill keeps a pointer.
  case "$f" in */SKILL.md)
    assert_contains "roadmap-standards.md" "$(grep -F 'Initiative stages use the prefixes I-A to I-E' "$f")" "req-003 AC-1: $n points at the roadmap standards for I-A to I-E"
    t="$t"$'\n'"$(cat "$ZERO_DIR/standards/roadmap-standards.md")";;
  esac
  for p in "I-A Chart" "I-B Activate" "I-C Run" "I-D Advance" "I-E Delivery"; do
    assert_contains "$p" "$t" "req-003 AC-1: $n lists $p"
  done
  has=no
  printf '%s\n' "$t" | grep -qE '(^|[^A-Za-z0-9])R-[A-E]([^A-Za-z0-9]|$)' && has=yes
  assert_equals "no" "$has" "req-003 AC-1: $n has no R-A to R-E prefix"
done

echo ""
echo "=== req-003 AC-2: driver stop line ==="
R="$WORK/blocked"
mkdir -p "$R/plan/current-initiative"
cat > "$R/plan/current-initiative/initiative.md" <<'EOT'
---
title: "Initiative: demo"
status: blocked
---
branch: initiative/0000050-demo
status: blocked
position: 1
EOT
OUT="$(cd "$R" && node "$DRIVER" --root "$R" 2>&1)"
CODE=$?
assert_equals "1" "$CODE" "req-003 AC-2: non-active status exits 1"
assert_equals "1" "$(printf '%s\n' "$OUT" | grep -c '^I-C Run: Blocked:')" "req-003 AC-2: line starts I-C Run: Blocked:"

print_summary
