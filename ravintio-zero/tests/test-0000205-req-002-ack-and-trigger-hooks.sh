#!/usr/bin/env bash
# Tests for feature 0000205 REQ-002: ack split and trigger hooks.
# AC-1: either ack file silences strict mode.
# AC-2: the strict banner names the right ack file.
# AC-3: the auto-trigger hook picks the skill.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
AUTO_TRIGGER="$ZERO_DIR/hooks/enforcement/auto-trigger-orchestrator.mjs"
PRESENCE="$ZERO_DIR/hooks/enforcement/check-orchestrator-presence.mjs"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

new_ws() {
  local ws
  ws="$(mktemp -d "$TMP_ROOT/ws.XXXXXX")"
  mkdir -p "$ws/ravintio-zero" "$ws/plan/current"
  echo "$ws"
}

# run_hook <hook> <workspace> [ENV=value ...] -> prints stdout, sets RC
run_hook() {
  local hook="$1" ws="$2"
  shift 2
  local out
  out="$(printf '{"cwd":"%s","session_id":"sess-1"}' "$ws" | env -u RAVINTIO_INITIATIVE_STEP "$@" node "$hook" 2>/dev/null)"
  echo $? > "$TMP_ROOT/rc"
  printf '%s' "$out"
}

make_active_initiative() {
  mkdir -p "$1/plan/current-initiative"
  printf -- '---\ntitle: "x"\nstatus: "active"\n---\n# I\n\n**Status:** active\n' \
    > "$1/plan/current-initiative/initiative.md"
}

strict_ws() {
  local ws
  ws="$(new_ws)"
  echo "feat-1" > "$ws/plan/.orchestrator-active"
  touch "$ws/plan/.orchestrator-strict"
  echo "$ws"
}

echo ""
echo "=== AC-1: either ack file silences strict mode ==="

ws="$(strict_ws)"
echo "sess-1" > "$ws/plan/.initiative-ack"
out="$(run_hook "$PRESENCE" "$ws" X=1)"
assert_equals "" "$out" "AC-1: .initiative-ack with the id is silent"
assert_equals "0" "$(cat "$TMP_ROOT/rc")" "AC-1: exit 0 with .initiative-ack"

ws="$(strict_ws)"
echo "sess-1" > "$ws/plan/.orchestrator-ack"
out="$(run_hook "$PRESENCE" "$ws" X=1)"
assert_equals "" "$out" "AC-1: .orchestrator-ack with the id is silent"

ws="$(strict_ws)"
echo "sess-1" > "$ws/plan/.orchestrator-ack"
echo "other" > "$ws/plan/.initiative-ack"
touch "$ws/plan/.initiative-runner.lock"
out="$(run_hook "$PRESENCE" "$ws" X=1)"
assert_equals "" "$out" "AC-1: one matching ack of two is silent even with the lock held"

echo ""
echo "=== AC-2: the banner names the right ack file ==="

ws="$(strict_ws)"
make_active_initiative "$ws"
touch "$ws/plan/.initiative-runner.lock"
echo "stale" > "$ws/plan/.orchestrator-ack"
out="$(run_hook "$PRESENCE" "$ws" X=1)"
assert_contains "plan/.initiative-ack" "$out" "AC-2: active initiative names plan/.initiative-ack"
assert_contains "ravintio-initiative" "$out" "AC-2: active initiative names ravintio-initiative"
assert_contains "sess-1" "$out" "AC-2: banner carries the session id"
assert_equals "0" "$(cat "$TMP_ROOT/rc")" "AC-2: exit 0 (never 2)"

ws="$(strict_ws)"
out="$(run_hook "$PRESENCE" "$ws" X=1)"
assert_contains "plan/.orchestrator-ack" "$out" "AC-2: no initiative names plan/.orchestrator-ack"
assert_contains "ravintio-orchestrator" "$out" "AC-2: no initiative names ravintio-orchestrator"
case "$out" in
  *ravintio-initiative*) assert_equals "absent" "present" "AC-2: no initiative must not name ravintio-initiative" ;;
  *) assert_equals "absent" "absent" "AC-2: no initiative does not name ravintio-initiative" ;;
esac

ws="$(strict_ws)"
make_active_initiative "$ws"
touch "$ws/plan/.initiative-runner.lock"
out="$(run_hook "$PRESENCE" "$ws" RAVINTIO_INITIATIVE_STEP=1)"
assert_contains "plan/.orchestrator-ack" "$out" "AC-2: step session with lock held still gets the orchestrator banner"

echo ""
echo "=== Advisory mode keeps working ==="

