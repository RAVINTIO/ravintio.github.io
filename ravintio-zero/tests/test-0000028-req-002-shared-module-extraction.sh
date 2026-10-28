#!/usr/bin/env bash
# Tests for feature 0000028, req-002: extract duplicated hook logic into a
# shared module under hooks/enforcement/ (ADR-002), sequenced so no caller ever
# imports a module absent from the same commit (ADR-004).
#
# Scope after feature 0000033 removed telemetry: hooks/telemetry/ is gone, and
# with it read-product-id.mjs, record-telemetry-failure.mjs, get-flag-path.mjs,
# emit-event.mjs and phase-enum.mjs. The one shared module req-002 left behind
# is hooks/enforcement/read-stdin.mjs, so this suite covers that module and its
# six real importers.
#
# Covers:
#   1. readStdin has exactly one definition left in hooks/.
#   2. The shared module exists and every importer takes it by relative path.
#   3. The shared readStdin settles on a stdin stream error rather than
#      hanging, and every importer still exits 0 on that path (NFR-001). This is
#      the deliberate behaviour change req-002 calls out: before extraction
#      most per-hook copies wired no stdin.on("error", reject).
#   4. Placement: the always-installed hooks/enforcement/ tree holds everything
#      an enforcement hook imports, so no enforcement hook reaches outside it.
#   5. The install glob copies the shared module, verified by running setup.sh
#      into a scratch workspace with no flags and invoking an installed hook.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$ZERO_DIR/hooks"
ENF="$HOOKS/enforcement"

# The eight enforcement hooks that import the shared readStdin. Every other
# former caller lived in hooks/telemetry/ and no longer exists.
READSTDIN_CALLERS=(
  "$ENF/auto-trigger-orchestrator.mjs" "$ENF/check-design.mjs"
  "$ENF/check-orchestrator-presence.mjs" "$ENF/em-dash-guard.mjs"
  "$ENF/gate-write.mjs" "$ENF/ratchet-check.mjs" "$ENF/merge-guard.mjs"
  "$ENF/check-reply-prefix.mjs"
)

count_defs() {
  # count_defs <pattern> <dir>... — files matching a pattern across hooks subtrees.
  # The pattern comes first so multiple directories can be passed as separate
  # arguments; collapsing them into one word makes grep -rl take an invalid
  # path, return no matches, and the assertion pass vacuously.
  local pattern="$1"; shift
  grep -rl "$pattern" "$@" 2>/dev/null | wc -l | tr -d ' '
}

make_workspace() {
  local dir
  dir=$(mktemp -d -t ravintio_0000028_req002_XXXXXX)
  cp -r "$ZERO_DIR" "$dir/ravintio-zero"
  git init "$dir" >/dev/null 2>&1
  git config --global --add safe.directory "$dir" >/dev/null 2>&1 || true
  printf 'components: []\n' > "$dir/product.yml"
  echo "$dir"
}

# =============================================================================
# 1. readStdin has exactly one definition remaining
# =============================================================================

echo ""
echo "=== req-002: readStdin has exactly one definition ==="

assert_equals "1" "$(count_defs '^export function readStdin' "$ENF")" \
  "req-002: readStdin is defined exactly once across the hook trees"
assert_equals "0" "$(count_defs '^function readStdin' "$HOOKS")" \
  "req-002: no hook declares a local readStdin"

# The single definition must be the shared module itself, not a hook that
# happens to export it.
DEF_FILE="$(grep -rl '^export function readStdin' "$HOOKS" 2>/dev/null)"
assert_equals "$ENF/read-stdin.mjs" "$DEF_FILE" \
  "req-002: that one definition lives in hooks/enforcement/read-stdin.mjs"

# =============================================================================
# 2. The shared module exists and every importer takes it
# =============================================================================

echo ""
echo "=== req-002: the shared module exists and callers import it ==="

if [ -f "$ENF/read-stdin.mjs" ]; then
  assert_equals "0" "0" "req-002: shared module exists: hooks/enforcement/read-stdin.mjs"
else
  assert_equals "exists" "missing" "req-002: shared module exists: hooks/enforcement/read-stdin.mjs"
fi

for caller in "${READSTDIN_CALLERS[@]}"; do
  CONTENT="$(cat "$caller")"
  assert_contains 'import { readStdin } from "./read-stdin.mjs";' "$CONTENT" \
    "req-002: $(basename "$caller") imports the shared readStdin"
done

# The importer list must be the whole set: a hook added later with its own
# inline copy would otherwise go unnoticed.
ACTUAL_IMPORTERS="$(grep -rl 'read-stdin.mjs' "$HOOKS" 2>/dev/null | sort | tr '\n' ' ')"
EXPECTED_IMPORTERS="$(printf '%s\n' "${READSTDIN_CALLERS[@]}" | sort | tr '\n' ' ')"
assert_equals "$EXPECTED_IMPORTERS" "$ACTUAL_IMPORTERS" \
  "req-002: the eight enforcement hooks are the complete set of readStdin importers"

