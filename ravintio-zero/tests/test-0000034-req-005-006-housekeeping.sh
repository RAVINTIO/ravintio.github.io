#!/usr/bin/env bash
# Tests for feature 0000034-setup-hardening, req-005 and req-006.
#
# req-005: the stray root .feature-id is gone, and no live file refers to a
# root-level .feature-id (backlog 0000096).
# req-006: the backlog template offers "human request" as a deferral source
# and allows "none (human request)" for source feature and phase (0000102).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO_ROOT="$(cd "$ZERO_DIR/.." && pwd)"
TEMPLATE="$ZERO_DIR/templates/backlog-entry.template.md"

echo ""
echo "=== req-005: no stray root .feature-id ==="

assert_equals "no" "$([ -e "$REPO_ROOT/.feature-id" ] && echo yes || echo no)" \
  "req-005: the repo root holds no .feature-id"
REFS="$(grep -rIl --exclude-dir=.git --exclude-dir=_archive --exclude-dir=changelog --exclude-dir=current --exclude-dir=backlog \
  -e 'root `\.feature-id`' -e 'root-level `\.feature-id`' "$REPO_ROOT/ravintio-zero" "$REPO_ROOT/docs" 2>/dev/null | grep -v 'test-0000034' | head -1)"
assert_equals "" "$REFS" "req-005: no live file refers to a root-level .feature-id"

echo ""
echo "=== req-006: the backlog template allows human request ==="

assert_contains '| human request' "$(grep -n 'Deferral source:\*\*' "$TEMPLATE")" \
  "req-006: the deferral source field lists human request"
assert_contains 'none (human request)' "$(cat "$TEMPLATE")" \
  "req-006: the template allows none (human request) for source feature and phase"
assert_contains 'Use `human request` when' "$(cat "$TEMPLATE")" \
  "req-006: the guidance says when to use human request"

print_summary
