#!/usr/bin/env bash
# REGRESSION-CANDIDATE: guards a setup contract that older installs depend on.
# Tests for feature 0000034-setup-hardening, req-003: atomic settings writes.
#
# Covers ADR-002: every settings.json write goes to settings.json.ravintio-tmp
# in the same folder, then renames over the target. A failed write leaves the
# original byte-identical and removes the temporary file. A current-flags run
# writes the same bytes as before.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO_ROOT="$(cd "$ZERO_DIR/.." && pwd)"

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000034_req003_test_XXXXXX)
  cp -r "$1" "$dir/${2:-ravintio-zero}"
  git init "$dir" >/dev/null 2>&1
  echo "$dir"
}

# ── (a): a failed write leaves the original intact and no temporary file ──

echo ""
echo "=== req-003 (a): a failed settings.json write keeps the original ==="

WS=$(make_workspace "$ZERO_DIR")
cd "$WS"
mkdir -p .claude
cat > .claude/settings.json << 'JSON'
{"allowedTools":["Agent","Bash(ls:*)"],"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"./mine.sh"}]}]}}
JSON
ORIGINAL="$(shasum .claude/settings.json | cut -d' ' -f1)"
# A folder at the temporary path makes the exclusive temporary write fail.
# Setup must not delete a folder it didn't create.
mkdir .claude/settings.json.ravintio-tmp
bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1
assert_equals "$ORIGINAL" "$(shasum .claude/settings.json | cut -d' ' -f1)" \
  "req-003 (a): settings.json is byte-identical after the failed write"
assert_equals "dir" "$([ -d .claude/settings.json.ravintio-tmp ] && echo dir || echo other)" \
  "req-003 (a): the failed write leaves no temporary file and keeps the folder it found"
cd /; chmod -R u+w "$WS" 2>/dev/null; rm -rf "$WS"

# ── (b): a normal run writes the same bytes and clears a leftover ─────────

echo ""
echo "=== req-003 (b): a current-flags run writes the same settings.json ==="

WS=$(make_workspace "$ZERO_DIR")
cd "$WS"
mkdir -p .claude
echo "leftover" > .claude/settings.json.ravintio-tmp
bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1
assert_exit_zero "$?" "req-003 (b): setup exits 0 with a leftover temporary file"
assert_equals "no" "$([ -e .claude/settings.json.ravintio-tmp ] && echo yes || echo no)" \
  "req-003 (b): the leftover temporary file is gone after the run"
NEW_SETTINGS="$(cat .claude/settings.json)"
cd /; rm -rf "$WS"

# Compare with the v0.4.0 script when the tag is reachable. A shallow CI
# checkout has no tags, so fall back to the canonical format check.
if git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/v0.4.0" >/dev/null 2>&1; then
  OLD_DIR=$(mktemp -d -t ravintio_0000034_req003_old_XXXXXX)
  # v0.4.0 predates the 0000160 rename, so its pack folder has the old name.
  OLD_PACK="planifest-zero"
  git -C "$REPO_ROOT" archive v0.4.0 "$OLD_PACK" | tar -x -C "$OLD_DIR"
  WS=$(make_workspace "$OLD_DIR/$OLD_PACK" "$OLD_PACK")
  cd "$WS"
  bash "$OLD_PACK/setup.sh" claude-code >/dev/null 2>&1
  OLD_SETTINGS="$(cat .claude/settings.json)"
  cd /; rm -rf "$WS" "$OLD_DIR"
  # merge-guard (0000043 req-006) attribution (0000169 req-004), and the Stop hook (0000200 req-004) postdate v0.4.0, so drop them first.
  NEW_SETTINGS="$(printf '%s' "$NEW_SETTINGS" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const s=JSON.parse(d);s.hooks.PreToolUse=s.hooks.PreToolUse.filter(e=>!JSON.stringify(e).includes("merge-guard"));delete s.attribution;delete s.hooks.Stop;process.stdout.write(JSON.stringify(s,null,2))})')"
  assert_equals "$OLD_SETTINGS" "$NEW_SETTINGS" \
    "req-003 (b): settings.json matches the v0.4.0 script byte for byte"
else
  CANON="$(printf '%s' "$NEW_SETTINGS" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>process.stdout.write(JSON.stringify(JSON.parse(d),null,2)))')"
  assert_equals "$CANON" "$NEW_SETTINGS" \
    "req-003 (b): settings.json keeps the two-space JSON format (no v0.4.0 tag)"
fi

# ── (d): P5 hardening of the temporary write ───────────────────────────────

echo ""
echo "=== req-003 (d): symlinks, mode, and read-only targets ==="

WS=$(make_workspace "$ZERO_DIR")
cd "$WS"
mkdir -p .claude
echo '{"allowedTools":["Agent"]}' > .claude/settings.json
echo "victim" > ../victim-$$.txt
ln -s "../../victim-$$.txt" .claude/settings.json.ravintio-tmp
chmod 600 .claude/settings.json
bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1
assert_equals "victim" "$(cat ../victim-$$.txt)" \
  "req-003 (d): a symlink at the temporary path is never followed"
assert_equals "no" "$([ -L .claude/settings.json ] && echo yes || echo no)" \
  "req-003 (d): settings.json is a regular file, not the planted link"
# GNU stat takes -c. BSD stat takes -f, which GNU reads as a file system query.
MODE="$(stat -c '%a' .claude/settings.json 2>/dev/null || stat -f '%Lp' .claude/settings.json)"
assert_equals "600" "$MODE" "req-003 (d): settings.json keeps its 600 mode"
rm -f ../victim-$$.txt
cd /; rm -rf "$WS"

WS=$(make_workspace "$ZERO_DIR")
cd "$WS"
mkdir -p .claude dotfiles
echo '{}' > dotfiles/settings.json
ln -s ../dotfiles/settings.json .claude/settings.json
bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1
assert_equals "yes" "$([ -L .claude/settings.json ] && echo yes || echo no)" \
  "req-003 (d): a symlinked settings.json stays a symlink"
assert_contains "gate-write" "$(cat dotfiles/settings.json)" \
  "req-003 (d): setup writes through the symlink to its real file"
cd /; rm -rf "$WS"

WS=$(make_workspace "$ZERO_DIR")
cd "$WS"
mkdir -p .claude
echo '{"allowedTools":["Agent"]}' > .claude/settings.json
chmod 444 .claude/settings.json
ORIGINAL="$(shasum .claude/settings.json | cut -d' ' -f1)"
bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1
assert_equals "$ORIGINAL" "$(shasum .claude/settings.json | cut -d' ' -f1)" \
  "req-003 (d): a read-only settings.json stays unchanged"
cd /; chmod -R u+w "$WS" 2>/dev/null; rm -rf "$WS"

# ── (c): no settings.json write goes straight to the target ───────────────

echo ""
echo "=== req-003 (c): every settings.json write uses the temporary file ==="

SH="$ZERO_DIR/setup.sh"
PS1="$ZERO_DIR/setup.ps1"
assert_equals "0" "$(grep -c 'writeFileSync(sf' "$SH" || true)" \
  "req-003 (c): setup.sh has no direct writeFileSync to settings.json"
assert_equals "yes" "$(grep -q 'renameSync' "$SH" && echo yes || echo no)" \
  "req-003 (c): setup.sh renames the temporary file over settings.json"
assert_equals "0" "$(grep -E 'ConvertTo-Json.*Set-Content -Path \$(SettingsPath|settings)' "$PS1" | wc -l | tr -d ' ')" \
  "req-003 (c): setup.ps1 has no direct Set-Content to settings.json"
assert_equals "yes" "$(grep -q 'ravintio-tmp' "$PS1" && grep -q 'Move-Item' "$PS1" && echo yes || echo no)" \
  "req-003 (c): setup.ps1 moves a ravintio-tmp file over settings.json"
assert_equals "yes" "$(grep -q '\[System.IO.File\]::Replace(\$tmp, \$full' "$PS1" && echo yes || echo no)" \
  "req-003 (c): setup.ps1 swaps an existing settings.json with File.Replace"
assert_equals "0" "$(grep -c 'Move-Item .*-Force' "$PS1" || true)" \
  "req-003 (c): setup.ps1 never uses Move-Item -Force, which deletes the target first"
assert_equals "yes" "$(grep -q 'IsReadOnly' "$PS1" && grep -q 'Remove-SettingsTmpEntry -Tmp \$tmp' "$PS1" && echo yes || echo no)" \
  "req-003 (c): setup.ps1 refuses a read-only target and clears a leftover first"

print_summary
