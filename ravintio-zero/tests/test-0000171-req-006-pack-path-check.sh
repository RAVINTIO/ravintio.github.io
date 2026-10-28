#!/usr/bin/env bash
# 0000171 req-006: pack-path-check
# A skill names a pack template, standard, or schema only by its full
# ravintio-zero/... path, and every such full path exists (ADR-004).
# Also covers req-005 AC-1 (the real skills pass) and AC-2 (no bundle fields).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/ravintio-0000171-req-006.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo ""
echo "=== 0000171 req-006 pack-path-check ==="

# Lists every pack entry relative to the pack folder, one per line. A file
# line starts with "f ", a folder line with "d ".
pack_entries() {
  ( cd "$ZERO_DIR" && {
      find templates standards schemas -type f | sed 's/^/f /'
      find templates standards schemas -type d | sed 's/^/d /'
    } )
}

# check_pack_paths DIR
# Scans DIR/**/*.md. Prints one line per violation as FILE:LINE: reason: PATH.
# Exits 1 when it finds a violation, 0 otherwise.
#
# A token counts as a pack mention when it ends in the name of a pack file and,
# after any leading ./ or ../ steps, is a trailing part of that file's pack
# path. So bare names, short paths, and relative paths count. A skill's own
# files and output paths such as plan/current/story-map.md do not, because no
# pack file has that name or path. A token that starts with
# ravintio-zero/templates, ravintio-zero/standards, or ravintio-zero/schemas
# must name an existing pack file or folder.
check_pack_paths() {
  local dir="$1" list files
  list="$WORK/pack-entries.txt"
  pack_entries > "$list"
  files="$(find "$dir" -type f -name '*.md' | sort)"
  [ -n "$files" ] || return 0
  # shellcheck disable=SC2086
  awk '
    FNR == NR {
      kind = substr($0, 1, 1); rel = substr($0, 3)
      exists[rel] = 1
      if (kind == "f") {
        files[rel] = 1
        n = split(rel, parts, "/"); names[parts[n]] = 1
      }
      next
    }
    {
      rest = $0
      while (match(rest, /[A-Za-z0-9_.\/{}*-]+/)) {
        tok = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        sub(/\.+$/, "", tok)
        if (tok == "") continue
        # A placeholder such as {artifact} names a family of files, so it is not one path (0000244).
        if (tok ~ /\{/) continue
        if (tok ~ /^ravintio-zero\/(templates|standards|schemas)(\/|$)/) {
          rel = substr(tok, 15); sub(/\/+$/, "", rel)
          if (!(rel in exists)) {
            printf "%s:%d: missing pack path: %s\n", FILENAME, FNR, tok
            bad = 1
          }
          continue
        }
        t = tok
        while (t ~ /^\.\.?\//) sub(/^\.\.?\//, "", t)
        n = split(t, parts, "/")
        if (!(parts[n] in names)) continue
        for (p in files) {
          if (p == t || (length(p) > length(t) && substr(p, length(p) - length(t)) == "/" t)) {
            printf "%s:%d: short pack path: %s (use ravintio-zero/%s)\n", FILENAME, FNR, tok, p
            bad = 1
            break
          }
        }
      }
    }
    END { exit bad ? 1 : 0 }
  ' "$list" $files
}

# Writes a fixture skill folder under $WORK and prints its path.
make_fixture() {
  local name="$1" body="$2"
  mkdir -p "$WORK/$name/skills/fixture-skill"
  printf '%s\n' "$body" > "$WORK/$name/skills/fixture-skill/SKILL.md"
  echo "$WORK/$name/skills"
}

# AC-1: a short path fails and names the file, line, and path
fx="$(make_fixture short "---
name: fixture-skill
---
Write each requirement from \`templates/requirement.template.md\`.")"
out="$(check_pack_paths "$fx")"; rc=$?
assert_equals "1" "$rc" "req-006 AC-1: a short template path fails the check"
assert_contains "fixture-skill/SKILL.md:4:" "$out" "req-006 AC-1: the failure names the file and line"
assert_contains "templates/requirement.template.md" "$out" "req-006 AC-1: the failure names the path"

# AC-1: a bare name and a relative path also fail
fx="$(make_fixture bare "Follow roadmap-standards.md for the branch.
Copy ../standards/testing-standards.md first.
See library-standards/_version-policy.md for pins.")"
out="$(check_pack_paths "$fx")"; rc=$?
assert_equals "1" "$rc" "req-006 AC-1: bare and relative pack names fail the check"
assert_contains "SKILL.md:1: short pack path: roadmap-standards.md" "$out" "req-006 AC-1: a bare name fails"
assert_contains "SKILL.md:2: short pack path: ../standards/testing-standards.md" "$out" "req-006 AC-1: a relative path fails"
assert_contains "SKILL.md:3: short pack path: library-standards/_version-policy.md" "$out" "req-006 AC-1: a partial standards path fails"

# AC-2: a missing full path fails and names the path
fx="$(make_fixture missing "Fill \`ravintio-zero/templates/no-such.template.md\` now.")"
out="$(check_pack_paths "$fx")"; rc=$?
assert_equals "1" "$rc" "req-006 AC-2: a missing full path fails the check"
assert_contains "SKILL.md:1: missing pack path: ravintio-zero/templates/no-such.template.md" "$out" "req-006 AC-2: the failure names the path"

# No false positives: full paths, skill-own files, output paths, and override
# paths pass.
fx="$(make_fixture clean "Fill \`ravintio-zero/templates/requirement.template.md\`.
Follow ravintio-zero/standards/library-standards/_version-policy.md.
Read \`references/orchestrator-scope-lock.md\` and \`./assets/notes.md\`.
Write \`plan/current/story-map.md\` and \`plan/current/design.md\`.
Check \`ravintio-overrides/library-standards/{language}/prefer-avoid.md\` first.
The pack folder \`ravintio-zero/standards/library-standards/\` holds the lists.")"
out="$(check_pack_paths "$fx")"; rc=$?
assert_equals "0" "$rc" "req-006: full paths and non-pack paths pass the check"
[ "$rc" -eq 0 ] || echo "$out"

# AC-3 (and req-005 AC-1): the real skill sources pass
out="$(check_pack_paths "$ZERO_DIR/skills")"; rc=$?
assert_equals "0" "$rc" "req-006 AC-3: every pack mention in the skills is an existing full path"
[ "$rc" -eq 0 ] || echo "$out"

# req-005 AC-2: no SKILL.md frontmatter holds a bundle field
hits=""
for f in "$ZERO_DIR"/skills/*/SKILL.md; do
  fm="$(awk 'NR==1 && /^---$/ {f=1; next} f && /^---$/ {exit} f' "$f")"
  if printf '%s\n' "$fm" | grep -qE '^(bundle_templates|bundle_standards):'; then
    hits="$hits ${f#"$ZERO_DIR"/}"
  fi
done
assert_equals "" "$hits" "req-005 AC-2: no SKILL.md frontmatter holds bundle_templates or bundle_standards"

print_summary
