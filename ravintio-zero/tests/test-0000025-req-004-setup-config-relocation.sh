#!/usr/bin/env bash
# Tests for feature 0000025-pipeline-gate-and-config-fixes-and-ship-agent-fixes,
# req-004: setup config relocation.
#
# The tracked record's path moved under 0000032 ADR-001: setup.sh now writes
# plan/state/{tool}.md instead of ravintio-overrides/setup-config/{tool}.md
# (0000032 req-001). This suite's bash-side assertions (a)-(e) target the new
# path. setup.sh's write logic itself is covered in depth by
# test-0000032-req-001-bash-write-to-plan-state.sh; setup.ps1 has not moved yet
# (0000032 req-002 is a separate requirement), so case (f) still checks the
# setup.ps1 writer at the original ravintio-overrides/setup-config/ path.
#
# Originally covered ADR-002 (setup config overrides precedence): setup.sh/
# setup.ps1 write the tracked, git-versioned source of truth for the active
# setup flags, in addition to (not instead of) the existing gitignored
# {tool-dir}/.ravintio-setup-flags marker. The marker continues to be written
# and its flags must match the tracked file's for the same run
# (ADR-002 decision 3, carried forward by 0000032 ADR-001 decision 5 — both are
# regenerated from the same current-run values, so they never disagree coming
# out of a single setup run).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SETUP_PS1="$ZERO_DIR/setup.ps1"

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
dir_exists() { [ -d "$1" ] && echo "yes" || echo "no"; }

# Reads a field from the gitignored JSON marker file.
read_marker_field() {
  local file="$1"
  local field="$2"
  node -e '
    const fs = require("fs");
    const j = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const v = j[process.argv[2]];
    console.log(v === undefined || v === null ? "null" : JSON.stringify(v));
  ' "$file" "$field" 2>/dev/null
}

# Reads a field from the tracked plan/state/{tool}.md file's fenced ```json
# block — the same tool/flags/writtenAt shape as the marker (req-004).
read_config_field() {
  local file="$1"
  local field="$2"
  awk '/^```json$/{flag=1; next} /^```$/{flag=0} flag' "$file" | node -e '
    let d = "";
    process.stdin.on("data", (c) => (d += c));
    process.stdin.on("end", () => {
      const j = JSON.parse(d);
      const v = j[process.argv[1]];
      console.log(v === undefined || v === null ? "null" : JSON.stringify(v));
    });
  ' "$field" 2>/dev/null
}

# Reports whether the tracked record's json block holds the named key at all.
# read_config_field cannot tell an absent key from a null one — both print
# "null" — so absence assertions use this instead (ADR-001 decision 6 drops
# backendUrl entirely, and the key must not be present).
config_has_key() {
  local file="$1"
  local field="$2"
  awk '/^```json$/{flag=1; next} /^```$/{flag=0} flag' "$file" | node -e '
    let d = "";
    process.stdin.on("data", (c) => (d += c));
    process.stdin.on("end", () => {
      const j = JSON.parse(d);
      console.log(Object.prototype.hasOwnProperty.call(j, process.argv[1]) ? "yes" : "no");
    });
  ' "$field" 2>/dev/null
}

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000025_req004_test_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

# ── (a): first-run/bootstrap — no plan/state/ yet ───────────────────────────

echo ""
echo "=== (a): setup.sh claude-code (no flags) bootstraps plan/state/ ==="

WS=$(make_workspace); cd "$WS"
assert_equals "no" "$(dir_exists "plan/state")" \
  "(a): plan/state/ does not exist before setup runs"

bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1
assert_exit_zero $? "(a): setup exits 0 on first run with no pre-existing setup-config dir"

assert_equals "yes" "$(dir_exists "plan/state")" \
  "(a): plan/state/ created by setup"

assert_equals "yes" "$(file_exists "plan/state/claude-code.md")" \
  "(a): tracked per-tool config file created for claude-code"

assert_equals "yes" "$(file_exists ".claude/.ravintio-setup-flags")" \
  "(a): existing gitignored marker is still written (additive, not replaced)"

assert_equals '"claude-code"' "$(read_config_field "plan/state/claude-code.md" "tool")" \
  "(a): tracked file records tool name"

assert_equals "[]" "$(read_config_field "plan/state/claude-code.md" "flags")" \
  "(a): tracked file flags empty when no flags passed"