# Every import in every hook must resolve on disk. A missing shared module is
# an ESM module-load failure, which happens before the hook's own try/catch and
# so cannot degrade gracefully (ADR-002/ADR-004).
echo ""
echo "=== req-002: every relative import in hooks/ resolves on disk ==="
UNRESOLVED=$(node -e '
  const fs = require("fs"), path = require("path");
  const roots = process.argv.slice(1);
  const missing = [];
  for (const root of roots) {
    for (const f of fs.readdirSync(root).filter((n) => n.endsWith(".mjs"))) {
      const src = fs.readFileSync(path.join(root, f), "utf8");
      for (const m of src.matchAll(/from\s+"(\.[^"]+)"/g)) {
        const target = path.resolve(root, m[1]);
        if (!fs.existsSync(target)) missing.push(`${f} -> ${m[1]}`);
      }
    }
  }
  console.log(missing.join(","));
' "$ENF")
assert_equals "" "$UNRESOLVED" "req-002: no hook imports a module that is absent from the source tree"

# =============================================================================
# 3. Shared readStdin settles on a stdin error (NFR-001)
# =============================================================================

echo ""
echo "=== req-002: shared readStdin settles on a stdin stream error ==="

assert_contains 'process.stdin.on("error"' "$(cat "$ENF/read-stdin.mjs")" \
  "req-002: shared readStdin wires an error handler"

