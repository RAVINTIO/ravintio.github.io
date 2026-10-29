#!/usr/bin/env bash
# Tests for feature 0000207-codex-support, req-001 to req-003: setup installs
# the pack for the codex tool. It writes AGENTS.md, installs skills in
# .agents/skills, wires merge-guard in .codex/hooks.json, and reports which
# hooks are active and which fall back to instructions.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000207_codex_test_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  echo "$dir"
}

hook_count() {
  node -e '
    const h = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).hooks.PreToolUse || [];
    let n = 0;
    for (const g of h) for (const e of g.hooks || []) if (/merge-guard\.mjs/.test(e.command) && g.matcher === "Bash") n++;
    process.stdout.write(String(n));
  ' "$1"
}

echo ""
echo "=== req-001 AC-1, req-002 AC-1 to AC-3, req-003 AC-1 and AC-2: setup codex ==="

WS=$(make_workspace)
cd "$WS"
mkdir -p ravintio-overrides/instructions
echo "Local rule for the test." > ravintio-overrides/instructions/custom-001-test.md
OUT="$(bash ravintio-zero/setup.sh codex 2>&1)"
EXIT=$?
assert_equals "0" "$EXIT" "req-001 AC-1: setup codex exits 0"
[ -f plan/state/codex.md ] && R=yes || R=no
assert_equals "yes" "$R" "req-001 AC-1: plan/state/codex.md is written"
assert_contains "No code without a confirmed design" "$(cat AGENTS.md 2>/dev/null)" "req-002 AC-1: AGENTS.md holds the hard limits"
assert_contains "ravintio-overrides:instructions:start" "$(cat AGENTS.md 2>/dev/null)" "req-002 AC-1: AGENTS.md holds the override instructions"
[ -f .agents/skills/ravintio-orchestrator/SKILL.md ] && R=yes || R=no
assert_equals "yes" "$R" "req-002 AC-2: the orchestrator skill is installed in .agents/skills"
[ -f .agents/skills/.ravintio-manifest ] && R=yes || R=no
assert_equals "yes" "$R" "req-002 AC-2: the manifest is written"
[ -e CLAUDE.md ] && R=present || R=absent
assert_equals "absent" "$R" "req-002 AC-3: CLAUDE.md is absent"
[ -e .claude ] && R=present || R=absent
assert_equals "absent" "$R" "req-002 AC-3: .claude is absent"
assert_equals "1" "$(hook_count .codex/hooks.json)" "req-003 AC-1: hooks.json holds one merge-guard Bash entry"
[ -f .codex/hooks/enforcement/merge-guard.mjs ] && R=yes || R=no
assert_equals "yes" "$R" "req-003 AC-1: merge-guard.mjs is copied"
[ -f .codex/hooks/enforcement/read-stdin.mjs ] && R=yes || R=no
assert_equals "yes" "$R" "req-003 AC-1: read-stdin.mjs is copied"
[ -e .codex/hooks/enforcement/gate-write.mjs ] && R=present || R=absent
assert_equals "absent" "$R" "req-003 AC-1: gate-write.mjs is not copied"
assert_contains "Active hooks" "$OUT" "req-003 AC-2: the report has an active list"
assert_contains "merge-guard" "$OUT" "req-003 AC-2: merge-guard is active"
assert_contains "Fallback hooks" "$OUT" "req-003 AC-2: the report has a fallback list"
assert_contains "gate-write" "$OUT" "req-003 AC-2: gate-write is a fallback"
assert_contains "/hooks" "$OUT" "req-003 AC-2: the report names the /hooks review"
assert_contains "gate-write" "$(cat ravintio-zero/standards/hook-enforcement.md)" "req-003: the hook reference states the gate-write fallback"
# 0000217: real Codex 0.163.0 skips project hooks until a person trusts them, so
# the report and AGENTS.md must not call merge-guard active before that.
assert_contains "Until you trust it, Codex skips merge-guard" "$OUT" "0000217: the report says merge-guard is off until trusted"
assert_contains "nothing blocks a merge" "$(cat ravintio-zero/standards/hook-enforcement.md)" "0000217: the hook reference says nothing blocks a merge until the hook is trusted"

echo ""
echo "=== req-003 AC-1: a rerun keeps one entry and other entries ==="

node -e '
  const fs = require("fs");
  const f = ".codex/hooks.json";
  const j = JSON.parse(fs.readFileSync(f, "utf8"));
  j.hooks.PreToolUse.push({ matcher: "Bash", hooks: [{ type: "command", command: "echo user-hook" }] });
  j.custom = true;
  fs.writeFileSync(f, JSON.stringify(j));
'
OUT="$(bash ravintio-zero/setup.sh codex 2>&1)"
assert_equals "0" "$?" "req-003 AC-1: the rerun exits 0"
assert_equals "1" "$(hook_count .codex/hooks.json)" "req-003 AC-1: the rerun leaves one merge-guard entry"
assert_contains "user-hook" "$(cat .codex/hooks.json)" "req-003 AC-1: the rerun keeps the user's hook"
assert_contains '"custom":true' "$(tr -d ' \n' < .codex/hooks.json)" "req-003 AC-1: the rerun keeps other keys"
cd /; rm -rf "$WS"

echo ""
echo "=== req-003 AC-3: invalid hooks.json stops setup ==="

WS=$(make_workspace)
cd "$WS"
mkdir -p .codex
printf '{ not json' > .codex/hooks.json
OUT="$(bash ravintio-zero/setup.sh codex 2>&1)"
EXIT=$?
assert_equals "1" "$EXIT" "req-003 AC-3: invalid JSON exits 1"
assert_contains ".codex/hooks.json is not valid JSON" "$OUT" "req-003 AC-3: the fixed error line is printed"
assert_equals "{ not json" "$(cat .codex/hooks.json)" "req-003 AC-3: the file is unchanged"
cd /; rm -rf "$WS"

echo ""
echo "=== req-004 AC-3: claude-code is unchanged ==="

WS=$(make_workspace)
cd "$WS"
bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1
[ -f CLAUDE.md ] && R=yes || R=no
assert_equals "yes" "$R" "req-004 AC-3: CLAUDE.md exists"
[ -f .claude/settings.json ] && R=yes || R=no
assert_equals "yes" "$R" "req-004 AC-3: .claude/settings.json exists"
[ -e AGENTS.md ] && R=present || R=absent
assert_equals "absent" "$R" "req-004 AC-3: AGENTS.md is absent"
[ -e .codex ] && R=present || R=absent
assert_equals "absent" "$R" "req-004 AC-3: .codex is absent"
cd /; rm -rf "$WS"

print_summary
