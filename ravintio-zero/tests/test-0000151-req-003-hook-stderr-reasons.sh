#!/usr/bin/env bash
# Tests for feature 0000151-hardening-efficiency-and-ci
# req-003: gate-write, em-dash-guard, and ratchet-check write each block
# reason to stderr as well as stdout (ADR-002).
#
# Covers (a) block: exit 2, non-empty stderr, stdout kept
#        (c) allow: exit 0, empty stderr

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$ZERO_DIR/hooks/enforcement"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PROJ="$TMP/proj"
mkdir -p "$PROJ/plan/current" "$PROJ/src" "$PROJ/docs"
cat > "$PROJ/plan/current/loop-state-design_critic.md" <<'MD'
---
status: "active"
---
# Loop State: design_critic
MD
cat > "$PROJ/plan/current/requirements-doc.md" <<'MD'
# Requirement: REQ-001 - Demo
## Acceptance Criteria
- [ ] criterion alpha holds
- [ ] criterion beta holds
MD

# run_hook <hook> <file> <content>: sets RC, OUT, ERR.
run_hook() {
  local hook="$1" file="$2" content="$3" payload
  payload=$(node -e '
    const [fp, content] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:fp,content}}));
  ' "$file" "$content")
  OUT=$(cd "$PROJ" && printf '%s' "$payload" | node "$HOOKS/$hook" 2>"$TMP/err")
  RC=$?
  ERR=$(cat "$TMP/err")
}

EM=$'text — more'
WEAK=$'# Requirement: REQ-001 - Demo\n## Acceptance Criteria\n- [ ] criterion alpha holds'

echo "=== gate-write ==="
run_hook gate-write.mjs "src/app.ts" "x"
assert_equals "2" "$RC" "gate-write: block exits 2"
assert_contains "No confirmed design" "$ERR" "gate-write: reason on stderr"
assert_contains "No confirmed design" "$OUT" "gate-write: reason kept on stdout"
run_hook gate-write.mjs "docs/a.md" "x"
assert_equals "0" "$RC" "gate-write: allowed write exits 0"
assert_equals "" "$ERR" "gate-write: allowed write has empty stderr"

echo ""
echo "=== em-dash-guard ==="
run_hook em-dash-guard.mjs "docs/a.md" "$EM"
assert_equals "2" "$RC" "em-dash-guard: block exits 2"
assert_contains "Em dash" "$ERR" "em-dash-guard: reason on stderr"
assert_contains "Em dash" "$OUT" "em-dash-guard: reason kept on stdout"
run_hook em-dash-guard.mjs "docs/a.md" "clean text"
assert_equals "0" "$RC" "em-dash-guard: allowed write exits 0"
assert_equals "" "$ERR" "em-dash-guard: allowed write has empty stderr"

echo ""
echo "=== ratchet-check ==="
run_hook ratchet-check.mjs "$PROJ/plan/current/requirements-doc.md" "$WEAK"
assert_equals "2" "$RC" "ratchet-check: block exits 2"
assert_contains "while a loop is active" "$ERR" "ratchet-check: plain reason on stderr"
assert_equals "deny" "$(printf '%s' "$OUT" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).hookSpecificOutput.permissionDecision))')" \
  "ratchet-check: stdout keeps the JSON deny"
assert_equals "no" "$(printf '%s' "$ERR" | grep -q 'hookSpecificOutput' && echo yes || echo no)" \
  "ratchet-check: stderr is plain text, not JSON"
STRONG=$'# Requirement: REQ-001 - Demo\n## Acceptance Criteria\n- [ ] criterion alpha holds\n- [ ] criterion beta holds\n- [ ] criterion gamma holds'
run_hook ratchet-check.mjs "$PROJ/plan/current/requirements-doc.md" "$STRONG"
assert_equals "0" "$RC" "ratchet-check: strengthening write exits 0"
assert_equals "" "$ERR" "ratchet-check: allowed write has empty stderr"

print_summary
