#!/usr/bin/env bash
# 0000185 req-002: strict-mode-links
# The getting-started strict mode row and the README --strict-orchestrator
# row link to the strict mode section, and its heading still exists.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$ZERO_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

GS="$ZERO_DIR/getting-started.md"
OPS="$ZERO_DIR/project-operations.md"
README="$REPO_DIR/README.md"

echo ""
echo "=== 0000185 req-002 strict-mode-links ==="

check() {
  if [ "$2" = "0" ]; then _pass_line "$1"; PASS=$((PASS+1)); else _fail_line "$1"; FAIL=$((FAIL+1)); fi
}

ok=1
if grep -F '| Orchestrator sentinel and strict mode |' "$GS" \
  | grep -qF '(project-operations.md#strict-orchestrator-mode)'; then ok=0; fi
check "req-002 AC-1: getting-started strict mode row links to the strict mode section" "$ok"

ok=1
if [ -f "$README" ] && grep -F '| `--strict-orchestrator` |' "$README" \
  | grep -qF '(ravintio-zero/project-operations.md#strict-orchestrator-mode)'; then ok=0; fi
check "req-002 AC-2: README --strict-orchestrator row links to the strict mode section" "$ok"

ok=1
if grep -qx '## Strict Orchestrator Mode' "$OPS"; then ok=0; fi
check "req-002 AC-3: project-operations.md keeps the Strict Orchestrator Mode heading" "$ok"

print_summary
