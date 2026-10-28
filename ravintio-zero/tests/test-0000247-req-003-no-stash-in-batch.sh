#!/usr/bin/env bash
# Tests for feature 0000247-git-state-hygiene, req-003: the dispatch standard
# and its skeleton prompts forbid git stash in a subagent during a batch.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

STD="$SCRIPT_DIR/../standards/agent-dispatch-standards.md"

echo ""
echo "=== req-003 AC-1: the rule and its reason ==="
BATCH=$(awk '/^## Fast batches/{f=1;next} /^## /{f=0} f' "$STD")
assert_contains "Never run \`git stash\`" "$BATCH" "req-003 AC-1: the batch rules forbid git stash"
assert_contains "uncommitted work of every other subagent" "$BATCH" "req-003 AC-1: the rule gives the reason"

echo ""
echo "=== req-003 AC-2: each skeleton prompt forbids git stash ==="
SKEL=$(awk '/^\*\*Concrete parallel dispatch skeleton/{f=1} /^\*\*Self-contained prompt rule/{f=0} f' "$STD")
PROMPTS=$(printf '%s\n' "$SKEL" | grep -c 'prompt: "' || true)
FORBID=$(printf '%s\n' "$SKEL" | grep 'prompt: "' | grep -c 'Never run git stash' || true)
assert_equals "2" "$PROMPTS" "req-003 AC-2: the skeleton holds two prompts"
assert_equals "2" "$FORBID" "req-003 AC-2: both prompts forbid git stash"

echo ""
echo "=== req-003 AC-3: the parent resume stash stays ==="
RESUME=$(awk '/^### Resuming an interrupted unit/{f=1;next} /^## |^### /{f=0} f' "$STD")
assert_contains "git stash push --include-untracked" "$RESUME" "req-003 AC-3: the resume section still stashes"

print_summary
