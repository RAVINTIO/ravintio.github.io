#!/usr/bin/env bash
# test-0000028-req-004-install-refresh-registration.sh
#
# REQ-004 asserts an operational outcome: after a refresh, the phase telemetry
# hooks are registered and telemetry receipts stay out of version control.
#
# The live-firing half of that outcome belongs to REQ-005 and cannot be
# asserted here. A hook firing requires a real host tool session, which is
# exactly why backlog 0000058 existed and why its evidence lives in
# plan/current/verification-report.md rather than in this file. What IS
# assertable without a live session is covered below: that setup.sh contains
# the wiring, that the shared modules reach every install tier, and that the
# receipts path is ignored by git.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ZERO_DIR="$REPO_ROOT/ravintio-zero"

source "$SCRIPT_DIR/helpers/assert.sh"

SETUP_SH="$ZERO_DIR/setup.sh"
setup_content=$(cat "$SETUP_SH")

echo "=== req-004: shared modules reach tier 1 installs ==="

# The tier 1 telemetry copy globbed emit-phase-*.mjs, which would silently drop
# any shared module and break the req-002 extraction for Cursor, Windsurf and
# Cline. Assert the narrow glob is gone rather than merely that a wide one
# exists somewhere in the file.
tier1_narrow=$(printf '%s' "$setup_content" | grep -c 'telem_src"/emit-phase-\*\.mjs' || true)
assert_equals "0" "$tier1_narrow" \
  "req-004: tier 1 telemetry install no longer globs only emit-phase-*.mjs"

echo ""
echo "=== req-004 / SEC-001: enforcement hooks are invoked through node ==="

# P5 SEC-001. These were wired as bare .mjs paths relying on a shebang plus an
# executable bit. That bit is a committed file mode, and 9 of 10 hook files are
# mode 100644, so the shell could not exec them: the command exited 126 and the
# hook silently never ran. A PreToolUse hook that fails to start looks exactly
# like one that passed, so gate-write, em-dash-guard and check-design were dead
# on every bash install.
#
# The suite could not catch this before because every test invokes hooks via
# `node` directly, never through the command string setup.sh actually writes.
# These assertions check the wiring itself, which is where the defect lived.
# The list is the six enforcement hooks that survive 0000033.
for hook in gate-write ratchet-check em-dash-guard auto-trigger-orchestrator \
            check-orchestrator-presence check-design; do
  assert_contains "node \\\"\$hooks_dir_rel/$hook.mjs\\\"" "$setup_content" \
    "req-004: setup.sh invokes $hook.mjs through node, not as a bare path"
done

# Guard against a regression that reintroduces a bare-path wiring for any
# enforcement hook, including one added later.
bare_path_wiring=$(printf '%s' "$setup_content" \
  | grep -cE '^\s*local [a-z_]+_cmd="\$hooks_dir_rel/[a-z-]+\.mjs"' || true)
assert_equals "0" "$bare_path_wiring" \
  "req-004: no enforcement hook is wired as a bare path without node"

echo ""
echo "=== req-004: telemetry receipts stay out of version control ==="

# Receipts are written per successful emit_event and, like failure markers, can
# echo user-configured URL and error strings. Both must be ignored.
cd "$REPO_ROOT"
receipts_ignored=$(git check-ignore -q plan/.telemetry-receipts/probe.json && echo yes || echo no)
assert_equals "yes" "$receipts_ignored" \
  "req-004: plan/.telemetry-receipts/ is gitignored"

markers_ignored=$(git check-ignore -q plan/.telemetry-failures/probe.json && echo yes || echo no)
assert_equals "yes" "$markers_ignored" \
  "req-004: plan/.telemetry-failures/ is still gitignored"

print_summary
