#!/usr/bin/env bash
# migrate-ravintio-rename.sh - Move a consumer repo from the Planifest names to the RAVINTIO names.
# Idempotent: safe to run multiple times. Stops before it moves anything on a conflict.
# Run from the consumer project root, the folder that holds ravintio-zero/.
# It never deletes the old pack. It moves it to .ravintio-backup/ instead.

set -euo pipefail

OLD_OVERRIDES="planifest-overrides"
NEW_OVERRIDES="ravintio-overrides"
OLD_WORKFLOW=".github/workflows/planifest.yml"
NEW_WORKFLOW=".github/workflows/ravintio.yml"
OLD_PACK="planifest-zero"
BACKUP=".ravintio-backup"
MARKERS=(".claude/.planifest-setup-flags" ".claude/skills/.planifest-manifest")
# The pack's own workflow variables. Every other PLANIFEST_ name, such as a
# consumer secret, stays as it is.
PACK_VARS="REQUIRE_PWSH|PWSH|TEST_QUIET|PREFLIGHT_ONLY|REGRESSION_DIR|ROADMAP_MODEL|ROADMAP_MAX_TURNS"

changed=0

is_tracked() {
    [ -n "$(git ls-files -- "$1" 2>/dev/null | head -n 1)" ]
}

move_path() {
    if is_tracked "$1"; then
        git mv "$1" "$2"
    else
        mv "$1" "$2"
    fi
}

# first_link PATH...: print the first path that is a symlink, if any.
first_link() {
    local p
    for p in "$@"; do
        if [ -L "$p" ]; then
            echo "$p"
            return 0
        fi
    done
    return 0
}

in_git=0
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null || true)" = "true" ]; then
    in_git=1
fi

# A symlinked parent folder skips only the step that would write through it.
wf_link="$(first_link ".github" ".github/workflows")"

# Refuse a symlink before any other check. Never follow a planted link.
# This covers each source and target and the two workflow files. A dangling
# link counts too.
link_checks=("$OLD_OVERRIDES" "$NEW_OVERRIDES" "$OLD_PACK" "$BACKUP")
if [ -z "$wf_link" ]; then
    link_checks+=("$OLD_WORKFLOW" "$NEW_WORKFLOW")
fi
for p in "${link_checks[@]}"; do
    if [ -L "$p" ]; then
        echo "ERROR: $p is a symlink. Refusing to continue. Nothing was moved."
        echo "Replace the link with a real file or folder, or remove it, then run this helper again."
        exit 1
    fi
done

# Step 1: the new pack must be in place. This folder is the project root.
if [ ! -d "ravintio-zero" ]; then
    echo "ERROR: ravintio-zero/ not found. Nothing was moved."
    echo "Copy the new ravintio-zero/ folder into this repo, then run this helper again."
    exit 1
fi

# Step 2: both override folders is a conflict.
if [ -d "$OLD_OVERRIDES" ] && [ -d "$NEW_OVERRIDES" ]; then
    echo "WARNING: Both $OLD_OVERRIDES/ and $NEW_OVERRIDES/ exist. Nothing was moved."
    echo "Cannot merge automatically. Please resolve manually:"
    echo "  1. Decide which folder is authoritative."
    echo "  2. Move its contents to $NEW_OVERRIDES/ if needed."
    echo "  3. Delete $OLD_OVERRIDES/."
    exit 1
fi

# Step 4 conflict check runs before any move, so a stop leaves the repo untouched.
if [ -z "$wf_link" ] \
   && { [ -e "$OLD_WORKFLOW" ] || [ -L "$OLD_WORKFLOW" ]; } \
   && { [ -e "$NEW_WORKFLOW" ] || [ -L "$NEW_WORKFLOW" ]; }; then
    echo "ERROR: $NEW_WORKFLOW already exists. Nothing was moved."
    echo "Merge or delete one of $OLD_WORKFLOW and $NEW_WORKFLOW, then run this helper again."
    exit 1
fi

# Step 6 conflict check runs before any move. An earlier backup is never overwritten.
if [ -d "$OLD_PACK" ]; then
    if [ -e "$BACKUP/$OLD_PACK" ] || [ -L "$BACKUP/$OLD_PACK" ] || { [ -e "$BACKUP" ] && [ ! -d "$BACKUP" ]; }; then
        echo "ERROR: $BACKUP/$OLD_PACK already exists. Nothing was moved."
        echo "Check $BACKUP/ and delete it once nothing of yours is in it, then run this helper again."
        exit 1
    fi
fi

