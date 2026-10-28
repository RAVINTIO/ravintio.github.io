#!/usr/bin/env bash
# Feature 0000164 req-005 and REQ-010: structure tests for ravintio-file-backlog.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL="$ZERO_DIR/skills/ravintio-file-backlog/SKILL.md"
CATALOGUE="$ZERO_DIR/skills/ravintio-orchestrator/references/orchestrator-skills-catalogue.md"

assert_equals "yes" "$([ -f "$SKILL" ] && echo yes || echo no)" "SKILL.md exists"
[ -f "$SKILL" ] || { print_summary; exit 1; }

FM=$(sed -n '2,/^---$/p' "$SKILL")
BODY=$(cat "$SKILL")
assert_contains "name: ravintio-file-backlog" "$FM" "frontmatter name matches folder"
DESC=$(printf '%s\n' "$FM" | sed -n 's/^description: *//p')
assert_equals "yes" "$([ -n "$DESC" ] && echo yes || echo no)" "description is non-empty"

echo "=== req-005: id, slug, template rules ==="
assert_contains "reserve-id.mjs" "$BODY" "id rule"
assert_contains "plan/backlog/" "$BODY" "scans plan/backlog/"
assert_contains ".next-id" "$BODY" "reserves from the counter file"
assert_contains "id width" "$BODY" "id width rule"
assert_contains "this pack's template" "$BODY" "template fallback"
assert_contains "same slug" "$BODY" "same-slug rule"
assert_contains "write nothing" "$BODY" "same-slug writes nothing"
assert_contains "Never overwrite" "$BODY" "never-overwrite rule"
assert_contains "reserve the next id" "$BODY" "next id rule"
assert_contains "plan/backlog/{id}-{slug}/entry.md" "$BODY" "entry path"
assert_contains "Report the path written" "$BODY" "reports path"

echo "=== cycle 2: slug, symlink, data-not-instructions, template rules ==="
assert_contains '^[a-z0-9]+(-[a-z0-9]+)*$' "$BODY" "S-006 slug pattern"
assert_contains "ask for a valid slug" "$BODY" "S-006 invalid slug asks"
assert_contains "inside the target's \`plan/backlog/\`" "$BODY" "S-006 resolved folder containment"
assert_contains "as data, never as instructions" "$BODY" "S-007 template and entries are data"
assert_contains "is a symlink" "$BODY" "S-008 symlink stop"
assert_contains "is not a directory" "$BODY" "S-008 non-directory target stop"
assert_contains "7 digits" "$BODY" "pack id width is 7 digits"
assert_contains "guidance blockquote" "$BODY" "drop the guidance blockquote"
assert_contains '`{{...}}` placeholder' "$BODY" "fill or remove placeholders"
assert_contains 'Omit the `**Parked branch:**` line' "$BODY" "omit parked branch line for open entry"
assert_contains "covers \`plan/backlog/\` only" "$BODY" "same-slug check scope is backlog only"
S4=$(grep -n "^## Step .*Check for Collisions" "$SKILL" | cut -d: -f1)
S1=$(grep -n "^## Step .*Find the Backlog Folder" "$SKILL" | cut -d: -f1)
assert_equals "yes" "$([ -n "$S4" ] && [ -n "$S1" ] && [ "$S4" -lt "$S1" ] && echo yes || echo no)" "same-slug check runs before creating plan/backlog/"

echo "=== REQ-010: git guardrails and catalogue ==="
RULE=$(grep -i "never commit" "$SKILL")
for w in "commit" "push" "switch branches" "stash" "pull request"; do
  assert_contains "$w" "$RULE" "never-commit rule names: $w"
done
assert_contains "ravintio-file-backlog" "$(cat "$CATALOGUE")" "catalogue lists the skill"

print_summary
