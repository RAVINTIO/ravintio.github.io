#!/usr/bin/env bash
# migrate-initiative-rename.sh - Move a consumer repo from the roadmap names to the initiative names.
# Idempotent: safe to run multiple times. Stops before it changes anything on a conflict.
# Run from the consumer project root, the folder that holds ravintio-zero/.

set -euo pipefail

ACTIVE="plan/current-roadmap"
DRAFTS="plan/roadmap"
WORKFLOW=".github/workflows/ravintio.yml"
OLD_LOGS="plan/.roadmap-logs"
NEW_LOGS="plan/.initiative-logs"
MIGRATION="ravintio-zero/migrations/0005-initiative-rename.md"

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

refuse_link() {
    echo "ERROR: $1 is a symlink. Refusing to continue. Nothing was changed."
    echo "Replace the link with a real file or folder, or remove it, then run this helper again."
    exit 1
}

# Stop while an initiative is active. Finish or park it first.
if [ -e "$ACTIVE" ] || [ -L "$ACTIVE" ]; then
    echo "ERROR: $ACTIVE/ exists. An initiative is active. Nothing was changed."
    echo "Finish or park the active initiative, then run this helper again."
    exit 1
fi

# Collect the drafts to rename. A link at any path we touch stops the run.
for p in plan "$DRAFTS" "$OLD_LOGS" "$NEW_LOGS"; do
    if [ -L "$p" ]; then refuse_link "$p"; fi
done
wf_link="$(first_link ".github" ".github/workflows" "$WORKFLOW")"
if [ -n "$wf_link" ] && [ -e "$WORKFLOW" -o -L "$WORKFLOW" ]; then
    refuse_link "$wf_link"
fi

drafts=()
if [ -d "$DRAFTS" ]; then
    for d in "$DRAFTS"/*; do
        [ -e "$d" ] || [ -L "$d" ] || continue
        if [ -e "$d/roadmap.md" ] || [ -L "$d/roadmap.md" ]; then
            if [ -L "$d" ]; then refuse_link "$d"; fi
            if [ -L "$d/roadmap.md" ]; then refuse_link "$d/roadmap.md"; fi
            if [ -L "$d/initiative.md" ]; then refuse_link "$d/initiative.md"; fi
            drafts+=("$d")
        fi
    done
fi

# Check every conflict before the first change.
for d in ${drafts[@]+"${drafts[@]}"}; do
    if [ -e "$d/initiative.md" ]; then
        echo "ERROR: $d/ holds both roadmap.md and initiative.md. Nothing was changed."
        echo "Decide which file is authoritative, delete the other, then run this helper again."
        exit 1
    fi
done
if [ -e "$OLD_LOGS" ] && [ -e "$NEW_LOGS" ]; then
    echo "ERROR: Both $OLD_LOGS/ and $NEW_LOGS/ exist. Nothing was changed."
    echo "Merge or delete one folder, then run this helper again."
    exit 1
fi

# Step 1: rename each draft.
for d in ${drafts[@]+"${drafts[@]}"}; do
    move_path "$d/roadmap.md" "$d/initiative.md"
    echo "Renamed $d/roadmap.md to $d/initiative.md."
    changed=1
done

# Step 2: rename the CI branch pattern. A path such as plan/roadmap/** stays.
if [ -f "$WORKFLOW" ] && grep -Eq '(^|[^/A-Za-z0-9_-])roadmap/\*\*' "$WORKFLOW"; then
    tmp="$(mktemp)"
    sed -E 's#(^|[^/A-Za-z0-9_-])roadmap/\*\*#\1initiative/**#g' "$WORKFLOW" > "$tmp"
    cat "$tmp" > "$WORKFLOW"
    rm -f "$tmp"
    echo "Replaced roadmap/** with initiative/** in $WORKFLOW."
    changed=1
fi

# Step 3: rename the log folder.
if [ -d "$OLD_LOGS" ]; then
    move_path "$OLD_LOGS" "$NEW_LOGS"
    echo "Renamed $OLD_LOGS/ to $NEW_LOGS/."
    changed=1
fi

# Archive this migration once it has changed the repo, so the orchestrator
# stops offering it. A repo with nothing to move keeps it pending.
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

if [ "$changed" -eq 0 ]; then
    echo "Nothing to do. This repo already uses the initiative names."
else
    echo "Done."
fi
exit 0
