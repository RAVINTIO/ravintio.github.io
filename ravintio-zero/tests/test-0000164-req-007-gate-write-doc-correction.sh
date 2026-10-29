#!/usr/bin/env bash
# 0000164 req-007: gate-write-doc-correction (ADR-002)
# The four docs describe the full gate-write scope, not "src/ only".
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FILES=(
  "CLAUDE.md"
  "ravintio-zero/standards/hook-enforcement.md"
  "ravintio-zero/pipeline-reference.md"
  "ravintio-zero/project-operations.md"
)

for f in "${FILES[@]}"; do
  p="$ROOT/$f"
  # CLAUDE.md is gitignored, so a fresh clone such as CI has none to check.
  if [ "$f" = "CLAUDE.md" ] && [ ! -f "$p" ]; then
    echo "  SKIP: REQ-007 $f is absent (gitignored)"; continue
  fi
  gate="$(grep -i 'gate-write' "$p")"
  # The wrong wording is gone from lines that describe gate-write
  if printf '%s\n' "$gate" | grep -q 'Blocks writes to `src/`'; then
    echo "  FAIL: REQ-007 $f still says gate-write blocks writes to src/"; FAIL=$((${FAIL:-0}+1))
  else
    echo "  PASS: REQ-007 $f has no 'Blocks writes to src/' wording"
  fi
  if grep -q 'ravintio-zero/`) unless\|`docs/`, `ravintio-zero/`)' "$p"; then
    echo "  FAIL: REQ-007 $f lists ravintio-zero/ as always permitted"; FAIL=$((${FAIL:-0}+1))
  else
    echo "  PASS: REQ-007 $f does not list ravintio-zero/ as always permitted"
  fi
  # The right wording is present
  for phrase in "every in-project path" ".orchestrator-active" "outside the project"; do
    if printf '%s\n' "$gate" | grep -q -- "$phrase" || grep -A8 'How gate-write interacts' "$p" | grep -q -- "$phrase"; then
      echo "  PASS: REQ-007 $f states '$phrase'"
    else
      echo "  FAIL: REQ-007 $f lacks '$phrase'"; FAIL=$((${FAIL:-0}+1))
    fi
  done
done

[ "${FAIL:-0}" -eq 0 ] && { echo "REQ-007 passed"; exit 0; } || { echo "REQ-007 FAILED (${FAIL})"; exit 1; }
