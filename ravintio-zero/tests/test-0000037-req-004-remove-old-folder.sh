#!/usr/bin/env bash
# Tests for feature 0000037-self-host-on-planifest-zero, req-004 (ADR-001).
#
# The old folder is gone from the tree and from git.
# Git reads its hooks from ravintio-zero/hooks, so commit-msg stays active.
# The tests README names no old folder.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ ! -d "$REPO/.git" ] && ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo "  SKIP: ravintio-zero/ is not inside a git repo, so this is a consumer copy"
  print_summary
  exit 0
fi

# Built by concatenation, so this file does not name the old folder itself.
OLD_FOLDER="planifest-""framework"

echo "=== req-004 (a): the old folder is gone ==="
assert_equals "no" "$([ -e "$REPO/$OLD_FOLDER" ] && echo yes || echo no)" \
  "req-004 (a): the old folder is absent from the tree"
assert_equals "0" "$(git -C "$REPO" ls-files -- "$OLD_FOLDER" | wc -l | tr -d ' ')" \
  "req-004 (a): git ls-files lists nothing under the old folder"

echo "=== req-004 (b): git reads hooks from ravintio-zero/hooks ==="
if [ -n "${CI:-}" ]; then
  echo "  SKIP: req-004 (b): CI checkouts have no local git config"
else
  assert_equals "ravintio-zero/hooks" "$(git -C "$REPO" config core.hooksPath)" \
    "req-004 (b): core.hooksPath is ravintio-zero/hooks"
fi
assert_equals "yes" "$([ -f "$REPO/ravintio-zero/hooks/commit-msg" ] && echo yes || echo no)" \
  "req-004 (b): ravintio-zero/hooks/commit-msg exists"

echo "=== req-004 (c): the tests README names no old folder ==="
assert_equals "0" "$(grep -c "$OLD_FOLDER" "$SCRIPT_DIR/README.md" || true)" \
  "req-004 (c): tests/README.md names no old folder"

print_summary
