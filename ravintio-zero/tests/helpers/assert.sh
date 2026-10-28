#!/usr/bin/env bash
# Test assertion helpers for the RAVINTIO Zero test suite
# Usage: source this file, call assert_* functions, call print_summary at the end.
#
# JSON helpers use jq if available, fall back to Node.js — matching the hook scripts.

PASS=0
FAIL=0

# RAVINTIO_TEST_QUIET=1 hides PASS lines. A failing suite prints its name once,
# before its first FAIL line (0000151 req-008).
QUIET_NAMED=0

_pass_line() {
  [ "${RAVINTIO_TEST_QUIET:-0}" = "1" ] || echo "  PASS: $1"
}

_fail_line() {
  if [ "${RAVINTIO_TEST_QUIET:-0}" = "1" ] && [ "$QUIET_NAMED" -eq 0 ]; then
    echo "--- $(basename "$0") ---"
    QUIET_NAMED=1
  fi
  echo "  FAIL: $1"
}

# -----------------------------------------------------------------------
# JSON helpers (jq preferred, node fallback)
# -----------------------------------------------------------------------

get_permission_decision() {
  local output="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecision // ""'
  else
    printf '%s' "$output" | node -e \
      "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const j=JSON.parse(d);console.log(j?.hookSpecificOutput?.permissionDecision??'');});"
  fi
}

get_permission_reason() {
  local output="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""'
  else
    printf '%s' "$output" | node -e \
      "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const j=JSON.parse(d);console.log(j?.hookSpecificOutput?.permissionDecisionReason??'');});"
  fi
}

get_hook_event_name() {
  local output="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$output" | jq -r '.hookSpecificOutput.hookEventName // ""'
  else
    printf '%s' "$output" | node -e \
      "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const j=JSON.parse(d);console.log(j?.hookSpecificOutput?.hookEventName??'');});"
  fi
}

validate_json() {
  # Returns 0 if input is valid JSON, non-zero otherwise
  local output="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$output" | jq empty 2>/dev/null
  else
    printf '%s' "$output" | node -e \
      "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{JSON.parse(d);});" 2>/dev/null
  fi
}

# -----------------------------------------------------------------------
# Assertion helpers
# -----------------------------------------------------------------------

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-assertion}"

  if [ "$expected" = "$actual" ]; then
    _pass_line "$message"
    ((PASS++)) || true
  else
    _fail_line "$message"
    echo "        expected: $expected"
    echo "        actual:   $actual"
    ((FAIL++)) || true
  fi
}

assert_contains() {
  local needle="$1"
  local haystack="$2"
  local message="${3:-contains assertion}"

  # Pure-builtin substring check. The previous `printf | grep -qF` pattern broke
  # under `set -o pipefail` for haystacks >64KB (pipe buffer): grep -q exits on
  # an early match, printf takes SIGPIPE (141), pipefail fails the pipeline.
  if [[ "$haystack" == *"$needle"* ]]; then
    _pass_line "$message"
    ((PASS++)) || true
  else
    _fail_line "$message"
    echo "        needle:   $needle"
    echo "        haystack: $haystack"
    ((FAIL++)) || true
  fi
}

assert_not_contains() {
  local needle="$1"
  local haystack="$2"
  local message="${3:-not-contains assertion}"

  if [[ "$haystack" != *"$needle"* ]]; then
    _pass_line "$message"
    ((PASS++)) || true
  else
    _fail_line "$message"
    echo "        needle:   $needle"
    echo "        haystack: $haystack"
    ((FAIL++)) || true
  fi
}

assert_exit_zero() {
  local actual_exit="$1"
  local message="${2:-exit code assertion}"

  if [ "$actual_exit" -eq 0 ]; then
    _pass_line "$message"
    ((PASS++)) || true
  else
    _fail_line "$message — expected exit 0, got $actual_exit"
    ((FAIL++)) || true
  fi
}

# 0000151 req-011: the orchestrator SKILL.md keeps its core sections and moves
# rarely used ones to references/orchestrator-*.md. This prints the path of a
# temp file that holds SKILL.md followed by those files, so a test can keep
# every assertion about a moved string and read it from one text.
# Usage: ORCH="$(orch_combined "$ZERO_DIR/skills/ravintio-orchestrator")"
orch_combined() {
  # One fixed file per user, replaced by an atomic rename, so runs leave no
  # growing pile of temp files behind.
  local dir="$1" out tmp
  out="${TMPDIR:-/tmp}/ravintio-orch-combined-$(id -u).md"
  tmp="$(mktemp "${TMPDIR:-/tmp}/orch-combined.XXXXXX")"
  # 0000244 moved the initiative stage prefix block to the roadmap standards, so they join the text.
  cat "$dir/SKILL.md" "$dir"/references/orchestrator-*.md "$dir/../../standards/roadmap-standards.md" > "$tmp" 2>/dev/null
  mv -f "$tmp" "$out"
  echo "$out"
}

# 0000239 req-001: a call to an undefined assert_* function counts as a failure.
# macOS ships Bash 3.2, which has no command_not_found_handle, so this scans the
# running suite for lines that start with an assert_* word and checks that each
# name is a defined function.
_count_undefined_asserts() {
  local suite="${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}" name names count=0
  [ -f "$suite" ] || { echo 0; return 0; }
  names="$(sed -n 's/^[[:space:]]*\(assert_[A-Za-z0-9_]*\)\([[:space:]].*\)\{0,1\}$/\1/p' "$suite" | sort -u)"
  for name in $names; do
    if ! declare -F "$name" >/dev/null 2>&1; then
      echo "  FAIL: undefined assert function: $name" >&2
      count=$((count + 1))
    fi
  done
  echo "$count"
}

# 0000239 req-002: .claude/skills/ changes only when setup runs, so an active
# initiative leaves it behind the pack in every step. Prints a reason and
# returns 0 when the installed-copies check should skip. Prints nothing and
# returns 1 otherwise.
# Usage: reason="$(stale_install_skip_reason "$ROOT_DIR")" && echo "SKIP: $reason"
stale_install_skip_reason() {
  local root="$1"
  local init="$root/plan/current-initiative/initiative.md"
  local manifest="$root/.claude/skills/.ravintio-manifest"
  [ -f "$init" ] && [ -f "$manifest" ] || return 1
  grep -qE '^status: "?active"?[[:space:]]*$' "$init" || return 1
  [ -n "$(find "$root/ravintio-zero/skills" -type f -newer "$manifest" -print -quit 2>/dev/null)" ] || return 1
  echo "an initiative is active and the install manifest is older than the newest pack skill"
}

print_summary() {
  FAIL=$((FAIL + $(_count_undefined_asserts)))
  echo ""
  if [ "$FAIL" -eq 0 ]; then
    echo "Results: $PASS passed, $FAIL failed ✓"
    exit 0
  else
    echo "Results: $PASS passed, $FAIL failed ✗"
    exit 1
  fi
}
