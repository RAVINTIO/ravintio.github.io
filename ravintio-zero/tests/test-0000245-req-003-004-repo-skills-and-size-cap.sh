#!/usr/bin/env bash
# Test: 0000245 req-003 and req-004 repo skills and the boot file size cap
# REQ-003 AC-1: setup installs gutd with its description, and the boot file lacks the GUTD rule.
# REQ-003 AC-2: each retargeted rule appears in its skill, and the boot file keeps only custom-001.
# REQ-004 AC-1: the generated boot file is 6,000 bytes or fewer with this repo's overrides.

set -uo pipefail
unset RAVINTIO_INITIATIVE_STEP
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$ZERO_DIR/.." && pwd)"

WS="$(mktemp -d -t ravintio_0000245_req003_XXXXXX)"
trap 'rm -rf "$WS"' EXIT
cp -r "$ZERO_DIR" "$WS/ravintio-zero"
cp -r "$REPO_ROOT/ravintio-overrides" "$WS/ravintio-overrides"
git init "$WS" >/dev/null 2>&1
(cd "$WS" && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
BOOT="$WS/CLAUDE.md"
SK="$WS/.claude/skills"

echo "=== REQ-003 AC-1: gutd installs ==="
assert_equals "yes" "$([ -f "$SK/gutd/SKILL.md" ] && echo yes || echo no)" "gutd skill installed"
assert_contains "description: Git up to date." "$(cat "$SK/gutd/SKILL.md")" "gutd description intact"
assert_contains "GUTD" "$(grep '^description' "$SK/gutd/SKILL.md")" "description matches the bare token"
assert_equals "yes" "$([ -f "$SK/delete-redundant-branches/SKILL.md" ] && echo yes || echo no)" "branch cleanup skill installed"
assert_equals "0" "$(grep -c 'GUTD' "$BOOT")" "boot file lacks the GUTD rule"
assert_equals "0" "$(grep -c 'Delete redundant local branches' "$BOOT")" "boot file lacks the branch cleanup rule"
assert_equals "no" "$([ -f "$WS/ravintio-overrides/instructions/custom-003-git-up-to-date-shorthand.md" ] && echo yes || echo no)" "custom-003 deleted"
assert_equals "no" "$([ -f "$WS/ravintio-overrides/instructions/custom-005-delete-redundant-local-branches.md" ] && echo yes || echo no)" "custom-005 deleted"

echo "=== REQ-003 AC-2: retargeted rules land in their skills ==="
assert_contains "Prefer Subagent Decomposition" "$(cat "$SK/ravintio-orchestrator/SKILL.md")" "decomposition rule in the orchestrator skill"
assert_contains "Ship: push and raise the PR" "$(cat "$SK/ravintio-ship/SKILL.md")" "ship rule in the ship skill"
assert_contains "Standing approval for the setup refresh" "$(cat "$SK/ravintio-refresh-setup/SKILL.md")" "refresh approval in the refresh skill"
assert_contains "Git Permissions" "$(cat "$BOOT")" "boot file keeps custom-001"
for t in "Prefer Subagent Decomposition" "Ship: push and raise the PR" "Standing approval for the setup refresh"; do
  assert_equals "0" "$(grep -c "$t" "$BOOT")" "boot file lacks: $t"
done

echo "=== REQ-004 AC-1: size cap ==="
SIZE="$(wc -c < "$BOOT" | tr -d ' ')"
if [ "$SIZE" -le 6000 ]; then assert_equals ok ok "boot file is $SIZE bytes (cap 6000)"; else assert_equals ok bad "boot file is $SIZE bytes, cap is 6000"; fi

print_summary
