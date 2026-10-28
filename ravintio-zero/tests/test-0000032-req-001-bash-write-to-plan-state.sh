#!/usr/bin/env bash
# Tests for feature 0000032-relocate-setup-config-to-plan-state, req-001:
# bash write to plan/state.
#
# Covers ADR-001 (setup-config record lives in plan/state/): setup.sh's
# write_setup_config_override writes plan/state/{tool}.md as the tracked,
# git-versioned source of truth for the active setup flags, in
# addition to (not instead of) the existing gitignored
# {tool-dir}/.ravintio-setup-flags marker. The marker continues to be
# written and its flags must match the tracked file's for the
# same run (ADR-001 decision 5 — both are regenerated from the same
# current-run values, so they never disagree coming out of a single setup
# run).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."

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

# Reads a field from the tracked plan/state/{tool}.md file's fenced
# ```json block — the same tool/flags/writtenAt shape as the marker (req-001).
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
  dir=$(mktemp -d -t ravintio_0000032_req001_test_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  echo "$dir"
}

# ── (a): first-run/bootstrap — no plan/state/ yet ───────────────────────────

echo ""
echo "=== req-001 (a): setup.sh claude-code (no flags) bootstraps plan/state/ ==="

WS=$(make_workspace); cd "$WS"
assert_equals "no" "$(dir_exists "plan/state")" \
  "req-001 (a): plan/state/ does not exist before setup runs"

RUN_OUTPUT="$(bash ravintio-zero/setup.sh claude-code 2>&1)"
assert_exit_zero $? "req-001 (a): setup exits 0 on first run with no pre-existing plan/state/"

assert_equals "yes" "$(dir_exists "plan/state")" \
  "req-001 (a): plan/state/ created by setup"

assert_equals "yes" "$(file_exists "plan/state/claude-code.md")" \
  "req-001 (a): tracked per-tool record created for claude-code"

assert_contains "plan/state/claude-code.md" "$RUN_OUTPUT" \
  "req-001 (a): setup prints a line naming the new path"

assert_equals "yes" "$(file_exists ".claude/.ravintio-setup-flags")" \
  "req-001 (a): existing gitignored marker is still written (additive, not replaced)"

assert_equals '"claude-code"' "$(read_config_field "plan/state/claude-code.md" "tool")" \
  "req-001 (a): tracked file records tool name"

assert_equals "[]" "$(read_config_field "plan/state/claude-code.md" "flags")" \
  "req-001 (a): tracked file flags empty when no flags passed"

assert_equals "no" "$(config_has_key "plan/state/claude-code.md" "backendUrl")" \
  "req-001 (a): tracked file carries no backendUrl key at all (ADR-001 dec 6)"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (b): flags match between tracked file and marker ────────────────────────

echo ""
echo "=== req-001 (b): setup.sh claude-code with flags — tracked file and marker agree ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-zero/setup.sh claude-code --strict-orchestrator >/dev/null 2>&1
assert_exit_zero $? "req-001 (b): setup exits 0 with all flags"

CONFIG_FLAGS="$(read_config_field "plan/state/claude-code.md" "flags")"
MARKER_FLAGS="$(read_marker_field ".claude/.ravintio-setup-flags" "flags")"

assert_contains "--strict-orchestrator" "$CONFIG_FLAGS" "req-001 (b): tracked file records --strict-orchestrator"

assert_equals "$MARKER_FLAGS" "$CONFIG_FLAGS" \
  "req-001 (b): tracked file flags match marker flags for the same run"

assert_equals "no" "$(config_has_key "plan/state/claude-code.md" "backendUrl")" \
  "req-001 (b): tracked file carries no backendUrl key even on a flagged run (ADR-001 dec 6)"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (c): a second run changes only writtenAt, and the file is not gitignored ─

echo ""
echo "=== req-001 (c): second run changes only writtenAt; plan/state/claude-code.md is not gitignored ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1

