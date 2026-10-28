#!/usr/bin/env bash
# 0000164 req-002: gate-write-documented-scope (ADR-002)
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
node "$SCRIPT_DIR/test-0000164-req-002-gate-write-documented-scope.mjs"
exit $?
