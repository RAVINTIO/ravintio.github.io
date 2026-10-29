#!/usr/bin/env bash
# Tests for feature 0000218: both prompt hooks name the skill that owns the session.
# AC-1/AC-2: an active initiative gives the initiative banner, lock free or held.
# AC-3: a step session gives the orchestrator banner.
# AC-4: no active initiative gives the orchestrator banner.
# AC-5: the auto-trigger and strict-mode hooks name the same skill.
# AC-6: plan/.initiative-ack is git-ignored.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$SCRIPT_DIR/.."
REPO_ROOT="$ZERO_DIR/.."
AUTO_TRIGGER="$ZERO_DIR/hooks/enforcement/auto-trigger-orchestrator.mjs"
PRESENCE="$ZERO_DIR/hooks/enforcement/check-orchestrator-presence.mjs"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

new_ws() {
  local ws
  ws="$(mktemp -d "$TMP_ROOT/ws.XXXXXX")"
  mkdir -p "$ws/ravintio-zero" "$ws/plan/current" "$ws/plan/current-initiative"
  printf -- '---\nstatus: "active"\n---\n# I\n\n**Status:** active\n' \
    > "$ws/plan/current-initiative/initiative.md"
  echo "$ws"
}

run_hook() {
  local hook="$1" ws="$2"
  shift 2
  printf '{"cwd":"%s","session_id":"sess-1"}' "$ws" | env -u RAVINTIO_INITIATIVE_STEP "$@" node "$hook" 2>/dev/null
}

# names <output> -> initiative, orchestrator, or none
names() {
  case "$1" in
    *ravintio-initiative*) echo initiative ;;
    *ravintio-orchestrator*) echo orchestrator ;;
    *) echo none ;;
  esac
}

# check_case <label> <expected skill> <strict yes|no> <lock yes|no> <initiative yes|no> <artifacts yes|no> [ENV=value]
check_case() {
  local label="$1" want="$2" strict="$3" lock="$4" init="$5" art="$6"
  shift 6
  local ws
  ws="$(new_ws)"
  [ "$init" = no ] && rm -rf "$ws/plan/current-initiative"
  [ "$lock" = yes ] && touch "$ws/plan/.initiative-runner.lock"
  [ "$art" = yes ] && touch "$ws/plan/current/design.md"
  [ "$strict" = yes ] && touch "$ws/plan/.orchestrator-strict"

  # Strict and advisory mode run with the sentinel present.
  echo "feat-1" > "$ws/plan/.orchestrator-active"
  local presence
  presence="$(names "$(run_hook "$PRESENCE" "$ws" X=1 "$@")")"
  assert_equals "$want" "$presence" "$label: presence hook (strict=$strict) names $want"

  # The auto-trigger hook runs with the sentinel absent.
  rm -f "$ws/plan/.orchestrator-active"
  local trigger
  trigger="$(names "$(run_hook "$AUTO_TRIGGER" "$ws" X=1 "$@")")"
  assert_equals "$want" "$trigger" "$label: auto-trigger hook names $want"
  assert_equals "$presence" "$trigger" "$label: both hooks name the same skill"
}

for strict in yes no; do
  echo ""
  echo "=== strict=$strict ==="
  # AC-1: lock free, no step variable.
  check_case "AC-1 lock free" initiative "$strict" no yes no
  # AC-2: lock held, no step variable.
  check_case "AC-2 lock held" initiative "$strict" yes yes no
  check_case "AC-2 lock held, step artifacts open" initiative "$strict" yes yes yes
  # AC-3: step session.
  check_case "AC-3 step session, lock held" orchestrator "$strict" yes yes yes RAVINTIO_INITIATIVE_STEP=1
  check_case "AC-3 step session, lock free" orchestrator "$strict" no yes no RAVINTIO_INITIATIVE_STEP=1
  # AC-4: no active initiative.
  check_case "AC-4 no initiative, lock free" orchestrator "$strict" no no no
  check_case "AC-4 no initiative, lock held" orchestrator "$strict" yes no no
done

echo ""
echo "=== AC-6: the human's ack is git-ignored ==="
git -C "$REPO_ROOT" check-ignore -q plan/.initiative-ack
assert_equals "0" "$?" "AC-6: git check-ignore succeeds for plan/.initiative-ack"
git -C "$REPO_ROOT" check-ignore -q plan/.orchestrator-ack
assert_equals "1" "$?" "AC-6: plan/.orchestrator-ack stays tracked"

print_summary
