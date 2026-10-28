#!/usr/bin/env bash
# Feature 0000031 req-004: setup works by execution in a fresh temp clone,
# prunes retired skills, honours overrides. Replaces the never-run test_setup pair.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$ZERO_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

OLD_NAME="planifest""-framework"

WS=$(mktemp -d)
trap 'rm -rf "$WS"' EXIT

echo "=== (a) fresh install ==="
mkdir -p "$WS/clone"
cp -R "$ZERO_DIR" "$WS/clone/ravintio-zero"
mkdir -p "$WS/clone/ravintio-overrides/instructions"
( cd "$WS/clone" && git init -q . && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1 )
assert_equals "0" "$?" "setup.sh exits 0"
assert_equals "yes" "$([ -f "$WS/clone/.claude/settings.json" ] && echo yes || echo no)" "settings.json written"
SKILLS=$(ls -d "$WS/clone/.claude/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
assert_equals "16" "$SKILLS" "exactly 16 skills installed"
assert_equals "no" "$([ -d "$WS/clone/.claude/hooks/telemetry" ] && echo yes || echo no)" "no telemetry hook directory created"

echo "=== (b) pruning: retired skill folder removed on re-run ==="
mkdir -p "$WS/clone/.claude/skills/ravintio-change-agent"
touch "$WS/clone/.claude/skills/ravintio-change-agent/SKILL.md"
( cd "$WS/clone" && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1 )
assert_equals "no" "$([ -d "$WS/clone/.claude/skills/ravintio-change-agent" ] && echo yes || echo no)" "retired skill pruned on regeneration"
SKILLS2=$(ls -d "$WS/clone/.claude/skills/"*/ 2>/dev/null | wc -l | tr -d ' ')
assert_equals "16" "$SKILLS2" "still exactly 16 skills after re-run"

echo "=== (c) install installs enforcement hooks only ==="
mkdir -p "$WS/clone2"
cp -R "$ZERO_DIR" "$WS/clone2/ravintio-zero"
( cd "$WS/clone2" && git init -q . && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1 )
assert_equals "0" "$?" "setup.sh exits 0"
assert_equals "yes" "$([ -d "$WS/clone2/.claude/hooks/enforcement" ] && echo yes || echo no)" "enforcement hooks installed"
assert_equals "no" "$([ -d "$WS/clone2/.claude/hooks/telemetry" ] && echo yes || echo no)" "telemetry hooks absent"

echo "=== (c2) retired telemetry flags are rejected ==="
mkdir -p "$WS/clone3"
cp -R "$ZERO_DIR" "$WS/clone3/ravintio-zero"
# 0000196 ADR-002: a retired flag now fails during argument parsing, so setup exits 1.
( cd "$WS/clone3" && git init -q . && bash ravintio-zero/setup.sh claude-code --structured-telemetry-mcp >/dev/null 2>&1 )
assert_equals "1" "$?" "setup.sh exits 1 on the retired --structured-telemetry-mcp"
assert_equals "no" "$([ -d "$WS/clone3/.claude/hooks/telemetry" ] && echo yes || echo no)" "no telemetry hook directory after a run with the retired flag"

echo "=== (d) installed tree references no old name ==="
HITS=$(grep -rl "$OLD_NAME" "$WS/clone/.claude" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$HITS" "installed tree clean of old name"

print_summary