ws="$(new_ws)"
echo "feat-1" > "$ws/plan/.orchestrator-active"
out="$(run_hook "$PRESENCE" "$ws" X=1)"
assert_contains "RAVINTIO PIPELINE ACTIVE" "$out" "advisory: banner present"
assert_contains "ravintio-orchestrator" "$out" "advisory: names the orchestrator"

touch "$ws/plan/.initiative-runner.lock"
out="$(run_hook "$PRESENCE" "$ws" X=1)"
assert_contains "ravintio-orchestrator" "$out" "advisory lock without initiative: names the orchestrator"

make_active_initiative "$ws"
out="$(run_hook "$PRESENCE" "$ws" X=1)"
assert_contains "RAVINTIO PIPELINE ACTIVE" "$out" "advisory initiative: banner present"
assert_contains "ravintio-initiative" "$out" "advisory initiative: names ravintio-initiative"
assert_equals "0" "$(cat "$TMP_ROOT/rc")" "advisory initiative: exit 0"

ws="$(new_ws)"
out="$(run_hook "$PRESENCE" "$ws" X=1)"
assert_equals "" "$out" "no sentinel: silent"

echo ""
echo "=== AC-3: the trigger picks the skill ==="

# Active initiative, lock held, no sentinel, empty plan/current.
ws="$(new_ws)"
make_active_initiative "$ws"
touch "$ws/plan/.initiative-runner.lock"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_contains "SYSTEM INSTRUCTION" "$out" "AC-3: lock held emits an instruction"
assert_contains "ravintio-initiative" "$out" "AC-3: lock held names ravintio-initiative"
assert_equals "0" "$(cat "$TMP_ROOT/rc")" "AC-3: exit 0"

# Hidden entries in plan/current do not count as artifacts.
touch "$ws/plan/current/.skips"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_contains "ravintio-initiative" "$out" "AC-3: hidden entries in plan/current are ignored"

# Active initiative, lock free, no sentinel, empty plan/current.
ws="$(new_ws)"
make_active_initiative "$ws"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_contains "ravintio-initiative" "$out" "AC-3: lock free and empty plan/current names ravintio-initiative"

# Frontmatter-only status form.
ws="$(new_ws)"
mkdir -p "$ws/plan/current-initiative"
printf -- '---\nstatus: active\n---\n# I\n' > "$ws/plan/current-initiative/initiative.md"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_contains "ravintio-initiative" "$out" "AC-3: frontmatter status form is read"

# Body-only status form.
ws="$(new_ws)"
mkdir -p "$ws/plan/current-initiative"
printf -- '# I\n\n**Status:** active\n' > "$ws/plan/current-initiative/initiative.md"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_contains "ravintio-initiative" "$out" "AC-3: body status form is read"

# No initiative: orchestrator.
ws="$(new_ws)"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_contains "ravintio-orchestrator" "$out" "AC-3: no initiative names ravintio-orchestrator"

# No initiative, lock held: still orchestrator.
touch "$ws/plan/.initiative-runner.lock"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_contains "ravintio-orchestrator" "$out" "AC-3: lock without initiative names ravintio-orchestrator"

# Inactive initiative: orchestrator.
ws="$(new_ws)"
mkdir -p "$ws/plan/current-initiative"
printf -- '---\nstatus: "complete"\n---\n# I\n\n**Status:** complete\n' > "$ws/plan/current-initiative/initiative.md"
touch "$ws/plan/.initiative-runner.lock"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_contains "ravintio-orchestrator" "$out" "AC-3: inactive initiative names ravintio-orchestrator"

# Step session: lock held, empty plan/current, env var set -> orchestrator.
ws="$(new_ws)"
make_active_initiative "$ws"
touch "$ws/plan/.initiative-runner.lock"
out="$(run_hook "$AUTO_TRIGGER" "$ws" RAVINTIO_INITIATIVE_STEP=1)"
assert_contains "ravintio-orchestrator" "$out" "AC-3: step session (env set) names ravintio-orchestrator"

# Sentinel present: silent.
ws="$(new_ws)"
make_active_initiative "$ws"
touch "$ws/plan/.initiative-runner.lock"
echo "feat-1" > "$ws/plan/.orchestrator-active"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_equals "" "$out" "AC-3: sentinel present is silent"

# Non-empty plan/current with active initiative: the initiative owns the session (0000218).
ws="$(new_ws)"
make_active_initiative "$ws"
touch "$ws/plan/.initiative-runner.lock"
touch "$ws/plan/current/design.md"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_contains "ravintio-initiative" "$out" "AC-3: artifacts in plan/current do not change the skill"

# Not a ravintio project: silent.
ws="$(mktemp -d "$TMP_ROOT/bare.XXXXXX")"
out="$(run_hook "$AUTO_TRIGGER" "$ws" X=1)"
assert_equals "" "$out" "AC-3: non-ravintio project is silent"

print_summary
