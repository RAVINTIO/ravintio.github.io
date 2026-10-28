#!/usr/bin/env bash
# Tests for feature 0000207-codex-support, req-004: CI checks the codex target.
# The Bash and PowerShell suites install for codex, the CI workflow runs every
# suite through the two runners, and the docs name the target.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO_DIR="$ZERO_DIR/.."
WORKFLOW="$(cat "$REPO_DIR/.github/workflows/ravintio.yml")"

echo ""
echo "=== req-004 AC-1 and AC-2: CI runs the codex suites ==="

for suite in test-0000207-req-001-003-codex-setup.sh test-0000207-req-001-003-codex-setup.ps1; do
  [ -f "$SCRIPT_DIR/$suite" ] && R=yes || R=no
  assert_equals "yes" "$R" "req-004: $suite sits where the runners find it"
done
assert_contains "run-tests.sh" "$WORKFLOW" "req-004 AC-1: CI runs the Bash runner"
assert_contains "run-tests.ps1" "$WORKFLOW" "req-004 AC-2: CI runs the PowerShell runner"
assert_contains "setup.sh codex" "$(cat "$SCRIPT_DIR/test-0000207-req-001-003-codex-setup.sh")" "req-004 AC-1: the Bash suite runs setup for codex"
assert_contains "@('codex')" "$(cat "$SCRIPT_DIR/test-0000207-req-001-003-codex-setup.ps1")" "req-004 AC-2: the PowerShell suite runs setup for codex"

echo ""
echo "=== req-004 AC-3: the docs and the refresh skill name codex ==="

assert_contains "setup.sh codex" "$(cat "$ZERO_DIR/getting-started.md")" "req-004: getting-started names the codex command"
assert_contains "AGENTS.md" "$(cat "$REPO_DIR/README.md")" "req-004: README names AGENTS.md"
assert_contains "\`codex\`" "$(cat "$ZERO_DIR/skills/ravintio-refresh-setup/SKILL.md")" "req-001 AC-3: the refresh skill names codex"

print_summary