# Step 3: overrides.
if [ -d "$OLD_OVERRIDES" ]; then
    move_path "$OLD_OVERRIDES" "$NEW_OVERRIDES"
    echo "Moved $OLD_OVERRIDES/ to $NEW_OVERRIDES/."
    changed=1
else
    echo "Skipped $OLD_OVERRIDES/: not present."
fi

# Step 4: workflow.
if [ -n "$wf_link" ]; then
    echo "WARNING: $wf_link is a symlink. Skipped the workflow step, so nothing is written through the link."
    echo "If $OLD_WORKFLOW exists, rename it to ravintio.yml yourself."
elif [ -e "$OLD_WORKFLOW" ]; then
    move_path "$OLD_WORKFLOW" "$NEW_WORKFLOW"
    # Write to a temp file in the same folder, then rename it over the target,
    # so the write replaces the file and never follows a link. The variable
    # rewrite runs twice because each match uses up the character after it.
    tmp="$(mktemp "$(dirname "$NEW_WORKFLOW")/.ravintio.yml.XXXXXX")"
    cp -p "$NEW_WORKFLOW" "$tmp"
    var_rule="s#(^|[^A-Za-z0-9_])PLANIFEST_($PACK_VARS)([^A-Za-z0-9_]|\$)#\\1RAVINTIO_\\2\\3#g"
    sed -E -e 's#planifest-zero/#ravintio-zero/#g' -e "$var_rule" -e "$var_rule" "$NEW_WORKFLOW" > "$tmp"
    mv -f "$tmp" "$NEW_WORKFLOW"
    echo "Moved $OLD_WORKFLOW to $NEW_WORKFLOW."
    changed=1
else
    echo "Skipped $OLD_WORKFLOW: not present."
fi

# Step 5: old markers. A marker under a symlinked folder is left in place.
for m in "${MARKERS[@]}"; do
    parent_link="$(first_link ".claude" "$(dirname "$m")")"
    if [ -n "$parent_link" ]; then
        echo "WARNING: $parent_link is a symlink. Skipped $m, so nothing is removed through the link."
    elif [ -e "$m" ] || [ -L "$m" ]; then
        rm -f "$m"
        echo "Removed $m."
        changed=1
    else
        echo "Skipped $m: not present."
    fi
done

# Step 6: old pack folder. Stop tracking it, then rename it into the backup
# folder. A rename never follows a nested link.
if [ -d "$OLD_PACK" ]; then
    if [ "$in_git" -eq 1 ] && is_tracked "$OLD_PACK"; then
        git rm -r -q --cached -- "$OLD_PACK"
    fi
    mkdir -p "$BACKUP"
    mv "$OLD_PACK" "$BACKUP/$OLD_PACK"
    if [ "$in_git" -eq 1 ]; then
        exclude="$(git rev-parse --git-path info/exclude)"
        mkdir -p "$(dirname "$exclude")"
        if ! { [ -f "$exclude" ] && grep -qxF "$BACKUP/" "$exclude"; }; then
            if [ -s "$exclude" ] && [ -n "$(tail -c 1 "$exclude")" ]; then
                echo >> "$exclude"
            fi
            echo "$BACKUP/" >> "$exclude"
        fi
    fi
    echo "Moved $OLD_PACK/ to $BACKUP/$OLD_PACK/. Delete $BACKUP/ once you have checked that nothing of yours is in it."
    changed=1
else
    echo "Skipped $OLD_PACK/: not present."
fi

# Archive this migration once it has changed the repo, so the orchestrator
# stops offering it. A repo with no old install keeps it pending.
MIGRATION="ravintio-zero/migrations/0004-ravintio-rename.md"
if [ "$changed" -eq 1 ]; then
    migrations_link="$(first_link "ravintio-zero" "ravintio-zero/migrations")"
    if [ -n "$migrations_link" ]; then
        echo "WARNING: $migrations_link is a symlink. Skipped archiving $MIGRATION, so nothing is written through the link."
    elif [ -f "$MIGRATION" ] && [ ! -L "$MIGRATION" ]; then
        mkdir -p ravintio-zero/migrations/_done
        mv "$MIGRATION" ravintio-zero/migrations/_done/
        echo "Archived $MIGRATION to ravintio-zero/migrations/_done/."
    fi
fi

# Step 7: next step.
if [ "$changed" -eq 0 ]; then
    echo "Nothing to do. This repo already uses the ravintio names."
else
    echo "Done."
fi
echo "Next step: run ravintio-zero/setup.sh claude-code (ravintio-zero/setup.ps1 claude-code on Windows)."