# stdin must stay OPEN for this to mean anything: with /dev/null the stream
# reaches "end" immediately and resolves before any error can be observed.
# Process substitution on a sleeping process gives an fd that produces no data
# and no EOF for the life of the check, which is the shape a stalled stdin has.
SETTLE=$(node --input-type=module -e "
  import { readStdin } from '$ENF/read-stdin.mjs';
  let settled = 'HUNG';
  readStdin().then(() => { settled = 'RESOLVED'; }, () => { settled = 'REJECTED'; });
  setTimeout(() => process.stdin.emit('error', new Error('synthetic stdin failure')), 50);
  setTimeout(() => { console.log(settled); process.exit(0); }, 500);
" < <(sleep 5) 2>&1 | tail -1)
assert_equals "REJECTED" "$SETTLE" \
  "req-002: readStdin rejects on a stdin error instead of hanging forever"

# End-to-end, in the exact shape a hook uses it: await inside a try/catch that
# exits 0. The shared version must reach the catch and exit 0.
node --input-type=module -e "
  import { readStdin } from '$ENF/read-stdin.mjs';
  setTimeout(() => process.stdin.emit('error', new Error('synthetic stdin failure')), 50);
  try { await readStdin(); process.exit(0); } catch { process.exit(0); }
" < <(sleep 5) >/dev/null 2>&1
assert_exit_zero $? "req-002: a hook using the shared readStdin exits 0 on a stdin stream error"

# Control: the pre-extraction shape (no "error" handler) never settles its
# promise, so the stream's error surfaces as an unhandled "error" event that
# bypasses the hook's own top-level try/catch entirely and aborts the process
# non-zero. That is the latent NFR-001 violation consolidating fixed, and the
# reason the discrepancy was resolved toward the error-handling variant rather
# than away from it.
node --input-type=module -e "
  function readStdinOld() {
    return new Promise((resolve) => {
      let data = '';
      process.stdin.setEncoding('utf-8');
      process.stdin.on('data', (chunk) => { data += chunk; });
      process.stdin.on('end', () => resolve(data));
      process.stdin.resume();
    });
  }
  setTimeout(() => process.stdin.emit('error', new Error('synthetic stdin failure')), 50);
  try { await readStdinOld(); process.exit(0); } catch { process.exit(0); }
" < <(sleep 5) >/dev/null 2>&1
PRE_EXIT=$?
if [ "$PRE_EXIT" -ne 0 ]; then
  assert_equals "0" "0" "req-002: the pre-extraction readStdin shape exits non-zero on the same input (the bug this fixed)"
else
  assert_equals "non-zero" "0" "req-002: the pre-extraction readStdin shape exits non-zero on the same input (the bug this fixed)"
fi

# The rejection must land on each caller's existing fail-open path, so no hook
# turns a stdin error into a non-zero exit. Each caller either wraps its await
# in a top-level try/catch or attaches .catch() to its main().
echo ""
echo "=== req-002: every readStdin caller still exits 0 on a rejected stdin ==="
for caller in "${READSTDIN_CALLERS[@]}"; do
  NAME="$(basename "$caller")"
  GUARDED=$(node -e '
    const fs = require("fs");
    const s = fs.readFileSync(process.argv[1], "utf8");
    // Either a top-level try/catch, or main().catch(...)
    const hasTry = /^try\s*\{/m.test(s) && /^\}\s*catch/m.test(s);
    const hasMainCatch = /\)\.catch\(/.test(s) || /main\(\)\.catch/.test(s);
    console.log(hasTry || hasMainCatch ? "guarded" : "unguarded");
  ' "$caller")
  assert_equals "guarded" "$GUARDED" "req-002: $NAME routes a readStdin rejection to a fail-open catch"
done

# =============================================================================
# 4. Placement: enforcement is a self-contained, always-installed tree
# =============================================================================

echo ""
echo "=== req-002: no enforcement hook imports from outside hooks/enforcement/ ==="

# Setup installs hooks/enforcement/ as a unit. Any relative import that escapes
# that directory would resolve against a file setup never copies, which fails at
# ESM module-load time before the hook's own try/catch can run.
ESCAPING=$(node -e '
  const fs = require("fs"), path = require("path");
  const root = process.argv[1];
  const bad = [];
  for (const f of fs.readdirSync(root).filter((n) => n.endsWith(".mjs"))) {
    const src = fs.readFileSync(path.join(root, f), "utf8");
    for (const m of src.matchAll(/from\s+"(\.[^"]+)"/g)) {
      const target = path.resolve(root, m[1]);
      if (path.dirname(target) !== root) bad.push(`${f} -> ${m[1]}`);
    }
  }
  console.log(bad.join(","));
' "$ENF")
assert_equals "" "$ESCAPING" \
  "req-002: every relative import in an enforcement hook stays inside hooks/enforcement/"

if [ -f "$ENF/read-stdin.mjs" ]; then
  assert_equals "0" "0" "req-002: read-stdin.mjs lives in the always-installed enforcement tree"
else
  assert_equals "enforcement" "elsewhere" "req-002: read-stdin.mjs lives in the always-installed enforcement tree"
fi

# =============================================================================
# 5. Install topology: the shared module ships with the default install
# =============================================================================

echo ""
echo "=== req-002: the shared module installs with a no-flag setup run ==="

WS=$(make_workspace); cd "$WS"
bash ravintio-zero/setup.sh claude-code >/dev/null 2>&1

if [ -f "$WS/.claude/hooks/enforcement/read-stdin.mjs" ]; then
  assert_equals "0" "0" "req-002: setup.sh installs hooks/enforcement/read-stdin.mjs with no flags"
else
  assert_equals "installed" "missing" "req-002: setup.sh installs hooks/enforcement/read-stdin.mjs with no flags"
fi

# Every installed importer must sit beside the module it imports.
INST_MISSING=""
for caller in "${READSTDIN_CALLERS[@]}"; do
  NAME="$(basename "$caller")"
  [ -f "$WS/.claude/hooks/enforcement/$NAME" ] || INST_MISSING="$INST_MISSING $NAME"
done
assert_equals "" "$INST_MISSING" "req-002: every readStdin importer installs alongside the shared module"

# End to end: an installed hook must run against the installed copy of the
# shared module. check-design.mjs reads stdin through readStdin and, with no
# feature brief and no orchestrator sentinel, emits its STOP context. That
# output can only appear if the shared import resolved in the installed tree.
DESIGN_OUT=$(printf '{"cwd":"%s"}' "$WS" | node "$WS/.claude/hooks/enforcement/check-design.mjs" 2>&1)
assert_exit_zero $? "req-002: installed check-design exits 0"
assert_contains "[RAVINTIO] STOP" "$DESIGN_OUT" \
  "req-002: installed check-design read stdin through the installed shared module"

# A second importer, on its own code path, to prove the install is not a
# one-file accident. gate-write blocks a write to src/ when no design.md exists.
# Reaching that block means the payload parsed: an unreadable stdin falls into
# gate-write's own catch and exits 0 silently, so exit 2 plus the message is
# only possible once the shared module resolved and returned the JSON.
GATE_OUT=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s/src/app/main.ts"},"cwd":"%s"}' "$WS" "$WS" \
  | node "$WS/.claude/hooks/enforcement/gate-write.mjs" 2>&1)
GATE_EXIT=$?
assert_equals "2" "$GATE_EXIT" "req-002: installed gate-write blocks a src/ write with no design.md"
assert_contains "No confirmed design" "$GATE_OUT" \
  "req-002: installed gate-write parsed its stdin payload through the shared module"

cd /; rm -rf "$WS"

# setup.ps1 parity: the enforcement install uses the same *.mjs glob, so the
# shared module ships on Windows too.
PS1_CONTENT="$(cat "$ZERO_DIR/setup.ps1")"
assert_contains "Get-ChildItem -Path \$src -Filter '*.mjs'" "$PS1_CONTENT" \
  "req-002: setup.ps1 copies enforcement hooks with the same *.mjs glob"

print_summary
