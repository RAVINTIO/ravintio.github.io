#!/usr/bin/env bash
# Tests for feature 0000037-self-host-on-planifest-zero, req-003:
# setup record move.
#
# Covers ADR-001 decision 3. The repo keeps its setup record at
# plan/state/claude-code.md, in the layout setup.sh writes. The record has
# the setup flags the human chose and no backendUrl. The old ravintio-overrides/
# setup-config/ folder is gone. The suite runs setup.sh only in a temporary
# copy and checks that the real working tree stays unchanged.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$ZERO_DIR/.." && pwd)"
RECORD="plan/state/claude-code.md"
OLD_DIR="ravintio-overrides/setup-config"
RETIRED_FLAGS=(--structured-telemetry-mcp --backend-url --context-mode-mcp --include-full-skill-library)

file_exists() { [ -f "$1" ] && echo "yes" || echo "no"; }
path_exists() { [ -e "$1" ] && echo "yes" || echo "no"; }

# Prints one field of the record's fenced json block, as JSON.
# Prints "missing" when the key is absent and "invalid" when the block
# doesn't parse.
read_record_field() {
  node -e '
    const fs = require("fs");
    const text = fs.readFileSync(process.argv[1], "utf8");
    const m = text.match(/```json\n([\s\S]*?)\n```/);
    if (!m) { console.log("invalid"); process.exit(0); }
    let j;
    try { j = JSON.parse(m[1]); } catch (e) { console.log("invalid"); process.exit(0); }
    console.log(Object.prototype.hasOwnProperty.call(j, process.argv[2])
      ? JSON.stringify(j[process.argv[2]]) : "missing");
  ' "$1" "$2" 2>/dev/null
}

# Prints the record with its writtenAt value blanked, so two records
# compare on layout alone.
normalise_record() {
  sed -E 's/"writtenAt": "[^"]*"/"writtenAt": "X"/' "$1" 2>/dev/null
}

# ── (a): the tracked record ───────────────────────────────────────────────

echo ""
echo "=== req-003 (a): the tracked record sits at $RECORD ==="

cd "$REPO_ROOT"
assert_equals "yes" "$(file_exists "$RECORD")" \
  "req-003 (a): $RECORD exists"
assert_equals "\"claude-code\"" "$(read_record_field "$RECORD" tool)" \
  "req-003 (a): the record names claude-code"
# The flags array holds whatever setup flags the human last chose, such as
# --strict-orchestrator. The suite pins its shape, not its contents.
TRACKED_FLAGS="$(read_record_field "$RECORD" flags)"
assert_equals "yes" "$(printf '%s' "$TRACKED_FLAGS" | grep -qE '^\[("--[a-z-]+"(, *"--[a-z-]+")*)?\]$' && echo yes || echo no)" \
  "req-003 (a): the record has a flags array of setup flags"
assert_equals "missing" "$(read_record_field "$RECORD" backendUrl)" \
  "req-003 (a): the record has no backendUrl key"
WRITTEN_AT="$(read_record_field "$RECORD" writtenAt)"
assert_equals "yes" "$(printf '%s' "$WRITTEN_AT" | grep -qE '^"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z"$' && echo yes || echo no)" \
  "req-003 (a): the record has a UTC writtenAt"

# ── (b): the old folder is gone ───────────────────────────────────────────

echo ""
echo "=== req-003 (b): $OLD_DIR is gone ==="

assert_equals "no" "$(path_exists "$OLD_DIR")" \
  "req-003 (b): $OLD_DIR is absent from the tree"
assert_equals "" "$(git ls-files -- "$OLD_DIR" 2>/dev/null)" \
  "req-003 (b): git ls-files lists nothing under $OLD_DIR"

# ── (c): setup.sh in a temporary copy ─────────────────────────────────────

echo ""
echo "=== req-003 (c): setup.sh claude-code in a copy keeps the record clean ==="

REAL_RECORD_BEFORE="$(cat "$RECORD" 2>/dev/null)"
REAL_HOOKS_BEFORE="$(git config --get core.hooksPath 2>/dev/null)"

WS=$(mktemp -d -t ravintio_0000037_req003_test_XXXXXX)
cp -r "$ZERO_DIR" "$WS/ravintio-zero"
mkdir -p "$WS/plan/state"
[ -f "$RECORD" ] && cp "$RECORD" "$WS/$RECORD"
[ -d ravintio-overrides ] && cp -r ravintio-overrides "$WS/ravintio-overrides"
git init "$WS" >/dev/null 2>&1

cd "$WS"
# Setup runs with the tracked flags, so the copy's record keeps them.
# Word splitting is intended: each flag becomes one argument.
FLAG_ARGS="$(printf '%s' "$TRACKED_FLAGS" | tr -d '[]",')"
OUT="$(bash ravintio-zero/setup.sh claude-code $FLAG_ARGS 2>&1)"
EXIT=$?
assert_exit_zero "$EXIT" "req-003 (c): setup.sh claude-code exits 0 in the copy"
assert_equals "$TRACKED_FLAGS" "$(read_record_field "$RECORD" flags)" \
  "req-003 (c): the copy's record keeps the tracked flags after setup"
assert_equals "missing" "$(read_record_field "$RECORD" backendUrl)" \
  "req-003 (c): the copy's record has no backendUrl after setup"
for flag in "${RETIRED_FLAGS[@]}"; do
  assert_equals "no" "$(grep -q -- "$flag" "$RECORD" 2>/dev/null && echo yes || echo no)" \
    "req-003 (c): the copy's record holds no retired flag $flag"
done
assert_equals "no" "$(path_exists "$OLD_DIR")" \
  "req-003 (c): setup leaves no $OLD_DIR in the copy"
SETUP_LAYOUT="$(normalise_record "$RECORD")"
cd "$REPO_ROOT"
assert_equals "$SETUP_LAYOUT" "$(normalise_record "$RECORD")" \
  "req-003 (c): the tracked record matches the layout setup.sh writes"
rm -rf "$WS"

# ── (d): the real working tree is unchanged ───────────────────────────────

echo ""
echo "=== req-003 (d): the suite leaves the real working tree unchanged ==="

assert_equals "$REAL_RECORD_BEFORE" "$(cat "$RECORD" 2>/dev/null)" \
  "req-003 (d): the real $RECORD is unchanged"
assert_equals "$REAL_HOOKS_BEFORE" "$(git config --get core.hooksPath 2>/dev/null)" \
  "req-003 (d): the real core.hooksPath is unchanged"

print_summary
