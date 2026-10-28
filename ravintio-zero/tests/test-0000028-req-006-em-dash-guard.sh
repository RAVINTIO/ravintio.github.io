#!/usr/bin/env bash
# Tests for feature 0000028-telemetry-hardening-and-enforcement-fixes
# req-006: em dash write-time guard and cleanup (ADR-003)
#
# Covers:
#   (a) content with an em dash in a scoped path is rejected (exit 2)
#   (b) the same content targeting plan/_archive/ (historical record) passes
#   (c) the same content targeting plan/changelog/ (historical record) passes
#   (d) the sentinel bypass (<!-- ravintio-em-dash-allow -->) allows a
#       scoped write through despite an em dash being present
#   (e) a malformed JSON envelope on stdin exits 0 rather than blocking
#   (f) each of the five scoped prefixes blocks independently
#   (g) an unscoped path (source code) passes untouched
#   (h) the Edit tool's new_string is scanned the same way as Write's content
#   (i) the block message reports the offending line number(s)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$ZERO_DIR/hooks/enforcement"
GUARD="$HOOKS/em-dash-guard.mjs"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# -----------------------------------------------------------------------
# Fixture helpers
# -----------------------------------------------------------------------

mk_proj() {
  local proj="$1"
  mkdir -p "$proj/plan/current" "$proj/plan/_archive" "$proj/plan/changelog" "$proj/docs" \
    "$proj/ravintio-zero/skills" "$proj/ravintio-zero/templates" \
    "$proj/ravintio-zero/standards" "$proj/src"
  echo "$proj"
}

PROJ="$TMP/proj"; mk_proj "$PROJ" >/dev/null

# Runs em-dash-guard.mjs for a Write of `content` to `file_path` with cwd `proj`.
# Returns "<exit-code>\x1f<stdout>" so callers can split both out.
run_guard_write() {
  local file_path="$1" content="$2" proj="${3:-$PROJ}"
  local payload
  payload=$(node -e '
    const [fp, content] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:fp,content}}));
  ' "$file_path" "$content")
  local out rc
  out=$(cd "$proj" && printf '%s' "$payload" | node "$GUARD" 2>/dev/null)
  rc=$?
  printf '%s\x1f%s' "$rc" "$out"
}

# Same, but for the Edit tool shape (old_string/new_string).
run_guard_edit() {
  local file_path="$1" new_string="$2" proj="${3:-$PROJ}"
  local payload
  payload=$(node -e '
    const [fp, ns] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({tool_name:"Edit",tool_input:{file_path:fp,old_string:"x",new_string:ns}}));
  ' "$file_path" "$new_string")
  local out rc
  out=$(cd "$proj" && printf '%s' "$payload" | node "$GUARD" 2>/dev/null)
  rc=$?
  printf '%s\x1f%s' "$rc" "$out"
}

split_rc()  { local s="$1"; printf '%s' "${s%%$'\x1f'*}"; }
split_out() { local s="$1"; printf '%s' "${s#*$'\x1f'}"; }

EM_DASH_LINE=$'some text \xe2\x80\x94 with an em dash in it'
CLEAN_LINE="some text with no forbidden character in it"
SENTINEL="<!-- ravintio-em-dash-allow -->"

# -----------------------------------------------------------------------
echo ""
echo "=== req-006: hook exists ==="
# -----------------------------------------------------------------------

if [ -f "$GUARD" ]; then
  assert_equals "0" "0" "req-006: em-dash-guard.mjs exists"
else
  assert_equals "exists" "missing" "req-006: em-dash-guard.mjs exists"
fi

# -----------------------------------------------------------------------
echo ""
echo "=== req-006(a): em dash in a scoped path is rejected ==="
# -----------------------------------------------------------------------

RESULT=$(run_guard_write "plan/current/notes.md" "$EM_DASH_LINE")
RC=$(split_rc "$RESULT"); OUT=$(split_out "$RESULT")
assert_equals "2" "$RC" "req-006a: em dash in plan/current/ is blocked"
assert_contains "U+2014" "$OUT" "req-006a: block message names the character"
assert_contains "plan/current/notes.md" "$OUT" "req-006a: block message names the offending path"

RESULT=$(run_guard_write "docs/notes.md" "$EM_DASH_LINE")
RC=$(split_rc "$RESULT")
assert_equals "2" "$RC" "req-006a: em dash in docs/ is blocked"

RESULT=$(run_guard_write "plan/current/notes.md" "$CLEAN_LINE")
RC=$(split_rc "$RESULT")
assert_equals "0" "$RC" "req-006a: clean content in a scoped path passes"

# -----------------------------------------------------------------------
echo ""
echo "=== req-006(b)+(c): historical record paths pass untouched ==="
# -----------------------------------------------------------------------

