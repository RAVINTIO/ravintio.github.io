#!/usr/bin/env bash
# 0000169 req-001: attribution-ban-text
# The boot template, commit standards, and ship skill ban AI attribution in
# PR descriptions and name the three host lines.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZERO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

BOOT="$ZERO_DIR/templates/standard-boot.md"
STD="$ZERO_DIR/standards/commit-standards.md"
SHIP="$ZERO_DIR/skills/ravintio-ship/SKILL.md"

echo ""
echo "=== 0000169 req-001 attribution-ban-text ==="

for f in "$BOOT" "$STD" "$SHIP"; do
  n="$(basename "$(dirname "$f")")/$(basename "$f")"
  for phrase in 'Generated with [Claude Code]' 'Co-Authored-By' 'Claude-Session:'; do
    if grep -qF -- "$phrase" "$f"; then echo "  PASS: $n names $phrase"
    else echo "  FAIL: $n lacks $phrase"; FAIL=$((FAIL+1)); fi
  done
  if grep -i 'PR description\|PR bod' "$f" | grep -qi 'attribut'; then
    echo "  PASS: $n bans attribution in PR descriptions"
  else
    echo "  FAIL: $n does not ban attribution in PR descriptions"; FAIL=$((FAIL+1))
  fi
done

# Section 3 no longer limits the ban to commit messages
sec="$(awk '/^### 3\. /{f=1;next} /^### 4\. /{f=0} f' "$STD")"
if printf '%s\n' "$sec" | grep -q '^Commit messages MUST NOT'; then
  echo "  FAIL: commit-standards section 3 limits the ban to commit messages"; FAIL=$((FAIL+1))
else
  echo "  PASS: commit-standards section 3 is not limited to commit messages"
fi

print_summary
