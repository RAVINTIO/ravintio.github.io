#!/usr/bin/env bash
# Tests for feature 0000032-relocate-setup-config-to-plan-state, req-003:
# inline cleanup of the old record.
#
# Covers ADR-003 (setup removes the old record inline): after a successful
# write_setup_config_override (bash) / Write-SetupConfigOverride (PowerShell)
# writes plan/state/{tool}.md, setup.sh/setup.ps1 delete the stale
# ravintio-overrides/setup-config/{tool}.md at its exact path, and remove
# ravintio-overrides/setup-config/ if it is then empty.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
dir_exists() { [ -d "$1" ] && echo "yes" || echo "no"; }

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000032_req003_test_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

# ── (a): old file present, folder held only that file — both gone ──────────

echo ""
echo "=== req-003 (a): old file present, folder held only that file ==="

WS=$(make_workspace); cd "$WS"
mkdir -p "ravintio-overrides/setup-config"
echo "stale" > "ravintio-overrides/setup-config/claude-code.md"

RUN_OUTPUT="$(bash ravintio-zero/setup.sh claude-code 2>&1)"
assert_exit_zero $? "req-003 (a): setup exits 0 after removing the old file and folder"

assert_equals "no" "$(file_exists "ravintio-overrides/setup-config/claude-code.md")" \
  "req-003 (a): old file is gone"

assert_equals "yes" "$(file_exists "plan/state/claude-code.md")" \
  "req-003 (a): plan/state/claude-code.md exists"

assert_contains "ravintio-overrides/setup-config/claude-code.md" "$RUN_OUTPUT" \
  "req-003 (a): setup prints a line naming the removed old file"

assert_equals "no" "$(dir_exists "ravintio-overrides/setup-config")" \
  "req-003 (a): now-empty setup-config folder is removed"

assert_contains "ravintio-overrides/setup-config" "$RUN_OUTPUT" \
  "req-003 (a): setup prints a line naming the removed folder"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (b): folder holds another file — file removed, folder and other file stay ─

echo ""
echo "=== req-003 (b): folder holds another file — folder and that file remain ==="

WS=$(make_workspace); cd "$WS"
mkdir -p "ravintio-overrides/setup-config"
echo "stale" > "ravintio-overrides/setup-config/claude-code.md"
echo "keep me" > "ravintio-overrides/setup-config/other-tool.md"

RUN_OUTPUT="$(bash ravintio-zero/setup.sh claude-code 2>&1)"
assert_exit_zero $? "req-003 (b): setup exits 0"

assert_equals "no" "$(file_exists "ravintio-overrides/setup-config/claude-code.md")" \
  "req-003 (b): old claude-code.md is gone"

assert_equals "yes" "$(dir_exists "ravintio-overrides/setup-config")" \
  "req-003 (b): setup-config folder remains (still holds another file)"

assert_equals "yes" "$(file_exists "ravintio-overrides/setup-config/other-tool.md")" \
  "req-003 (b): other-tool.md is untouched"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (c): nothing to remove — silent, exit 0 ─────────────────────────────────

echo ""
echo "=== req-003 (c): no old file or folder exists ==="

WS=$(make_workspace); cd "$WS"

RUN_OUTPUT="$(bash ravintio-zero/setup.sh claude-code 2>&1)"
assert_exit_zero $? "req-003 (c): setup exits 0 with no old folder present"

REMOVAL_LINES="$(printf '%s\n' "$RUN_OUTPUT" | grep -c "removed ravintio-overrides/setup-config" || true)"
assert_equals "0" "$REMOVAL_LINES" \
  "req-003 (c): setup prints no removal line when nothing existed to remove"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (d): second run against a migrated repo — silent, exit 0 ───────────────

echo ""
echo "=== req-003 (d): second run against an already-migrated repo prints no removal line ==="

WS=$(make_workspace); cd "$WS"
mkdir -p "ravintio-overrides/setup-config"
echo "stale" > "ravintio-overrides/setup-config/claude-code.md"

bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1

RUN_OUTPUT="$(bash ravintio-zero/setup.sh claude-code 2>&1)"
assert_exit_zero $? "req-003 (d): second run exits 0"

REMOVAL_LINES="$(printf '%s\n' "$RUN_OUTPUT" | grep -c "removed ravintio-overrides/setup-config" || true)"
assert_equals "0" "$REMOVAL_LINES" \
  "req-003 (d): second run prints no removal line (already migrated)"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (e): old file cannot be removed (read-only folder) — one warning, exit 0 ─

echo ""
echo "=== req-003 (e): read-only setup-config folder — one warning, exit 0 ==="

if [ "$(id -u)" = "0" ]; then
  echo "  SKIP: running as root — permission-based failure case cannot be exercised"
else
  WS=$(make_workspace); cd "$WS"
  mkdir -p "ravintio-overrides/setup-config"
  echo "stale" > "ravintio-overrides/setup-config/claude-code.md"
  chmod 555 "ravintio-overrides/setup-config"

  RUN_OUTPUT="$(bash ravintio-zero/setup.sh claude-code 2>&1)"
  RUN_EXIT=$?
  chmod 755 "ravintio-overrides/setup-config"

  assert_exit_zero "$RUN_EXIT" \
    "req-003 (e): setup exits 0 even when the old file cannot be removed"

  WARNING_COUNT="$(printf '%s\n' "$RUN_OUTPUT" | grep -c "ravintio-overrides/setup-config/claude-code.md")"
  assert_equals "1" "$WARNING_COUNT" \
    "req-003 (e): setup prints exactly one warning naming the old file path"

  assert_equals "yes" "$(file_exists "plan/state/claude-code.md")" \
    "req-003 (e): plan/state/claude-code.md was still written"

  cd "$SCRIPT_DIR"
  rm -rf "$WS"
fi

# ── (f): static check — setup.ps1 removes the old path and emptied parent ──

echo ""
echo "=== req-003 (f): static check — setup.ps1 references removal of the legacy path ==="

PS1_CONTENT="$(cat "$ZERO_DIR/setup.ps1")"

assert_contains 'ravintio-overrides\setup-config' "$PS1_CONTENT" \
  "req-003 (f): setup.ps1 references the legacy ravintio-overrides\\setup-config path"

assert_contains 'Remove-Item' "$PS1_CONTENT" \
  "req-003 (f): setup.ps1 uses Remove-Item for the removal"

print_summary
