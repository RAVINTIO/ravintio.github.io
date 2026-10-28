#!/usr/bin/env bash
# Tests for boot-file regeneration and boot-file cleanliness.
#
# req-001: write_boot_file/Write-RavintioBootFile always overwrite the boot
#          file from the current template (skip-if-exists guard removed), with
#          ravintio-overrides/instructions/ content re-applied every run.
# req-002: templates/standard-boot.md carries no retired-MCP reference;
#          generated boot files carry none; the retired opt-in flag
#          hook-install path is untouched.
# req-003: ravintio-overrides/instructions/custom-001-local-git-only.md
#          (repo-local config, not distributed source) authorizes pull/push/PR
#          creation and names commits-to-main and PR-merge as human-only.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO_ROOT="$(cd "$ZERO_DIR/.." && pwd)"

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
grep_has() { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }
grep_count() { local c; c=$(grep -ci "$1" "$2" 2>/dev/null || true); echo "${c:-0}"; }
fn_has() {
  # grep inside one shell/PowerShell function body only (start pattern to closing brace)
  sed -n "/$1/,/^}/p" "$3" | grep -q "$2" && echo "yes" || echo "no"
}

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000029_test_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

# ── (a) req-001: fresh workspace, boot file created ─────────────────────────

echo ""
echo "=== (a) req-001: setup.sh claude-code creates CLAUDE.md on fresh workspace ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-zero/setup.sh claude-code >/tmp/ravintio_0000029_a.log 2>&1
assert_exit_zero "$?" "(a): setup.sh claude-code exits 0 on fresh workspace"
assert_equals "yes" "$(file_exists "CLAUDE.md")" "(a): CLAUDE.md created"

# ── (b) req-001: rerun regenerates, hand-edit is replaced ───────────────────

echo ""
echo "=== (b) req-001: rerun overwrites an existing CLAUDE.md (no skip-if-exists) ==="

echo "SENTINEL-HAND-EDIT-0000029" >> CLAUDE.md
bash ravintio-zero/setup.sh claude-code >/tmp/ravintio_0000029_b.log 2>&1
assert_exit_zero "$?" "(b): rerun exits 0"
assert_equals "no" "$(grep_has "SENTINEL-HAND-EDIT-0000029" "CLAUDE.md")" \
  "(b): hand-edited sentinel is gone after rerun (file regenerated)"

# ── (c) req-001: override instructions re-applied on every run ──────────────

echo ""
echo "=== (c) req-001: ravintio-overrides/instructions/ content present after rerun ==="

mkdir -p ravintio-overrides/instructions
printf '### Test Override\nOVERRIDE-MARKER-0000029\n' > ravintio-overrides/instructions/custom-900-test.md
bash ravintio-zero/setup.sh claude-code >/tmp/ravintio_0000029_c.log 2>&1
assert_exit_zero "$?" "(c): rerun with overrides exits 0"
assert_equals "yes" "$(grep_has "OVERRIDE-MARKER-0000029" "CLAUDE.md")" \
  "(c): override content re-applied into regenerated CLAUDE.md"

# ── (d) req-001: setup.ps1 parity (static) ──────────────────────────────────

echo ""
echo "=== (d) req-001: Write-RavintioBootFile has no skip-if-exists branch ==="

assert_equals "no" "$(fn_has "^function Write-RavintioBootFile" "skipped" "$ZERO_DIR/setup.ps1")" \
  "(d): Write-RavintioBootFile no longer has a skip branch (function-scoped check)"
assert_equals "no" "$(fn_has "^write_boot_file()" "skipped" "$ZERO_DIR/setup.sh")" \
  "(d): write_boot_file no longer has a skip branch (function-scoped check)"

# ── (e) req-002: standard-boot.md carries no retired-MCP reference ─────────

echo ""
echo "=== (e) req-002: templates/standard-boot.md is free of the retired MCP ==="

BOOT_TEMPLATE="$ZERO_DIR/templates/standard-boot.md"
RETIRED_MCP="context""-mode"
assert_equals "0" "$(grep_count "$RETIRED_MCP" "$BOOT_TEMPLATE")" \
  "(e): zero retired-MCP occurrences in standard-boot.md"
assert_equals "0" "$(grep_count "ctx_batch_execute" "$BOOT_TEMPLATE")" \
  "(e): zero 'ctx_batch_execute' occurrences in standard-boot.md"

# ── (f) req-002: generated boot file carries no retired-MCP reference ──────

echo ""
echo "=== (f) req-002: regenerated CLAUDE.md is free of the retired MCP ==="

assert_equals "0" "$(grep_count "$RETIRED_MCP" "$WS/CLAUDE.md")" \
  "(f): zero retired-MCP occurrences in generated CLAUDE.md"

# ── (h) req-003: repo-local git-permission override wording ─────────────────

echo ""
echo "=== (h) req-003: custom-001 override authorizes pull/push/PR-create ==="

OVERRIDE_FILE="$REPO_ROOT/ravintio-overrides/instructions/custom-001-local-git-only.md"
assert_equals "no" "$(grep_has "pull, push or otherwise attempt" "$OVERRIDE_FILE")" \
  "(h): old 'don't fetch, pull, push' wording removed"
assert_equals "yes" "$(grep_has "gh pr create" "$OVERRIDE_FILE")" \
  "(h): PR creation via gh pr create named as authorized"
assert_equals "yes" "$(grep_has "human-only" "$OVERRIDE_FILE")" \
  "(h): human-only actions named"
assert_equals "yes" "$(grep_count "main" "$OVERRIDE_FILE" | grep -q "^0$" && echo no || echo yes)" \
  "(h): commits to main addressed in the wording"

cd "$SCRIPT_DIR"
print_summary
