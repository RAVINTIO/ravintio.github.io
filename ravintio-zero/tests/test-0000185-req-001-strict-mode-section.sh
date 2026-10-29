#!/usr/bin/env bash
# 0000185 req-001: strict-mode-section
# The strict mode section in project-operations.md names both files and the
# flag, explains what the ack file holds and its name, and covers an initiative run.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

OPS="$ZERO_DIR/project-operations.md"

echo ""
echo "=== 0000185 req-001 strict-mode-section ==="

check() {
  if [ "$2" = "0" ]; then _pass_line "$1"; PASS=$((PASS+1)); else _fail_line "$1"; FAIL=$((FAIL+1)); fi
}

sec="$(awk '/^## Strict Orchestrator Mode$/{f=1;next} /^## /{f=0} f' "$OPS")"
has() { printf '%s\n' "$sec" | grep -qF -- "$1"; }
hasi() { printf '%s\n' "$sec" | grep -qi -- "$1"; }

ok=1
if [ -n "$sec" ] && has 'plan/.orchestrator-strict' && has 'plan/.orchestrator-ack' \
  && has '--strict-orchestrator'; then ok=0; fi
check "req-001 AC-1: section names both files and the --strict-orchestrator flag" "$ok"

ok=1
if hasi 'acknowledg' && hasi 'session id' && hasi 'timestamp' \
  && has 'plan/.orchestrator-active'; then ok=0; fi
check "req-001 AC-2: section explains the ack file content, its name, and the timestamp fallback" "$ok"

ok=1
if hasi 'initiative' && has '.initiative-ack'; then ok=0; fi
check "req-001 AC-3: section covers the initiative case and names plan/.initiative-ack" "$ok"

print_summary
