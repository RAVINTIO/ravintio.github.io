# Migration 0004 - RAVINTIO rename

**Target standard:** `ravintio-zero/`, `ravintio-overrides/`, `.github/workflows/ravintio.yml`, and `.ravintio-*` markers
**Scope:** consumer repo root
**Applies when:** `planifest-zero/` or `planifest-overrides/` exists in the repo root. In any other repo, including the pack source, the migration stays pending and nothing runs.
**Safe to skip:** No. Setup stops while `planifest-zero/` or `planifest-overrides/` remains. Re-running is safe.

---

## What this migration does

The pack changed its name from Planifest to RAVINTIO. A consumer repo that installed the old pack holds four things that setup does not move:

- the old `planifest-zero/` folder
- your content in `planifest-overrides/`
- the installed `.github/workflows/planifest.yml`
- the old marker files `.claude/.planifest-setup-flags` and `.claude/skills/.planifest-manifest`

The helper moves or removes each one. It never deletes `planifest-zero/`. It moves the folder to `.ravintio-backup/planifest-zero/` and adds `.ravintio-backup/` to `.git/info/exclude`. The helper stops before it moves anything if it finds a conflict or a symlink at a path it moves.

---

## Migrator instructions

1. Check that `ravintio-zero/` exists in the project root. If it doesn't, ask the human to copy the new `ravintio-zero/` folder into the project, then continue. The project root can sit below the git top level.

2. Tell the human that the helper moves `planifest-zero/` to `.ravintio-backup/planifest-zero/` and deletes nothing. Git stops tracking the old pack, and `.git/info/exclude` hides the backup.

3. Show: `Will run the helper from the project root. It moves planifest-overrides/ and planifest.yml, removes the old markers, and moves planifest-zero/ to .ravintio-backup/.`
   Ask: `Proceed? (y/n)`

4. If yes, run the helper that matches the shell:
   - Bash: `bash ravintio-zero/migrations/migrate-ravintio-rename.sh`
   - PowerShell: `ravintio-zero/migrations/migrate-ravintio-rename.ps1`

5. If the helper exits non-zero, show its output and stop. It moved nothing. Do not retry until the human fixes the cause:
   - `ravintio-zero/` is missing.
   - Both `planifest-overrides/` and `ravintio-overrides/` exist. The human picks the authoritative folder.
   - `.github/workflows/ravintio.yml` already exists. The human merges or deletes one workflow.
   - `.ravintio-backup/planifest-zero` already exists from an earlier upgrade. The human checks it and deletes `.ravintio-backup/`.
   - `planifest-zero`, `planifest-overrides`, `ravintio-overrides`, `.ravintio-backup`, or a workflow file is a symlink, dangling or not. The human replaces the link with a real file or folder.

6. If the helper printed a `WARNING:` line about a symlinked parent folder, it skipped that one step and carried on:
   - `.github` or `.github/workflows`: the workflow step. The human renames `planifest.yml` to `ravintio.yml` and rewrites its paths.
   - `.claude` or `.claude/skills`: the old marker under it. The human removes the marker.
   - `ravintio-zero` or `ravintio-zero/migrations`: the archive step. Move this file to `_done/` yourself.

7. If the helper exits 0, run setup for the installed tool:
   - Bash: `ravintio-zero/setup.sh claude-code`
   - PowerShell: `ravintio-zero/setup.ps1 claude-code`

   Setup prunes the old `planifest-*` skill folders because the pack no longer ships them.

8. Ask the human to check that `ravintio-overrides/` holds their content and that `git status` shows the moves. Ask: `Confirmed? (y/n)`

9. Ask the human to check `.ravintio-backup/planifest-zero/` for files of their own, then delete `.ravintio-backup/`.

The helper moves this file to `ravintio-zero/migrations/_done/` after a run that changes the repo. If you made the changes by hand, or the human explicitly skips the migration, move it yourself.
