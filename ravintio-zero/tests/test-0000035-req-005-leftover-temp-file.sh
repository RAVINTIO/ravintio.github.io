#!/usr/bin/env bash
# Tests for feature 0000035-powershell-setup-parity, req-005: leftover
# temporary file.
#
# Both setup scripts remove .claude/settings.json.ravintio-tmp early in each
# run (ADR-003, backlog 0000104). The removal never follows a link and never
# removes a folder, and setup.sh needs no node for it.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
LEFTOVER=".claude/settings.json.ravintio-tmp"

# Runs only remove_leftover_settings_tmp from setup.sh, with the given PATH.
run_removal() {
  local root="$1" path="$2"
  local fn
  fn="$(sed -n '/^remove_leftover_settings_tmp() {/,/^}/p' "$ZERO_DIR/setup.sh")"
  PATH="$path" PROJECT_ROOT="$root" /bin/bash -c "
    $fn
    remove_leftover_settings_tmp .claude/settings.json
  " 2>&1
}

NO_NODE_PATH="$(mktemp -d -t ravintio_0000035_req005_bin_XXXXXX)"
for tool in rm mkdir cat; do
  src="$(command -v "$tool" 2>/dev/null)" && ln -s "$src" "$NO_NODE_PATH/$tool"
done

echo ""
echo "=== req-005 (a): a setup.sh run removes a planted leftover ==="

WS=$(mktemp -d -t ravintio_0000035_req005_test_XXXXXX)
cp -r "$ZERO_DIR" "$WS/ravintio-zero"
git init "$WS" >/dev/null 2>&1
mkdir -p "$WS/.claude"
echo 'partial' > "$WS/$LEFTOVER"
(cd "$WS" && bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1)
assert_exit_zero $? "req-005 (a): setup exits 0"
assert_equals "no" "$([ -e "$WS/$LEFTOVER" ] && echo yes || echo no)" \
  "req-005 (a): no leftover remains after the run"
rm -rf "$WS"

echo ""
echo "=== req-005 (b): the removal needs no node and prints nothing ==="

WS=$(mktemp -d -t ravintio_0000035_req005_test_XXXXXX)
mkdir -p "$WS/.claude"
echo 'partial' > "$WS/$LEFTOVER"
OUT="$(run_removal "$WS" "$NO_NODE_PATH")"
assert_equals "no" "$([ -e "$WS/$LEFTOVER" ] && echo yes || echo no)" \
  "req-005 (b): the leftover goes with node hidden from the PATH"
assert_equals "" "$OUT" "req-005 (b): the removal prints nothing"
OUT="$(run_removal "$WS" "$NO_NODE_PATH")"
assert_equals "" "$OUT" "req-005 (b): with no leftover, the removal prints nothing"
rm -rf "$WS"

echo ""
echo "=== req-005 (c): a link goes and its target stays, a folder stays ==="

WS=$(mktemp -d -t ravintio_0000035_req005_test_XXXXXX)
OUTSIDE=$(mktemp -t ravintio_0000035_req005_target_XXXXXX)
echo 'keep me' > "$OUTSIDE"
mkdir -p "$WS/.claude"
ln -s "$OUTSIDE" "$WS/$LEFTOVER"
run_removal "$WS" "$NO_NODE_PATH" >/dev/null
assert_equals "no" "$([ -L "$WS/$LEFTOVER" ] && echo yes || echo no)" \
  "req-005 (c): a planted link is removed"
assert_equals "keep me" "$(cat "$OUTSIDE")" "req-005 (c): the link target is unchanged"
mkdir "$WS/$LEFTOVER"
run_removal "$WS" "$NO_NODE_PATH" >/dev/null
assert_equals "yes" "$([ -d "$WS/$LEFTOVER" ] && echo yes || echo no)" \
  "req-005 (c): a folder at the temporary path is left alone"
rm -rf "$WS" "$OUTSIDE"
rm -rf "$NO_NODE_PATH"

echo ""
echo "=== req-005 (d): setup.ps1 removes the leftover before its first settings write ==="

SETUP_BODY="$(awk '/^function Invoke-RavintioSetup/{f=1} f && /^function / && !/Invoke-RavintioSetup/{exit} f{print}' "$ZERO_DIR/setup.ps1")"
REMOVE_LINE="$(printf '%s\n' "$SETUP_BODY" | grep -n 'Remove-LeftoverSettingsTmp -SettingsRel' | head -1 | cut -d: -f1)"
WRITER_LINE="$(printf '%s\n' "$SETUP_BODY" | grep -n 'Install-EnforcementHooks' | head -1 | cut -d: -f1)"
assert_equals "yes" "$([ -n "$REMOVE_LINE" ] && [ -n "$WRITER_LINE" ] && [ "$REMOVE_LINE" -lt "$WRITER_LINE" ] && echo yes || echo no)" \
  "req-005 (d): Remove-LeftoverSettingsTmp runs before the first settings writer"
# The removal itself lives in Remove-SettingsTmpEntry, shared with
# Write-SettingsAtomic (P5 S-002, S-003).
REMOVER="$(awk '/^function Remove-LeftoverSettingsTmp/{f=1} f && /^}/{print; exit} f{print}' "$ZERO_DIR/setup.ps1")"
HELPER="$(awk '/^function Remove-SettingsTmpEntry/{f=1} f && /^}/{print; exit} f{print}' "$ZERO_DIR/setup.ps1")"
assert_contains "Remove-SettingsTmpEntry" "$REMOVER" "req-005 (d): setup.ps1 removes the leftover through the shared helper"
assert_contains "elseif (-not \$isFolder)" "$HELPER" "req-005 (d): setup.ps1 leaves a folder alone"
assert_contains "ReparsePoint" "$HELPER" "req-005 (d): setup.ps1 removes a link without following it"

print_summary
