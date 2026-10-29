#!/usr/bin/env bash
# Tests for feature 0000248-ship-merge-and-wall-clocks, req-001: the ship skill
# gives a plain merge line with a literal PR number and merge-guard allows it.
# AC-3 (merge-guard unchanged) is a branch property that P3 checks with git diff.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"
STANDARDS="$ZERO_DIR/standards/roadmap-standards.md"
GUARD="$ZERO_DIR/hooks/enforcement/merge-guard.mjs"

TMP=$(mktemp -d -t ravintio_0000248_req001_XXXXXX)
trap 'rm -rf "$TMP"' EXIT

echo ""
echo "=== req-001 AC-1: the ship skill holds the line and the rule ==="
INIT=$(awk '/^## Initiative steps/{f=1;next} /^## /{f=0} f' "$SHIP")
assert_contains "gh pr merge --squash --delete-branch {n}" "$INIT" "req-001 AC-1: the section holds the plain merge line"
assert_contains "literal PR number" "$INIT" "req-001 AC-1: the section says {n} is a literal PR number"
assert_contains "gh pr create" "$INIT" "req-001 AC-1: the section names the source of the number"
assert_contains "no command substitution, variables, or pipes" "$INIT" "req-001 AC-1: the section forbids substitution, variables, and pipes"
ADV=$(awk '/^### I-D Advance/{f=1;next} /^### /{f=0} f' "$STANDARDS")
assert_contains "gh pr merge --squash --delete-branch {n}" "$ADV" "req-001 AC-1: I-D Advance keeps the same line"
assert_contains "literal PR number" "$ADV" "req-001 AC-1: I-D Advance says {n} is a literal PR number"

echo ""
echo "=== req-001 AC-2: merge-guard allows the line ==="
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" <<'STUB'
#!/usr/bin/env bash
if [ "$1 $2" = "pr view" ]; then printf '{"baseRefName":"%s"}\n' "$STUB_BASE"; fi
STUB
chmod +x "$TMP/bin/gh"
PAYLOAD=$(node -e 'console.log(JSON.stringify({tool_name:"Bash",tool_input:{command:process.argv[1]}}))' "gh pr merge --squash --delete-branch 52")
printf '%s' "$PAYLOAD" | env PATH="$TMP/bin:$PATH" STUB_BASE=initiative/x node "$GUARD" > /dev/null 2>&1
assert_equals "0" "$?" "req-001 AC-2: the guard exits 0 for an initiative/* base"
printf '%s' "$PAYLOAD" | env PATH="$TMP/bin:$PATH" STUB_BASE=main node "$GUARD" > /dev/null 2>&1
assert_equals "2" "$?" "req-001 AC-2: the guard still blocks a main base"

print_summary
