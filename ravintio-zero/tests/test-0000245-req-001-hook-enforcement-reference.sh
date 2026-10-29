#!/usr/bin/env bash
# Test: 0000245 req-001 hook enforcement reference
# AC-1: the reference file names every hook the boot file listed before the move.
# AC-2: both boot templates hold the path and neither holds the old hook list.
# AC-3: each blocking hook names the file in its message and keeps its exit code.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$ZERO_DIR/hooks/enforcement"
REF="$ZERO_DIR/standards/hook-enforcement.md"
REF_PATH="ravintio-zero/standards/hook-enforcement.md"
STD_BOOT="$ZERO_DIR/templates/standard-boot.md"
CODEX_BOOT="$ZERO_DIR/templates/codex-boot.md"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

echo ""
echo "=== AC-1: reference file holds the rules ==="
ref_text="$(cat "$REF" 2>/dev/null || true)"
for hook in gate-write auto-trigger-orchestrator check-design check-reply-prefix commit-msg ratchet-check; do
  assert_contains "$hook" "$ref_text" "AC-1: reference names $hook"
done
for hook in merge-guard em-dash-guard check-orchestrator-presence; do
  assert_contains "$hook" "$ref_text" "AC-1: reference names Codex entry $hook"
done
assert_contains "Enforcement failures exit 2" "$ref_text" "AC-1: reference holds the exit-code paragraph"
assert_contains "## Codex" "$ref_text" "AC-1: reference holds a Codex heading"

echo ""
echo "=== AC-2: boot files point to it ==="
for f in "$STD_BOOT" "$CODEX_BOOT"; do
  name="$(basename "$f")"
  text="$(cat "$f")"
  assert_contains "$REF_PATH" "$text" "AC-2: $name holds the path"
  assert_not_contains "**check-design**" "$text" "AC-2: $name holds no old hook list"
  assert_not_contains "**ratchet-check**" "$text" "AC-2: $name holds no ratchet-check entry"
done
assert_contains "commit-msg" "$(cat "$STD_BOOT")" "AC-2: standard boot keeps the commit-msg rule"
assert_contains "Never run a pull request merge command against" "$(cat "$CODEX_BOOT")" "AC-2: codex boot keeps the merge safety line"

echo ""
echo "=== AC-3: block messages name the file, exit codes unchanged ==="
ws="$TMP_ROOT/ws"
mkdir -p "$ws/plan/current" "$ws/src"
touch "$ws/plan/.orchestrator-active"

# gate-write: no design.md, so a src write blocks with exit 2.
out="$(printf '{"cwd":"%s","tool_input":{"file_path":"%s/src/a.js"}}' "$ws" "$ws" | node "$HOOKS/gate-write.mjs" 2>/dev/null)"; rc=$?
assert_equals "2" "$rc" "AC-3: gate-write exit code stays 2"
assert_contains "$REF_PATH" "$out" "AC-3: gate-write names the file"

# em-dash-guard: an em dash in a scoped path blocks with exit 2.
dash="$(printf '\xe2\x80\x94')"
out="$(printf '{"cwd":"%s","tool_input":{"file_path":"%s/docs/a.md","content":"a %s b"}}' "$ws" "$ws" "$dash" | node "$HOOKS/em-dash-guard.mjs" 2>/dev/null)"; rc=$?
assert_equals "2" "$rc" "AC-3: em-dash-guard exit code stays 2"
assert_contains "$REF_PATH" "$out" "AC-3: em-dash-guard names the file"

# merge-guard: an unconfirmed merge blocks with exit 2.
merge_cmd="gh pr ""merge 5 --squash"
out="$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$merge_cmd" | node "$HOOKS/merge-guard.mjs" 2>/dev/null)"; rc=$?
assert_equals "2" "$rc" "AC-3: merge-guard exit code stays 2"
assert_contains "$REF_PATH" "$out" "AC-3: merge-guard names the file"

# ratchet-check: weakening an acceptance criterion in an active loop blocks with exit 2.
printf -- '---\nstatus: active\n---\n' > "$ws/plan/current/loop-state-x.md"
printf '## Acceptance Criteria\n- [ ] AC-1: keep me\n' > "$ws/plan/current/req.md"
out="$(cd "$ws" && printf '{"tool_input":{"file_path":"%s/plan/current/req.md","content":"## Acceptance Criteria\\n"}}' "$ws" | node "$HOOKS/ratchet-check.mjs" 2>&1)"; rc=$?
assert_equals "2" "$rc" "AC-3: ratchet-check exit code stays 2"
assert_contains "$REF_PATH" "$out" "AC-3: ratchet-check names the file"

# commit-msg: an AI attribution line blocks with exit 1.
msgfile="$TMP_ROOT/msg"
printf 'feat(x): add thing\n\nClaude-Session: abc\n' > "$msgfile"
out="$(bash "$ZERO_DIR/hooks/commit-msg" "$msgfile" 2>&1)"; rc=$?
assert_equals "1" "$rc" "AC-3: commit-msg exit code stays 1"
assert_contains "$REF_PATH" "$out" "AC-3: commit-msg names the file"

print_summary
