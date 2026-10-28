#!/usr/bin/env bash
# 0000169 req-003: attribution-check-in-ship-and-ci
# Ship Step 9 checks the PR body for attribution before gh pr create, and
# validate-branch runs the same check on the PR description in both workflows.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$ZERO_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
WF_REPO="$ROOT/.github/workflows/ravintio.yml"
WF_TPL="$ZERO_DIR/hooks/ravintio.yml"

section() { awk -v h="$1" '
    $0 == h { on = 1; lvl = index(h, " "); next }
    on && /^#+ / { if (index($0, " ") <= lvl) exit }
    on { print }' "$2"; }
has() { printf '%s\n' "$2" | grep -qF -- "$1" && echo yes || echo no; }
line() { printf '%s\n' "$2" | grep -n -F -- "$1" | head -1 | cut -d: -f1; }

echo ""
echo "=== 0000169 req-003 attribution-check-in-ship-and-ci ==="

S9="$(section '### Step 9: PR' "$SHIP")"
assert_equals "yes" "$(has 'check-attribution.mjs' "$S9")" "Step 9 runs check-attribution.mjs"
assert_equals "yes" "$(has 'temporary file' "$S9")" "Step 9 writes the body to a temporary file"
assert_equals "yes" "$(has 'P4 Ship: Blocked: attribution line in the PR body.' "$S9")" "Step 9 holds the stop message"
lc="$(line 'check-attribution.mjs' "$S9")"
ls_="$(line 'P4 Ship: Blocked: attribution line in the PR body.' "$S9")"
lp="$(line 'gh pr create' "$S9")"
ok=no
[ -n "$lc" ] && [ -n "$ls_" ] && [ -n "$lp" ] && [ "$lc" -lt "$ls_" ] && ok=yes
assert_equals "yes" "$ok" "Step 9 orders the check before its stop message"
# the check text precedes the first gh pr create code block
first_pr="$(printf '%s\n' "$S9" | grep -n '^gh pr create$' | head -1 | cut -d: -f1)"
ok=no; [ -n "$lc" ] && [ "$lc" -lt "$first_pr" ] && ok=yes
assert_equals "yes" "$ok" "Step 9 runs the check before gh pr create"

for wf in "$WF_REPO" "$WF_TPL"; do
  n="$(basename "$(dirname "$wf")")/$(basename "$wf")"
  assert_equals "yes" "$(has 'check-attribution.mjs' "$(cat "$wf")")" "$n runs check-attribution.mjs"
  assert_equals "yes" "$(has 'PR_BODY: ${{ github.event.pull_request.body }}' "$(cat "$wf")")" "$n passes the body through env"
  # no run block interpolates the body: the expression appears only on PR_BODY lines
  bad="$(grep -F 'github.event.pull_request.body' "$wf" | grep -v 'PR_BODY:' | grep -vc '^[[:space:]]*#')"
  assert_equals "0" "$bad" "$n has no other use of the PR body expression"
done

# Run the CI step script itself, taken from the repo workflow.
STEP="$(awk '
  /Check PR description for attribution/ {on=1; next}
  on && /^        run: \|/ {run=1; next}
  on && run && /^          / {sub(/^          /, ""); print; next}
  on && run {exit}' "$WF_REPO")"
assert_equals "yes" "$([ -n "$STEP" ] && echo yes || echo no)" "CI step script extracted"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
run_step() {
  ( cd "$ROOT" && RUNNER_TEMP="$TMP" PR_BODY="$1" bash -c "$STEP" >/dev/null 2>&1 )
}
run_step ""; assert_equals "0" "$?" "CI step passes for an empty body"
run_step "$(printf 'Summary\n\nCo-Authored-By: Claude <noreply@anthropic.com>')"; rc=$?
assert_equals "1" "$rc" "CI step fails for an attribution line"
run_step "Plain summary"; assert_equals "0" "$?" "CI step passes for a clean body"

print_summary
