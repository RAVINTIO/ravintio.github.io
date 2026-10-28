#!/usr/bin/env bash
# Test: 0000245 req-002 targeted overrides
# AC-1: an override with `target: {skill}` lands in that skill once, not in the boot file.
# AC-2: a missing or malformed target warns and falls back to the boot file.
# AC-3: an override with no target stays in the boot file.
# Also: traversal rejection, stale-block cleanup, capability-skill targets.

set -uo pipefail
unset RAVINTIO_INITIATIVE_STEP
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TMPS=("")
trap 'for d in "${TMPS[@]}"; do rm -rf "$d"; done' EXIT

make_workspace() {
  local dir
  dir="$(mktemp -d -t ravintio_0000245_req002_XXXXXX)"
  TMPS+=("$dir")
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  mkdir -p "$dir/ravintio-overrides/instructions"
  echo "$dir"
}

run_setup() { (cd "$1" && bash ravintio-zero/setup.sh claude-code 2>&1); }
count() { grep -cF -- "$1" "$2" 2>/dev/null || true; }
SHIP=".claude/skills/ravintio-ship/SKILL.md"
START='<!-- ravintio-overrides:instructions:start -->'

echo "=== AC-1: targeted override lands in the skill once ==="
WS="$(make_workspace)"
printf -- '---\ntarget: ravintio-ship\n---\nSHIP-RULE-MARK push then raise the PR.\n' > "$WS/ravintio-overrides/instructions/ship-rule.md"
run_setup "$WS" >/dev/null; run_setup "$WS" >/dev/null
assert_equals "1" "$(count SHIP-RULE-MARK "$WS/$SHIP")" "ship skill holds the text once after two runs"
assert_equals "1" "$(count "$START" "$WS/$SHIP")" "ship skill holds one marker block"
assert_equals "0" "$(count SHIP-RULE-MARK "$WS/CLAUDE.md")" "boot file does not hold the text"
assert_equals "0" "$(count 'target: ravintio-ship' "$WS/$SHIP")" "frontmatter is stripped"
assert_equals "0" "$(count "$START" "$WS/.claude/skills/ravintio-plan/SKILL.md")" "other skills get no block"

echo "=== stale block: removing the target leaves no block ==="
printf 'SHIP-RULE-MARK now untargeted.\n' > "$WS/ravintio-overrides/instructions/ship-rule.md"
run_setup "$WS" >/dev/null
assert_equals "0" "$(count SHIP-RULE-MARK "$WS/$SHIP")" "ship skill holds no text after the target is removed"
assert_equals "0" "$(count "$START" "$WS/$SHIP")" "ship skill holds no marker after the target is removed"
assert_equals "1" "$(count SHIP-RULE-MARK "$WS/CLAUDE.md")" "boot file holds the untargeted text"
rm "$WS/ravintio-overrides/instructions/ship-rule.md"
printf -- '---\ntarget: ravintio-ship\n---\nSHIP-RULE-MARK\n' > "$WS/ravintio-overrides/instructions/ship-rule.md"
run_setup "$WS" >/dev/null
rm "$WS/ravintio-overrides/instructions/ship-rule.md"
run_setup "$WS" >/dev/null
assert_equals "0" "$(count "$START" "$WS/$SHIP")" "deleting the override file leaves no block"

echo "=== AC-2: bad targets fall back to the boot file ==="
for bad in 'no-such-skill' '../x' 'Ravintio-Ship' '' '-lead'; do
  WS="$(make_workspace)"
  printf -- '---\ntarget: %s\n---\nBAD-MARK text.\n' "$bad" > "$WS/ravintio-overrides/instructions/bad.md"
  OUT="$(run_setup "$WS")"
  assert_equals "1" "$(count BAD-MARK "$WS/CLAUDE.md")" "target '$bad': boot file holds the text"
  assert_contains "Warning" "$OUT" "target '$bad': setup warns"
  assert_equals "0" "$(grep -rlF BAD-MARK "$WS/.claude/skills" 2>/dev/null | wc -l | tr -d ' ')" "target '$bad': no skill holds the text"
done

echo "=== traversal does not write outside the skills dir ==="
WS="$(make_workspace)"
mkdir -p "$WS/.claude/x"; echo "keep" > "$WS/.claude/x/SKILL.md"
printf -- '---\ntarget: ../x\n---\nTRAV-MARK\n' > "$WS/ravintio-overrides/instructions/t.md"
run_setup "$WS" >/dev/null
assert_equals "keep" "$(cat "$WS/.claude/x/SKILL.md")" "the traversal target file is untouched"

echo "=== capability skill target works ==="
WS="$(make_workspace)"
printf -- '---\ntarget: linked-skill\n---\nLINK-MARK\n' > "$WS/ravintio-overrides/instructions/l.md"
mkdir -p "$WS/ravintio-overrides/capability-skills/linked-skill"
printf -- '---\nname: linked-skill\n---\nbody\n' > "$WS/ravintio-overrides/capability-skills/linked-skill/SKILL.md"
run_setup "$WS" >/dev/null
assert_equals "1" "$(count LINK-MARK "$WS/.claude/skills/linked-skill/SKILL.md")" "capability skill receives the block"
assert_equals "0" "$(count LINK-MARK "$WS/CLAUDE.md")" "boot file does not hold it"

echo "=== AC-3: untargeted override unchanged, frontmatter kept ==="
WS="$(make_workspace)"
printf -- '---\ntitle: keep me\n---\nPLAIN-MARK text.\n' > "$WS/ravintio-overrides/instructions/plain.md"
run_setup "$WS" >/dev/null; run_setup "$WS" >/dev/null
assert_equals "1" "$(count PLAIN-MARK "$WS/CLAUDE.md")" "boot file holds the text once"
assert_equals "1" "$(count 'title: keep me' "$WS/CLAUDE.md")" "frontmatter is kept"
assert_equals "0" "$(grep -rlF PLAIN-MARK "$WS/.claude/skills" 2>/dev/null | wc -l | tr -d ' ')" "no skill holds it"

print_summary
