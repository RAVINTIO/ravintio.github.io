#!/usr/bin/env bash
# Test: 0000239 req-002 stale-install-skip
# stale_install_skip_reason prints a reason and returns 0 only in an active
# initiative whose install manifest is older than the newest pack skill.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# new_root <initiative status or "none"> <manifest age: old|new>
new_root() {
  local root
  root="$(mktemp -d "$TMP/root.XXXXXX")"
  mkdir -p "$root/ravintio-zero/skills/s" "$root/.claude/skills" "$root/plan/current-initiative"
  echo "skill" > "$root/ravintio-zero/skills/s/SKILL.md"
  echo "[]" > "$root/.claude/skills/.ravintio-manifest"
  if [ "$2" = "old" ]; then
    touch -t 202001010000 "$root/.claude/skills/.ravintio-manifest"
    touch -t 202601010000 "$root/ravintio-zero/skills/s/SKILL.md"
  else
    touch -t 202001010000 "$root/ravintio-zero/skills/s/SKILL.md"
    touch -t 202601010000 "$root/.claude/skills/.ravintio-manifest"
  fi
  if [ "$1" != "none" ]; then
    printf -- '---\nstatus: "%s"\n---\n# I\n' "$1" > "$root/plan/current-initiative/initiative.md"
  fi
  echo "$root"
}

echo "=== req-002 AC-1: skip in an active initiative with a stale manifest ==="
R="$(new_root active old)"
OUT="$(stale_install_skip_reason "$R")"; RC=$?
assert_equals "0" "$RC" "returns 0"
assert_contains "manifest is older than the newest pack skill" "$OUT" "prints the reason"

echo "=== req-002 AC-2: no skip outside an active initiative ==="
R="$(new_root none old)"
OUT="$(stale_install_skip_reason "$R")"; RC=$?
assert_equals "1" "$RC" "no initiative file returns 1"
assert_equals "" "$OUT" "no initiative file prints nothing"
R="$(new_root delivered old)"
OUT="$(stale_install_skip_reason "$R")"; RC=$?
assert_equals "1" "$RC" "status delivered returns 1"
assert_equals "" "$OUT" "status delivered prints nothing"

echo "=== req-002 AC-3: no skip with a current manifest ==="
R="$(new_root active new)"
OUT="$(stale_install_skip_reason "$R")"; RC=$?
assert_equals "1" "$RC" "current manifest returns 1"
assert_equals "" "$OUT" "current manifest prints nothing"

echo "=== req-002: section (c) of the req-014 suite uses the helper ==="
SUITE014="$SCRIPT_DIR/test-0000151-req-014-chart-clarity-and-dependency-stop.sh"
assert_contains "stale_install_skip_reason" "$(cat "$SUITE014")" "req-014 calls the helper"
assert_contains "SKIP:" "$(cat "$SUITE014")" "req-014 prints a SKIP line"

print_summary
