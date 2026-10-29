#!/usr/bin/env bash
# 0000164 req-001: gate-write-outside-project (ADR-002)
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
node "$SCRIPT_DIR/test-0000164-req-001-gate-write-outside-project.mjs"
exit $?