RESULT=$(run_guard_write "plan/_archive/notes.md" "$EM_DASH_LINE")
RC=$(split_rc "$RESULT")
assert_equals "0" "$RC" "req-006b: em dash in plan/_archive/ passes (historical record)"

RESULT=$(run_guard_write "plan/changelog/0000001-notes.md" "$EM_DASH_LINE")
RC=$(split_rc "$RESULT")
assert_equals "0" "$RC" "req-006c: em dash in plan/changelog/ passes (historical record)"

# -----------------------------------------------------------------------
echo ""
echo "=== req-006(d): sentinel bypass ==="
# -----------------------------------------------------------------------

WITH_SENTINEL="${EM_DASH_LINE}"$'\n'"${SENTINEL}"
RESULT=$(run_guard_write "plan/current/notes.md" "$WITH_SENTINEL")
RC=$(split_rc "$RESULT")
assert_equals "0" "$RC" "req-006d: sentinel comment allows a scoped em dash write through"

# Sentinel written by an "agent" (no distinction enforced — reusable, not human-only).
RESULT=$(run_guard_write "ravintio-zero/standards/notes.md" "$WITH_SENTINEL")
RC=$(split_rc "$RESULT")
assert_equals "0" "$RC" "req-006d: sentinel bypass is not restricted to a human-only marker"

# -----------------------------------------------------------------------
echo ""
echo "=== req-006(e): malformed input fails open ==="
# -----------------------------------------------------------------------

RC=$( (cd "$PROJ" && printf '%s' '{not valid json' | node "$GUARD" >/dev/null 2>&1); echo $? )
assert_equals "0" "$RC" "req-006e: malformed JSON on stdin exits 0 (fails open)"

RC=$( (cd "$PROJ" && printf '%s' '' | node "$GUARD" >/dev/null 2>&1); echo $? )
assert_equals "0" "$RC" "req-006e: empty stdin exits 0 (fails open)"

# tool_input missing entirely — still must not throw/block.
RC=$( (cd "$PROJ" && printf '%s' '{"tool_name":"Write"}' | node "$GUARD" >/dev/null 2>&1); echo $? )
assert_equals "0" "$RC" "req-006e: envelope with no tool_input exits 0 (fails open)"

# -----------------------------------------------------------------------
echo ""
echo "=== req-006(f): each scoped prefix blocks independently ==="
# -----------------------------------------------------------------------

for prefix in "plan/current" "docs" "ravintio-zero/skills" \
              "ravintio-zero/templates" "ravintio-zero/standards"; do
  RESULT=$(run_guard_write "$prefix/leaf.md" "$EM_DASH_LINE")
  RC=$(split_rc "$RESULT")
  assert_equals "2" "$RC" "req-006f: $prefix/ blocks an em dash write"
done

# -----------------------------------------------------------------------
echo ""
echo "=== req-006(g): unscoped paths pass untouched ==="
# -----------------------------------------------------------------------

RESULT=$(run_guard_write "src/some-component/index.ts" "$EM_DASH_LINE")
RC=$(split_rc "$RESULT")
assert_equals "0" "$RC" "req-006g: source code path passes regardless of em dash"

RESULT=$(run_guard_write "ravintio-zero/hooks/enforcement/em-dash-guard.mjs" "$EM_DASH_LINE")
RC=$(split_rc "$RESULT")
assert_equals "0" "$RC" "req-006g: the hook's own source path is structurally out of scope"

# -----------------------------------------------------------------------
echo ""
echo "=== req-006(h): Edit tool's new_string is scanned like Write's content ==="
# -----------------------------------------------------------------------

RESULT=$(run_guard_edit "docs/notes.md" "$EM_DASH_LINE")
RC=$(split_rc "$RESULT")
assert_equals "2" "$RC" "req-006h: Edit new_string with an em dash in a scoped path is blocked"

RESULT=$(run_guard_edit "docs/notes.md" "$CLEAN_LINE")
RC=$(split_rc "$RESULT")
assert_equals "0" "$RC" "req-006h: Edit new_string with no em dash passes"

# -----------------------------------------------------------------------
echo ""
echo "=== req-006(i): block message reports the offending line number ==="
# -----------------------------------------------------------------------

MULTILINE=$'line one is clean\n'"${EM_DASH_LINE}"$'\nline three is clean'
RESULT=$(run_guard_write "plan/current/notes.md" "$MULTILINE")
RC=$(split_rc "$RESULT"); OUT=$(split_out "$RESULT")
assert_equals "2" "$RC" "req-006i: multi-line content with one offending line is blocked"
assert_contains "line(s): 2" "$OUT" "req-006i: block message reports the correct offending line number"

print_summary