FIRST_TOOL="$(read_config_field "plan/state/claude-code.md" "tool")"
FIRST_FLAGS="$(read_config_field "plan/state/claude-code.md" "flags")"
FIRST_HAS_URL="$(config_has_key "plan/state/claude-code.md" "backendUrl")"
FIRST_WRITTEN_AT="$(read_config_field "plan/state/claude-code.md" "writtenAt")"

sleep 1

bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1
assert_exit_zero $? "req-001 (c): second setup run exits 0"

SECOND_TOOL="$(read_config_field "plan/state/claude-code.md" "tool")"
SECOND_FLAGS="$(read_config_field "plan/state/claude-code.md" "flags")"
SECOND_HAS_URL="$(config_has_key "plan/state/claude-code.md" "backendUrl")"
SECOND_WRITTEN_AT="$(read_config_field "plan/state/claude-code.md" "writtenAt")"

assert_equals "$FIRST_TOOL" "$SECOND_TOOL" \
  "req-001 (c): second run keeps the same tool field"
assert_equals "$FIRST_FLAGS" "$SECOND_FLAGS" \
  "req-001 (c): second run keeps the same flags field"
assert_equals "no" "$FIRST_HAS_URL" \
  "req-001 (c): first run writes no backendUrl key at all (ADR-001 dec 6)"
assert_equals "$FIRST_HAS_URL" "$SECOND_HAS_URL" \
  "req-001 (c): second run still writes no backendUrl key"

if [ "$FIRST_WRITTEN_AT" != "$SECOND_WRITTEN_AT" ]; then
  WRITTEN_AT_CHANGED="yes"
else
  WRITTEN_AT_CHANGED="no"
fi
assert_equals "yes" "$WRITTEN_AT_CHANGED" \
  "req-001 (c): second run changes the writtenAt field"

if git check-ignore -q "plan/state/claude-code.md" 2>/dev/null; then
  IGNORED="yes"
else
  IGNORED="no"
fi
assert_equals "no" "$IGNORED" \
  "req-001 (c): tracked config file is not matched by any .gitignore rule"

STATUS_LINE="$(git status --porcelain -- plan/state/claude-code.md 2>/dev/null)"
assert_contains "plan/state/claude-code.md" "$STATUS_LINE" \
  "req-001 (c): tracked config file appears as trackable/committable in git status"

cd "$SCRIPT_DIR"
rm -rf "$WS"

# ── (d): write failure falls back to marker-only behavior, does not abort ───

echo ""
echo "=== req-001 (d): setup.sh still completes if plan/state/ can't be written ==="

if [ "$(id -u)" = "0" ]; then
  echo "  SKIP: running as root — permission-based failure case cannot be exercised"
else
  WS=$(make_workspace); cd "$WS"
  mkdir -p "plan"
  # Pre-seed the files setup.sh writes only when absent, so the read-only
  # plan/ below blocks just the plan/state/ write this test targets.
  touch "plan/README.md" "plan/feature-structure.md"
  chmod 555 "plan"

  RUN_OUTPUT="$(bash ravintio-zero/setup.sh claude-code 2>&1)"
  FALLBACK_EXIT=$?
  chmod 755 "plan"

  assert_exit_zero "$FALLBACK_EXIT" \
    "req-001 (d): setup exits 0 even when plan/state/ cannot be created"

  ONE_WARNING_COUNT="$(printf '%s\n' "$RUN_OUTPUT" | grep -c "plan/state/")"
  assert_equals "1" "$ONE_WARNING_COUNT" \
    "req-001 (d): setup prints exactly one warning naming plan/state/"

  assert_equals "yes" "$(file_exists ".claude/.ravintio-setup-flags")" \
    "req-001 (d): marker still written when the tracked-file write fails (fallback behavior)"

  assert_equals "no" "$(file_exists "plan/state/claude-code.md")" \
    "req-001 (d): tracked config file was not created when its directory couldn't be written"

  cd "$SCRIPT_DIR"
  rm -rf "$WS"
fi

print_summary