assert_equals "no" "$(config_has_key "plan/state/claude-code.md" "backendUrl")" \
  "(a): tracked file carries no backendUrl key at all (ADR-001 dec 6)"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (b): flags match between tracked file and marker ────────────────────────

echo ""
echo "=== (b): setup.sh claude-code with flags — tracked file and marker agree ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-zero/setup.sh claude-code --strict-orchestrator >/dev/null 2>&1
assert_exit_zero $? "(b): setup exits 0 with all flags"

CONFIG_FLAGS="$(read_config_field "plan/state/claude-code.md" "flags")"
MARKER_FLAGS="$(read_marker_field ".claude/.ravintio-setup-flags" "flags")"

assert_contains "--strict-orchestrator" "$CONFIG_FLAGS" "(b): tracked file records --strict-orchestrator"

assert_equals "$MARKER_FLAGS" "$CONFIG_FLAGS" \
  "(b): tracked file flags match marker flags for the same run"

assert_equals "no" "$(config_has_key "plan/state/claude-code.md" "backendUrl")" \
  "(b): tracked file carries no backendUrl key even on a flagged run (ADR-001 dec 6)"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (c): tracked file is not gitignored — shows up as trackable in git ──────

echo ""
echo "=== (c): plan/state/claude-code.md is not gitignored ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1

if git check-ignore -q "plan/state/claude-code.md" 2>/dev/null; then
  IGNORED="yes"
else
  IGNORED="no"
fi
assert_equals "no" "$IGNORED" \
  "(c): tracked config file is not matched by any .gitignore rule"

STATUS_LINE="$(git status --porcelain -- plan/state/claude-code.md 2>/dev/null)"
assert_contains "plan/state/claude-code.md" "$STATUS_LINE" \
  "(c): tracked config file appears as trackable/committable in git status"

STATUS_MARKER_LINE="$(git status --porcelain -- .claude/.ravintio-setup-flags 2>/dev/null)"
assert_equals "" "$STATUS_MARKER_LINE" \
  "(c): gitignored marker does not appear in git status (unlike the tracked file)"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (e): write failure falls back to marker-only behavior, does not abort ───

echo ""
echo "=== (e): setup.sh still completes if plan/state/ can't be written ==="

if [ "$(id -u)" = "0" ]; then
  echo "  SKIP: running as root — permission-based failure case cannot be exercised"
else
  WS=$(make_workspace); cd "$WS"
  mkdir -p "plan"
  # Pre-seed the files setup.sh writes only when absent, so the read-only
  # plan/ below blocks just the plan/state/ write this test targets.
  touch "plan/README.md" "plan/feature-structure.md"
  chmod 555 "plan"

  bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1
  FALLBACK_EXIT=$?
  chmod 755 "plan"

  assert_exit_zero "$FALLBACK_EXIT" \
    "(e): setup exits 0 even when plan/state/ cannot be created"

  assert_equals "yes" "$(file_exists ".claude/.ravintio-setup-flags")" \
    "(e): marker still written when the tracked-file write fails (fallback behavior)"

  assert_equals "no" "$(file_exists "plan/state/claude-code.md")" \
    "(e): tracked config file was not created when its directory couldn't be written"

  cd "$SCRIPT_DIR"
  rm -rf "$WS"
fi

# ── (f): setup.ps1 defines the same tracked-config-write logic (static check) ─
# A live pwsh invocation is not run here; this environment has no PowerShell
# runtime available (same constraint as test-0000020-req-008).

echo ""
echo "=== (f): setup.ps1 defines the matching tracked setup-config writer ==="

grep_has() { grep -q "$1" "$2" 2>/dev/null && echo "yes" || echo "no"; }

assert_equals "yes" "$(grep_has 'function Write-SetupConfigOverride' "$SETUP_PS1")" \
  "(f): setup.ps1 defines Write-SetupConfigOverride"

assert_equals "yes" "$(grep_has "plan.state" "$SETUP_PS1")" \
  "(f): setup.ps1 references the plan\\state directory"

assert_equals "yes" "$(grep_has 'Write-SetupConfigOverride -ToolName \$ToolName' "$SETUP_PS1")" \
  "(f): setup.ps1 calls the tracked-config writer from inside Invoke-RavintioSetup"

print_summary
